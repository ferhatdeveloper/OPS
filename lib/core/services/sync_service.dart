// Dosya Adı: sync_service.dart
// Açıklama: SQLite ve Supabase arasında senkronizasyon işlemlerini yöneten servis
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';

/// {@template SyncService}
/// SQLite ve Supabase arasında senkronizasyon işlemlerini yöneten servis
/// {@endtemplate}
class SyncService {
  static SyncService? _instance;
  final SupabaseService _supabaseService;
  final StorageService _storageService;
  final _uuid = const Uuid();
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Singleton pattern
  SyncService._internal(this._supabaseService, this._storageService);

  /// Servis örneğini döndürür
  static Future<SyncService> getInstance() async {
    if (_instance == null) {
      final supabaseService = await SupabaseService.getInstance();
      final storageService = await StorageService.getInstance();
      _instance = SyncService._internal(supabaseService, storageService);
    }
    return _instance!;
  }

  /// Senkronizasyonu başlatır
  Future<void> startSync(
      {Duration interval = const Duration(minutes: 5)}) async {
    if (_syncTimer != null) return;

    _syncTimer = Timer.periodic(interval, (_) async {
      if (!_isSyncing) {
        await sync();
      }
    });

    if (kDebugMode) {
      print(
          'Senkronizasyon başlatıldı (${interval.inMinutes} dakika aralıklarla)');
    }
  }

  /// Senkronizasyonu durdurur
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (kDebugMode) {
      print('Senkronizasyon durduruldu');
    }
  }

  /// Senkronizasyon işlemini gerçekleştirir
  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (kDebugMode) {
        print('Senkronizasyon başladı');
      }

      // Yerel değişiklikleri Supabase'e gönder
      await _syncLocalToRemote();

      // Uzak değişiklikleri yerel veritabanına al
      await _syncRemoteToLocal();

      if (kDebugMode) {
        print('Senkronizasyon tamamlandı');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Senkronizasyon sırasında hata: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Yerel değişiklikleri Supabase'e gönderir
  Future<void> _syncLocalToRemote() async {
    final db = await _storageService.getDatabase();
    final tables = await _getTables(db);

    for (final table in tables) {
      // Sadece onaylanmış ve senkronize edilmemiş kayıtları al
      final records = await db.query(
        table,
        where: 'approval_status = ? AND is_synced = ?',
        whereArgs: [1, 0],
      );

      for (final record in records) {
        try {
          // UUID kontrolü
          if (record['id'] == null) {
            record['id'] = _uuid.v4();
          }

          // Supabase'e gönder
          await _supabaseService.insert(table, record);

          // Senkronize edildi olarak işaretle
          await db.update(
            table,
            {'is_synced': 1, 'approval_status': 2},
            where: 'id = ?',
            whereArgs: [record['id']],
          );

          if (kDebugMode) {
            print('$table tablosunda kayıt senkronize edildi: ${record['id']}');
          }
        } catch (e) {
          // Hata durumunda approval_status=4 olarak işaretle
          await db.update(
            table,
            {'approval_status': 4},
            where: 'id = ?',
            whereArgs: [record['id']],
          );

          if (kDebugMode) {
            print('$table tablosunda kayıt senkronize edilirken hata: $e');
          }
        }
      }
    }
  }

  /// Uzak değişiklikleri yerel veritabanına alır
  Future<void> _syncRemoteToLocal() async {
    final db = await _storageService.getDatabase();
    final tables = await _getTables(db);

    for (final table in tables) {
      try {
        // Son senkronizasyon zamanını al
        final lastSync = await _getLastSyncTime(table);

        // Supabase'den değişiklikleri al
        final records = await _supabaseService.query(
          table,
          filter: 'updated_at > ?',
          filterArgs: [lastSync],
        );

        for (final record in records) {
          // Çakışma kontrolü
          final localRecord = await db.query(
            table,
            where: 'id = ?',
            whereArgs: [record['id']],
          );

          if (localRecord.isEmpty) {
            // Yeni kayıt
            await db.insert(table, record);
          } else {
            // Güncelleme - updated_at kontrolü
            final localUpdatedAt =
                DateTime.parse(localRecord.first['updated_at'] as String);
            final remoteUpdatedAt =
                DateTime.parse(record['updated_at'] as String);

            if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
              await db.update(
                table,
                record,
                where: 'id = ?',
                whereArgs: [record['id']],
              );
            }
          }

          if (kDebugMode) {
            print('$table tablosunda kayıt güncellendi: ${record['id']}');
          }
        }

        // Son senkronizasyon zamanını güncelle
        await _updateLastSyncTime(table);
      } catch (e) {
        if (kDebugMode) {
          print('$table tablosu senkronize edilirken hata: $e');
        }
      }
    }
  }

  /// Veritabanındaki tabloları döndürür
  Future<List<String>> _getTables(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return tables.map((table) => table['name'] as String).toList();
  }

  /// Son senkronizasyon zamanını alır
  Future<String> _getLastSyncTime(String table) async {
    final db = await _storageService.getDatabase();
    final result = await db.query(
      'sync_times',
      where: 'table_name = ?',
      whereArgs: [table],
    );

    if (result.isEmpty) {
      return DateTime(1970).toIso8601String();
    }

    return result.first['last_sync'] as String;
  }

  /// Son senkronizasyon zamanını günceller
  Future<void> _updateLastSyncTime(String table) async {
    final db = await _storageService.getDatabase();
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'sync_times',
      {
        'table_name': table,
        'last_sync': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Servisi temizler
  Future<void> dispose() async {
    stopSync();
    await _supabaseService.dispose();
  }
}
