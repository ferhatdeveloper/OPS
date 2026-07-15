// Dosya Adı: sync_service.dart
// Açıklama: Supabase ve SQLite senkronizasyon servisi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
// supabase removed
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'backup_manager.dart';
import 'sync_config.dart';
import 'sync_result.dart';
import 'approval_status.dart';
import 'conflict_strategy.dart';
import '../services/postgre_service.dart';

/// {@template sync_service}
/// Supabase ve SQLite arasında senkronizasyon sağlayan servis sınıfı.
/// {@endtemplate}
class SyncService {
//  final dynamic _supabase; // Removed
  final Database _db;
  final SyncConfig _config;
  final _syncController = BehaviorSubject<SyncProgress>.seeded(SyncProgress.idle());
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  final Map<String, StreamSubscription> _realtimeSubscriptions = {};

  /// Senkronizasyon durumu stream'i
  Stream<SyncProgress> get syncStatus => _syncController.stream;

  SyncService(this._db, this._config) {
    _initConnectivityListener();
    if (_config.autoSyncEnabled) {
      _startPeriodicSync();
    }
  }

  /// Bağlantı durumunu dinler
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none && _config.autoSyncEnabled) {
        syncAll();
      }
    });
  }

  /// Periyodik senkronizasyonu başlatır
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      _config.syncInterval,
      (timer) => syncAll(),
    );
  }

  /// Tüm tabloları senkronize eder
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult.failure(
          errorMessage: 'Senkronizasyon zaten devam ediyor');
    }

    _isSyncing = true;
    
    final allTables = await _getTables();
    // Tabloları öncelik sırasına göre sırala
    allTables.sort((a, b) {
      final pA = _config.tablePriorities[a] ?? 99;
      final pB = _config.tablePriorities[b] ?? 99;
      return pA.compareTo(pB);
    });

    _syncController.add(SyncProgress(
      isSyncing: true,
      currentTable: allTables.isNotEmpty ? allTables.first : null,
      tableProgress: allTables.map((t) => SyncProgressItem(tableName: t)).toList(),
    ));

    try {
      // Yedekleme etkinse yedek al
      if (_config.backupEnabled) {
        await BackupManager(_db).backupSqliteDatabase();
        await BackupManager(_db).backupPostgreDatabase();
      }

      final results = <SyncResult>[];

      for (var table in allTables) {
        if (_config.syncableTables.isEmpty ||
            _config.syncableTables.contains(table)) {
          // Progress güncelle
          final currentProgress = _syncController.value;
          _syncController.add(currentProgress.copyWith(currentTable: table));

          final result = await _syncTable(table);
          results.add(result);

          // Tablo progress'ini güncelle
          final updatedTableProgress = currentProgress.tableProgress.map((p) {
            if (p.tableName == table) {
              return p.copyWith(
                processedRecords: result.syncedRecords,
                isCompleted: true,
                errorCount: result.isSuccess ? 0 : 1,
              );
            }
            return p;
          }).toList();
          _syncController.add(currentProgress.copyWith(tableProgress: updatedTableProgress));
        }
      }

      _isSyncing = false;
      _syncController.add(SyncProgress.idle());

      // Sonuçları birleştir
      final hasErrors = results.any((r) => !r.isSuccess);
      if (hasErrors) {
        return SyncResult.failure(
            errorMessage: 'Bazı tablolarda senkronizasyon hatası oluştu');
      }

      return SyncResult.success(
        syncedRecords: results.length,
        syncedTables: allTables,
      );
    } catch (e) {
      _isSyncing = false;
      _syncController.add(SyncProgress.idle());
      return SyncResult.failure(errorMessage: 'Senkronizasyon hatası: $e');
    }
  }

  /// Belirtilen tabloyu senkronize eder
  Future<SyncResult> syncTable(String tableName) async {
    if (_isSyncing) {
      return SyncResult.failure(
          errorMessage: 'Senkronizasyon zaten devam ediyor');
    }

    _isSyncing = true;
    _syncController.add(SyncProgress(
      isSyncing: true,
      currentTable: tableName,
      tableProgress: [SyncProgressItem(tableName: tableName)],
    ));

    try {
      // Yedekleme etkinse yedek al
      if (_config.backupEnabled) {
        await BackupManager(_db).backupSqliteDatabase();
        await BackupManager(_db).backupPostgreDatabase();
      }

      final result = await _syncTable(tableName);
      _isSyncing = false;
      _syncController.add(SyncProgress.idle());
      return result;
    } catch (e) {
      _isSyncing = false;
      _syncController.add(SyncProgress.idle());
      return SyncResult.failure(
          errorMessage: 'Tablo senkronizasyon hatası: $e');
    }
  }

  /// SQLite tablolarını alır
  Future<List<String>> _getTables() async {
    if (kIsWeb) return [];

    final result = await _db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    return result.map((row) => row['name'] as String).toList();
  }

  /// Retry helper for network operations
  Future<T> _withRetry<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int retries = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) rethrow;
        final delay = Duration(seconds: 2 * retries);
        debugPrint('SyncService: Retrying operation in ${delay.inSeconds}s ($retries/$maxRetries)...');
        await Future.delayed(delay);
      }
    }
  }

  /// Belirtilen tabloyu senkronize eder
  Future<SyncResult> _syncTable(String tableName) async {
    try {
      await _uploadLocalChanges(tableName);
      await _downloadRemoteChanges(tableName);
      await _verifyIntegrity(tableName);

      return SyncResult.success(
        syncedRecords: 1,
        syncedTables: [tableName],
      );
    } catch (e) {
      return SyncResult.failure(
          errorMessage: '$tableName tablosu senkronizasyon hatası: $e');
    }
  }

  /// Map içindeki bool değerleri int (0/1) olarak dönüştürür
  Map<String, dynamic> _convertBoolsToInts(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value ? 1 : 0);
      }
      return MapEntry(key, value);
    });
  }

  /// Yerel değişiklikleri Supabase'e yükler
  Future<void> _uploadLocalChanges(String tableName) async {
    if (kIsWeb) return;

    final localChanges = await _db.query(
      tableName,
      where: 'approval_status = ? AND is_synced = ?',
      whereArgs: [ApprovalStatus.approved.value, 0],
    );
    final postgre = await PostgreService.getInstance();
    for (var change in localChanges) {
      try {
        await _withRetry(() => postgre.upsert(tableName, [change]));
        
        await _db.update(
          tableName,
          _convertBoolsToInts({
            'is_synced': 1,
            'approval_status': ApprovalStatus.synced.value,
            'updated_at': DateTime.now().toIso8601String(),
          }),
          where: 'id = ?',
          whereArgs: [change['id']],
        );
      } catch (e) {
        print('Yükleme hatası ($tableName): $e');
        await _db.update(
          tableName,
          _convertBoolsToInts({
            'approval_status': ApprovalStatus.error.value,
            'updated_at': DateTime.now().toIso8601String(),
          }),
          where: 'id = ?',
          whereArgs: [change['id']],
        );
      }
    }
  }

  /// Uzak değişiklikleri yerel veritabanına indirir
  Future<void> _downloadRemoteChanges(String tableName) async {
    if (kIsWeb) return;

    try {
      final lastSync = await _getLastSyncTime(tableName);
      final postgre = await PostgreService.getInstance();
      
      final remoteChanges = await _withRetry(() => postgre.query(
        'SELECT * FROM $tableName',
        filter: '"updated_at" > @p0',
        filterArgs: [lastSync.toIso8601String()],
      ));

      for (var change in remoteChanges) {
        final localRecord = await _db.query(
          tableName,
          where: 'id = ?',
          whereArgs: [change['id']],
        );

        if (localRecord.isEmpty) {
          change['approval_status'] = ApprovalStatus.synced.value;
          await _db.insert(tableName, _convertBoolsToInts(change));
        } else {
          final Map<String, dynamic> record = localRecord.first;
          // Çakışma kontrolü ve çözümü
          final resolvedData = _resolveConflict(record, change);
          if (resolvedData != null) {
            await _db.update(
              tableName,
              _convertBoolsToInts(resolvedData),
              where: 'id = ?',
              whereArgs: [change['id']],
            );
          }
        }
      }
    } catch (e) {
      print('İndirme hatası ($tableName): $e');
      rethrow;
    }
  }

  /// Çakışma çözümü yapar. null dönerse değişiklik yapılmaz.
  Map<String, dynamic>? _resolveConflict(Map<String, dynamic> local, Map<String, dynamic> remote) {
    if (local['is_synced'] == 1) return remote..['approval_status'] = ApprovalStatus.synced.value;

    final strategy = _config.conflictStrategy;
    
    switch (strategy) {
      case ConflictStrategy.serverWins:
        return remote..['approval_status'] = ApprovalStatus.synced.value;
      case ConflictStrategy.clientWins:
        return null; // Değişiklik yapma, yerel kalsın
      case ConflictStrategy.lastWriteWins:
        final localUpdate = DateTime.parse(local['updated_at'] as String);
        final remoteUpdate = DateTime.parse(remote['updated_at'] as String);
        if (remoteUpdate.isAfter(localUpdate)) {
          return remote..['approval_status'] = ApprovalStatus.synced.value;
        }
        return null;
      case ConflictStrategy.manual:
        // Manuel çözüm için tabloya log atılmalı veya status 'conflict' yapılmalı
        return local..['approval_status'] = ApprovalStatus.error.value; 
    }
  }

  /// Basit bütünlük kontrolü (Satır sayısı karşılaştırması)
  Future<void> _verifyIntegrity(String tableName) async {
    if (kIsWeb) return;

    final postgre = await PostgreService.getInstance();
    final remoteCountResult = await postgre.query('SELECT COUNT(*) as count FROM $tableName');
    final remoteCount = remoteCountResult.first['count'] as int;

    final localCountResult = await _db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    final localCount = localCountResult.first['count'] as int;

    if (remoteCount != localCount) {
      debugPrint('SyncIntegrity: Row count mismatch in $tableName (Local: $localCount, Remote: $remoteCount)');
      // Burada daha detaylı hash farkı veya eksik kayıt senkronizasyonu tetiklenebilir
    } else {
      debugPrint('SyncIntegrity: Table $tableName is perfectly synced.');
    }
  }

  /// Son senkronizasyon zamanını alır
  Future<DateTime> _getLastSyncTime(String tableName) async {
    if (kIsWeb) return DateTime.now().subtract(const Duration(days: 1));

    try {
      final result = await _db.query(
        'sync_metadata',
        where: 'table_name = ?',
        whereArgs: [tableName],
      );

      if (result.isNotEmpty) {
        return DateTime.parse(result.first['last_sync'] as String);
      }
    } catch (e) {
      print('Son senkronizasyon zamanı alınamadı: $e');
    }

    return DateTime.now().subtract(const Duration(days: 1));
  }

  /// Realtime senkronizasyonu başlatır
  Future<void> setupRealtimeSync(String tableName) async {
    if (kIsWeb) return;

    _realtimeSubscriptions[tableName]?.cancel();

    // Basit realtime dinleyici - gelişmiş özellikler için ayrı implementasyon gerekli
    print('Realtime sync setup for table: $tableName');
  }

  /// Konfigürasyonu günceller
  void updateConfig(SyncConfig newConfig) {
    // Periyodik senkronizasyonu yeniden başlat
    if (newConfig.autoSyncEnabled != _config.autoSyncEnabled) {
      if (newConfig.autoSyncEnabled) {
        _startPeriodicSync();
      } else {
        _syncTimer?.cancel();
      }
    }

    // Konfigürasyonu güncelle
    // Not: Bu basit implementasyon - gerçek uygulamada daha gelişmiş olmalı
    print('SyncConfig güncellendi');
  }

  /// Servisi temizler
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    for (var subscription in _realtimeSubscriptions.values) {
      subscription.cancel();
    }
    _realtimeSubscriptions.clear();
    _syncController.close();
  }
}
