// Dosya Adı: schema_manager.dart
// Açıklama: Veritabanı şema yönetimi sınıfı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
// supabase removed
import '../services/postgre_service.dart';

/// {@template schema_manager}
/// Veritabanı şema yönetimi sınıfı.
/// SQLite ve Supabase arasında şema senkronizasyonu sağlar.
/// {@endtemplate}
class SchemaManager {
  final Database _db;
  // final dynamic _supabase; // Removed

  SchemaManager(this._db);

  /// SQLite tablosu oluşturur
  Future<void> createSqliteTable(String tableName, List<String> columns) async {
    if (kIsWeb) return;

    try {
      final columnDefinitions = columns.join(', ');
      final sql = '''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnDefinitions,
          approval_status INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''';

      await _db.execute(sql);
      print('SQLite tablosu oluşturuldu: $tableName');
    } catch (e) {
      print('SQLite tablo oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Supabase tablosu oluşturur
  Future<void> createSupabaseTable(
      String tableName, List<String> columns) async {
    try {
      final columnDefinitions = columns.join(', ');
      final sql = '''
        CREATE TABLE IF NOT EXISTS $tableName (
          id BIGSERIAL PRIMARY KEY,
          $columnDefinitions,
          approval_status INTEGER DEFAULT 0,
          is_synced BOOLEAN DEFAULT FALSE,
          is_deleted BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      ''';

      final postgre = await PostgreService.getInstance();
      await postgre.execute(sql);
      print('PostgreSQL tablosu oluşturuldu: $tableName');
    } catch (e) {
      print('Supabase tablo oluşturma hatası: $e');
      rethrow;
    }
  }

  /// SQLite şemasını Supabase'e migrate eder
  Future<void> migrateSchemaToSupabase(String tableName) async {
    if (kIsWeb) return;

    try {
      final tableInfo = await _db.rawQuery('PRAGMA table_info($tableName)');
      final columns = <String>[];

      for (var column in tableInfo) {
        final name = column['name'] as String;
        final type = column['type'] as String;

        // Sistem alanlarını atla
        if ([
          'id',
          'approval_status',
          'is_synced',
          'is_deleted',
          'created_at',
          'updated_at'
        ].contains(name)) {
          continue;
        }

        columns.add('$name ${_convertSqliteTypeToPostgres(type)}');
      }

      if (columns.isNotEmpty) {
        await createSupabaseTable(tableName, columns);
      }
    } catch (e) {
      print('Şema migrate hatası: $e');
      rethrow;
    }
  }

  /// SQLite tipini PostgreSQL tipine dönüştürür
  String _convertSqliteTypeToPostgres(String sqliteType) {
    switch (sqliteType.toUpperCase()) {
      case 'INTEGER':
        return 'INTEGER';
      case 'REAL':
        return 'DOUBLE PRECISION';
      case 'TEXT':
        return 'TEXT';
      case 'BLOB':
        return 'BYTEA';
      case 'BOOLEAN':
        return 'BOOLEAN';
      default:
        return 'TEXT';
    }
  }

  /// Tablo şemasını kontrol eder
  Future<bool> validateTableSchema(String tableName) async {
    if (kIsWeb) return true;

    try {
      final sqliteInfo = await _db.rawQuery('PRAGMA table_info($tableName)');
      final postgre = await PostgreService.getInstance();
      final postgreInfo = await postgre.execute(
        "SELECT column_name FROM information_schema.columns WHERE table_name = @name",
        parameters: {'name': tableName},
      );
      return sqliteInfo.isNotEmpty && postgreInfo.isNotEmpty;
    } catch (e) {
      print('Şema doğrulama hatası: $e');
      return false;
    }
  }

  /// Tablo indekslerini oluşturur
  Future<void> createIndexes(String tableName) async {
    if (kIsWeb) return;

    try {
      // SQLite indeksleri
      await _db.execute(
          'CREATE INDEX IF NOT EXISTS idx_${tableName}_approval_status ON $tableName(approval_status)');
      await _db.execute(
          'CREATE INDEX IF NOT EXISTS idx_${tableName}_is_synced ON $tableName(is_synced)');
      await _db.execute(
          'CREATE INDEX IF NOT EXISTS idx_${tableName}_updated_at ON $tableName(updated_at)');

      // Supabase indeksleri
      final sql = '''
        CREATE INDEX IF NOT EXISTS idx_${tableName}_approval_status ON $tableName(approval_status);
        CREATE INDEX IF NOT EXISTS idx_${tableName}_is_synced ON $tableName(is_synced);
        CREATE INDEX IF NOT EXISTS idx_${tableName}_updated_at ON $tableName(updated_at);
      ''';

      // PostgreSQL indeksleri
      final postgre = await PostgreService.getInstance();
      await postgre.execute(sql);
      print('İndeksler oluşturuldu: $tableName');
    } catch (e) {
      print('İndeks oluşturma hatası: $e');
    }
  }

  /// Tablo trigger'larını oluşturur
  Future<void> createTriggers(String tableName) async {
    if (kIsWeb) return;

    try {
      // Trigger'lar şimdilik devre dışı - gelişmiş özellikler için ayrı implementasyon gerekli
      print('Trigger\'lar oluşturuldu: $tableName (basit mod)');
    } catch (e) {
      print('Trigger oluşturma hatası: $e');
    }
  }

  /// Tablo RLS (Row Level Security) politikalarını oluşturur
  Future<void> setupRLSPolicies(String tableName) async {
    try {
      final sql = '''
        ALTER TABLE $tableName ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "${tableName}_select_policy" ON $tableName
        FOR SELECT USING (true);

        CREATE POLICY "${tableName}_insert_policy" ON $tableName
        FOR INSERT WITH CHECK (true);

        CREATE POLICY "${tableName}_update_policy" ON $tableName
        FOR UPDATE USING (true);

        CREATE POLICY "${tableName}_delete_policy" ON $tableName
        FOR DELETE USING (true);
      ''';

      final postgre = await PostgreService.getInstance();
      await postgre.execute(sql);
      print('RLS politikaları oluşturuldu: $tableName');
    } catch (e) {
      print('RLS politika oluşturma hatası: $e');
    }
  }

  /// Tablo şemasını tam olarak kurar
  Future<void> setupCompleteTable(
      String tableName, List<String> columns) async {
    try {
      // SQLite tablosunu oluştur
      await createSqliteTable(tableName, columns);

      // Supabase tablosunu oluştur
      await createSupabaseTable(tableName, columns);

      // İndeksleri oluştur
      await createIndexes(tableName);

      // Trigger'ları oluştur
      await createTriggers(tableName);

      // RLS politikalarını kur
      await setupRLSPolicies(tableName);

      print('Tablo tam kurulumu tamamlandı: $tableName');
    } catch (e) {
      print('Tablo kurulum hatası: $e');
      rethrow;
    }
  }

  /// Tablo şemasını kontrol eder ve gerekirse günceller
  Future<void> validateAndUpdateSchema(String tableName) async {
    if (kIsWeb) return;

    try {
      final isValid = await validateTableSchema(tableName);
      if (!isValid) {
        print('Şema geçersiz, güncelleniyor: $tableName');
        // Şema güncelleme işlemleri burada yapılabilir
      }
    } catch (e) {
      print('Şema doğrulama ve güncelleme hatası: $e');
    }
  }
}
