// Dosya Adı: sync_manager.dart
// Açıklama: Senkronizasyon yöneticisi sınıfı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'schema_manager.dart';
import 'sync_service.dart';
import '../services/backup_manager.dart';
import '../models/sync_config.dart';
import '../models/sync_result.dart';

/// {@template sync_manager}
/// Senkronizasyon yöneticisi sınıfı.
/// Supabase ve SQLite senkronizasyonunu yönetir.
/// {@endtemplate}
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  late final SchemaManager _schemaManager;
  late final SyncService _syncService;
  late final BackupManager _backupManager;
  late final Database _db;
  late final SupabaseClient _supabase;
  late final SyncConfig _config;
  bool _isInitialized = false;

  /// Senkronizasyon durumu stream'i
  Stream<bool> get syncStatus => _syncService.syncStatus;

  /// Senkronizasyon konfigürasyonu
  SyncConfig get config => _config;

  /// Servisi başlatır
  Future<void> initialize({
    required Database database,
    required SupabaseClient supabase,
    SyncConfig? config,
  }) async {
    if (_isInitialized) return;

    try {
      _db = database;
      _supabase = supabase;
      _config = config ?? SyncConfig.defaultConfig;

      _schemaManager = SchemaManager(_db, _supabase);
      _syncService = SyncService(_supabase, _db);
      _backupManager = BackupManager(_db, _supabase);

      // Web platformunda SQLite kullanılmaz
      if (!kIsWeb) {
        await _createSyncMetadataTable();
      }

      _isInitialized = true;
      print('SyncManager başarıyla başlatıldı');
    } catch (e) {
      print('SyncManager başlatma hatası: $e');
      rethrow;
    }
  }

  /// Senkronizasyon metadata tablosunu oluşturur
  Future<void> _createSyncMetadataTable() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        table_name TEXT PRIMARY KEY,
        last_sync TEXT NOT NULL,
        sync_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Yeni bir tablo ekler ve senkronize eder
  Future<void> addTable(String tableName, List<String> columns) async {
    _checkInitialized();

    if (!kIsWeb) {
      // SQLite tablosunu oluştur
      await _schemaManager.createSqliteTable(tableName, columns);

      // Supabase'e şemayı aktar
      await _schemaManager.migrateSchemaToSupabase(tableName);

      // Realtime dinleyiciyi başlat
      await _syncService.setupRealtimeSync(tableName);
    }
  }

  /// Mevcut bir SQLite tablosunu Supabase ile senkronize eder
  Future<void> syncExistingTable(String tableName) async {
    _checkInitialized();

    if (!kIsWeb) {
      await _schemaManager.migrateSchemaToSupabase(tableName);
      await _syncService.setupRealtimeSync(tableName);
    }
  }

  /// Manuel senkronizasyonu başlatır
  Future<SyncResult> syncNow({String? tableName}) async {
    _checkInitialized();

    if (!kIsWeb) {
      if (tableName != null) {
        return await _syncService.syncTable(tableName);
      } else {
        return await _syncService.syncAll();
      }
    }

    return SyncResult.success();
  }

  /// Yeni bir tablo oluşturur ve senkronize eder
  Future<void> createAndSyncTable(
      String tableName, List<String> columns) async {
    _checkInitialized();

    try {
      // Yedekleme etkinse yedek al
      if (_config.backupEnabled) {
        await Future.wait([
          _backupManager.backupSqliteDatabase(),
          _backupManager.backupSupabaseDatabase(),
        ]);
      }

      // SQLite tablosunu oluştur
      await _schemaManager.createSqliteTable(tableName, columns);

      // Supabase tablosunu oluştur
      await _schemaManager.createSupabaseTable(tableName, columns);

      // Realtime senkronizasyonu başlat
      await _syncService.setupRealtimeSync(tableName);

      print('$tableName tablosu oluşturuldu ve senkronize edildi');
    } catch (e) {
      print('Tablo oluşturma ve senkronizasyon hatası: $e');
      rethrow;
    }
  }

  /// Tüm tabloları senkronize eder
  Future<SyncResult> syncAll() async {
    _checkInitialized();
    return await _syncService.syncAll();
  }

  /// Belirtilen tabloyu senkronize eder
  Future<SyncResult> syncTable(String tableName) async {
    _checkInitialized();
    return await _syncService.syncTable(tableName);
  }

  /// Şemayı Supabase'e migrate eder
  Future<void> migrateSchemaToSupabase(String tableName) async {
    _checkInitialized();
    await _schemaManager.migrateSchemaToSupabase(tableName);
  }

  /// Yedekleme işlemlerini yönetir
  Future<void> manageBackups() async {
    _checkInitialized();

    try {
      // Yedekleri listele
      final backups = await _backupManager.listBackups();
      print('Mevcut yedekler:');
      for (var backup in backups) {
        print(backup.toString());
      }

      // Eski yedekleri temizle
      await _backupManager.cleanupOldBackups();
    } catch (e) {
      print('Yedek yönetimi hatası: $e');
      rethrow;
    }
  }

  /// Yedekten geri yükleme yapar
  Future<void> restoreFromBackup(String backupPath) async {
    _checkInitialized();

    try {
      // Mevcut durumu yedekle
      if (_config.backupEnabled) {
        await Future.wait([
          _backupManager.backupSqliteDatabase(),
          _backupManager.backupSupabaseDatabase(),
        ]);
      }

      // Yedekten geri yükle
      await _backupManager.restoreFromBackup(backupPath);

      print('Yedekten geri yükleme başarılı: $backupPath');
    } catch (e) {
      print('Geri yükleme hatası: $e');
      rethrow;
    }
  }

  /// Konfigürasyonu günceller
  Future<void> updateConfig(SyncConfig newConfig) async {
    _checkInitialized();

    _config = newConfig;
    await _syncService.updateConfig(newConfig);

    print('Senkronizasyon konfigürasyonu güncellendi');
  }

  /// Senkronizasyon durumunu kontrol eder
  Future<Map<String, dynamic>> getSyncStatus() async {
    _checkInitialized();

    final tables = await _getTables();
    final status = <String, dynamic>{};

    for (final table in tables) {
      final lastSync = await _getLastSyncTime(table);
      final pendingCount = await _getPendingCount(table);

      status[table] = {
        'lastSync': lastSync?.toIso8601String(),
        'pendingCount': pendingCount,
        'isOnline': await _checkConnectivity(),
      };
    }

    return status;
  }

  /// SQLite tablolarını alır
  Future<List<String>> _getTables() async {
    final result = await _db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    return result.map((row) => row['name'] as String).toList();
  }

  /// Son senkronizasyon zamanını alır
  Future<DateTime?> _getLastSyncTime(String tableName) async {
    final result = await _db.query(
      'sync_metadata',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    if (result.isEmpty) {
      return null;
    }

    return DateTime.parse(result.first['last_sync'] as String);
  }

  /// Bekleyen kayıt sayısını alır
  Future<int> _getPendingCount(String tableName) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE approval_status = ? AND is_synced = ?',
      [1, 0], // Onaylanmış ve senkronize edilmemiş
    );

    return result.first['count'] as int;
  }

  /// Bağlantı durumunu kontrol eder
  Future<bool> _checkConnectivity() async {
    try {
      await _supabase.from('sync_health').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Servisi dispose eder
  void dispose() {
    if (!kIsWeb) {
      _syncService.dispose();
    }
    _isInitialized = false;
  }

  /// Başlatılma durumunu kontrol eder
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'SyncManager başlatılmamış. Önce initialize() metodunu çağırın.');
    }
  }
}
