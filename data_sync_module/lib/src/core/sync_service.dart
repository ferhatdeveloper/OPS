// Dosya Adı: sync_service.dart
// Açıklama: Supabase ve SQLite senkronizasyon servisi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/backup_manager.dart';
import '../models/sync_config.dart';
import '../models/sync_result.dart';

/// {@template sync_service}
/// Supabase ve SQLite arasında senkronizasyon sağlayan servis sınıfı.
/// {@endtemplate}
class SyncService {
  final SupabaseClient _supabase;
  final Database _db;
  final _syncController = BehaviorSubject<bool>();
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  /// Senkronizasyon durumu stream'i
  Stream<bool> get syncStatus => _syncController.stream;

  SyncService(this._supabase, this._db) {
    _initConnectivityListener();
    _startPeriodicSync();
  }

  /// Bağlantı durumunu dinler
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (result.isNotEmpty && result.first != ConnectivityResult.none) {
        syncAll();
      }
    });
  }

  /// Periyodik senkronizasyonu başlatır
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncAll();
    });
  }

  /// Tüm tabloları senkronize eder
  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult.success();
    _isSyncing = true;
    _syncController.add(true);

    try {
      final backupManager = BackupManager(_db, _supabase);
      await Future.wait([
        backupManager.backupSqliteDatabase(),
        backupManager.backupSupabaseDatabase(),
      ]);

      final tables = await _getTables();
      for (var table in tables) {
        await _syncTable(table);
      }
      return SyncResult.success();
    } catch (e) {
      print('Senkronizasyon hatası: $e');
      return SyncResult.failure(errorMessage: e.toString());
    } finally {
      _isSyncing = false;
      _syncController.add(false);
    }
  }

  /// Belirtilen tabloyu senkronize eder
  Future<SyncResult> syncTable(String tableName) async {
    if (_isSyncing) return SyncResult.success();
    _isSyncing = true;
    _syncController.add(true);

    try {
      await _syncTable(tableName);
      return SyncResult.success();
    } catch (e) {
      print('Senkronizasyon hatası ($tableName): $e');
      return SyncResult.failure(errorMessage: e.toString());
    } finally {
      _isSyncing = false;
      _syncController.add(false);
    }
  }

  /// Konfigürasyonu günceller
  Future<void> updateConfig(SyncConfig newConfig) async {
    // Gelecekte konfigürasyon bazlı değişiklikler buraya eklenebilir
    print('Senkronizasyon konfigürasyonu güncellendi');
  }

  /// SQLite tablolarını alır
  Future<List<String>> _getTables() async {
    final result = await _db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    return result.map((row) => row['name'] as String).toList();
  }

  /// Belirtilen tabloyu senkronize eder
  Future<void> _syncTable(String tableName) async {
    await _uploadLocalChanges(tableName);
    await _downloadRemoteChanges(tableName);
  }

  /// Map içindeki bool değerleri int (0/1) olarak dönüştürür
  Map<String, dynamic> convertBoolsToInts(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value ? 1 : 0);
      }
      return MapEntry(key, value);
    });
  }

  /// Map içindeki int (0/1) değerleri bool olarak dönüştürür
  Map<String, dynamic> convertIntsToBools(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is int && (value == 0 || value == 1)) {
        // Boolean alanları tespit et ve dönüştür
        if (_isBooleanField(key)) {
          return MapEntry(key, value == 1);
        }
      }
      return MapEntry(key, value);
    });
  }

  /// Alan adının boolean alan olup olmadığını kontrol eder
  bool _isBooleanField(String fieldName) {
    final booleanFields = [
      'is_active', 'is_selected', 'is_synced', 'is_deleted',
      'is_encrypted', 'is_approved', 'is_visible', 'is_enabled',
      'auto_sync_enabled', 'auto_backup_enabled', 'audit_log_enabled',
      'database_encrypted', 'remember_me', 'use_https'
    ];
    return booleanFields.contains(fieldName.toLowerCase());
  }

  /// Yerel değişiklikleri Supabase'e yükler
  Future<void> _uploadLocalChanges(String tableName) async {
    // SQLite'ı yedekle
    await BackupManager(_db, _supabase).backupSqliteDatabase();

    final localChanges = await _db.query(
      tableName,
      where: 'approval_status = ? AND is_synced = ?',
      whereArgs: [1, 0], // Sadece onaylanmış ve senkronize edilmemiş kayıtlar
    );

    for (var change in localChanges) {
      try {
        final response = await _supabase.from(tableName).upsert(
              change..['is_synced'] = true,
              onConflict: 'id',
            );

        if (response != null) {
          // Senkronizasyon başarılı, durumu güncelle
          await _db.update(
            tableName,
            convertBoolsToInts({
              'is_synced': 1,
              'approval_status': 2, // Senkronize edildi durumuna güncelle
              'updated_at': DateTime.now().toIso8601String(),
            }),
            where: 'id = ?',
            whereArgs: [change['id']],
          );
        }
      } catch (e) {
        print('Yükleme hatası ($tableName): $e');
        // Hata durumunda approval_status=4 olarak işaretle
        await _db.update(
          tableName,
          convertBoolsToInts({
            'approval_status': 4,
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
    try {
      final backupManager = BackupManager(_db, _supabase);
      await Future.wait([
        backupManager.backupSqliteDatabase(),
        backupManager.backupSupabaseDatabase(),
      ]);

      final lastSync = await _getLastSyncTime(tableName);
      final response = await _supabase
          .from(tableName)
          .select()
          .gt('updated_at', lastSync.toIso8601String());

      final remoteChanges = response as List<dynamic>;

      for (var change in remoteChanges) {
        final localRecord = await _db.query(
          tableName,
          where: 'id = ?',
          whereArgs: [change['id']],
        );

        if (localRecord.isEmpty) {
          // Yeni kayıt, approval_status=2 olarak ekle
          change['approval_status'] = 2;
          await _db.insert(tableName, convertBoolsToInts(change));
        } else {
          final Map<String, dynamic> record = localRecord.first;
          final localUpdatedAt = DateTime.parse(record['updated_at'] as String);
          final remoteUpdatedAt =
              DateTime.parse(change['updated_at'] as String);

          if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
            // Uzak değişiklik daha yeni, approval_status=2 olarak güncelle
            change['approval_status'] = 2;
            await _db.update(
              tableName,
              convertBoolsToInts(change),
              where: 'id = ?',
              whereArgs: [change['id']],
            );
          }
        }
      }

      await _updateLastSyncTime(tableName);
    } catch (e) {
      print('İndirme hatası ($tableName): $e');
    }
  }

  /// Son senkronizasyon zamanını alır
  Future<DateTime> _getLastSyncTime(String tableName) async {
    final result = await _db.query(
      'sync_metadata',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    if (result.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.parse(result.first['last_sync'] as String);
  }

  /// Son senkronizasyon zamanını günceller
  Future<void> _updateLastSyncTime(String tableName) async {
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      'sync_metadata',
      {
        'table_name': tableName,
        'last_sync': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Realtime aboneliğini başlatır
  Future<void> setupRealtimeSync(String tableName) async {
    _supabase.from(tableName).stream(primaryKey: ['id']).listen(
        (List<Map<String, dynamic>> data) async {
      for (var change in data) {
        await _handleRealtimeChange(tableName, change);
      }
    });
  }

  /// Realtime değişikliğini işler
  Future<void> _handleRealtimeChange(
      String tableName, Map<String, dynamic> change) async {
    final localRecord = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [change['id']],
    );

    if (localRecord.isEmpty) {
      await _db.insert(tableName, convertBoolsToInts(change));
    } else {
      final Map<String, dynamic> record = localRecord.first;
      final localUpdatedAt = DateTime.parse(record['updated_at'] as String);
      final remoteUpdatedAt = DateTime.parse(change['updated_at'] as String);

      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await _db.update(
          tableName,
          convertBoolsToInts(change),
          where: 'id = ?',
          whereArgs: [change['id']],
        );
      }
    }
  }

  /// Servisi dispose eder
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}
