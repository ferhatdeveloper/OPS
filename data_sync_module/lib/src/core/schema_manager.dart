// Dosya Adı: schema_manager.dart
// Açıklama: SQLite ve Supabase şema yönetimi için yardımcı sınıf
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/approval_status.dart';


/// {@template schema_manager}
/// SQLite ve Supabase şema yönetimi için yardımcı sınıf.
/// {@endtemplate}
class SchemaManager {
  final Database _db;
  final SupabaseClient _supabase;

  SchemaManager(this._db, this._supabase);

  /// SQLite tablosunu oluşturur
  Future<void> createSqliteTable(String tableName, List<String> columns) async {
    try {
      final baseColumns = [
        'id TEXT PRIMARY KEY',
        'created_at TEXT NOT NULL',
        'updated_at TEXT NOT NULL',
        'is_synced INTEGER NOT NULL DEFAULT 0',
        'is_deleted INTEGER NOT NULL DEFAULT 0',
        'approval_status INTEGER NOT NULL DEFAULT 0',
      ];

      final allColumns = [...baseColumns, ...columns];
      final createTableSql = '''
        CREATE TABLE IF NOT EXISTS $tableName (
          ${allColumns.join(', ')}
        )
      ''';

      await _db.execute(createTableSql);
      await _createIndexes(tableName);
    } catch (e) {
      print('SQLite tablo oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Supabase tablosunu oluşturur
  Future<void> createSupabaseTable(
      String tableName, List<String> columns) async {
    try {
      final exists = await _checkTableExists(tableName);
      if (!exists) {
        final createTableSql =
            _generateSupabaseCreateTableSql(tableName, columns);

        await _supabase
            .from('schema_migrations')
            .insert({
              'table_name': tableName,
              'sql': createTableSql,
            })
            .select()
            .then((value) => value);

        await _setupRLS(tableName);
      }
    } catch (e) {
      print('Supabase tablo oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Supabase'de tablo var mı kontrol eder
  Future<bool> _checkTableExists(String tableName) async {
    try {
      final result = await _supabase
          .from(tableName)
          .select()
          .limit(1)
          .then((value) => value);
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Supabase için CREATE TABLE SQL komutunu oluşturur
  String _generateSupabaseCreateTableSql(
      String tableName, List<String> columns) {
    final baseColumns = [
      'id uuid PRIMARY KEY DEFAULT uuid_generate_v4()',
      'created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()',
      'updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()',
      'is_synced BOOLEAN DEFAULT FALSE',
      'is_deleted BOOLEAN DEFAULT FALSE',
      'approval_status INTEGER DEFAULT 0',
    ];

    final allColumns = [...baseColumns, ...columns];
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        ${allColumns.join(',\n        ')}
      );
      
      -- Otomatik updated_at güncellemesi için trigger
      CREATE TRIGGER ${tableName}_set_updated_at
        BEFORE UPDATE ON $tableName
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at();
    ''';
  }

  /// RLS politikalarını ayarlar
  Future<void> _setupRLS(String tableName) async {
    try {
      await _supabase
          .from('schema_migrations')
          .insert({
            'table_name': tableName,
            'rls_enabled': true,
          })
          .select()
          .then((value) => value);

      // Temel RLS politikalarını oluştur
      final policies = '''
        -- RLS'yi etkinleştir
        ALTER TABLE $tableName ENABLE ROW LEVEL SECURITY;
        
        -- Tüm politikaları temizle
        DROP POLICY IF EXISTS "${tableName}_select_policy" ON $tableName;
        DROP POLICY IF EXISTS "${tableName}_insert_policy" ON $tableName;
        DROP POLICY IF EXISTS "${tableName}_update_policy" ON $tableName;
        DROP POLICY IF EXISTS "${tableName}_delete_policy" ON $tableName;
        
        -- Okuma politikası
        CREATE POLICY "${tableName}_select_policy"
          ON $tableName
          FOR SELECT
          USING (
            auth.role() = 'authenticated' AND (
              -- Kullanıcı admin ise tüm kayıtları görebilir
              auth.uid() IN (SELECT user_id FROM user_roles WHERE role = 'admin')
              OR
              -- Kullanıcı kendi şirketine ait kayıtları görebilir
              auth.uid() IN (SELECT user_id FROM user_companies WHERE company_id = company_id)
            )
          );
          
        -- Ekleme politikası
        CREATE POLICY "${tableName}_insert_policy"
          ON $tableName
          FOR INSERT
          WITH CHECK (
            auth.role() = 'authenticated' AND (
              -- Admin her şirkete kayıt ekleyebilir
              auth.uid() IN (SELECT user_id FROM user_roles WHERE role = 'admin')
              OR
              -- Kullanıcı kendi şirketine kayıt ekleyebilir
              auth.uid() IN (SELECT user_id FROM user_companies WHERE company_id = company_id)
            )
          );
          
        -- Güncelleme politikası
        CREATE POLICY "${tableName}_update_policy"
          ON $tableName
          FOR UPDATE
          USING (
            auth.role() = 'authenticated' AND (
              -- Admin her kaydı güncelleyebilir
              auth.uid() IN (SELECT user_id FROM user_roles WHERE role = 'admin')
              OR
              -- Kullanıcı kendi şirketinin kayıtlarını güncelleyebilir
              auth.uid() IN (SELECT user_id FROM user_companies WHERE company_id = company_id)
            )
          )
          WITH CHECK (
            auth.role() = 'authenticated' AND (
              -- Admin her kaydı güncelleyebilir
              auth.uid() IN (SELECT user_id FROM user_roles WHERE role = 'admin')
              OR
              -- Kullanıcı kendi şirketinin kayıtlarını güncelleyebilir
              auth.uid() IN (SELECT user_id FROM user_companies WHERE company_id = company_id)
              AND
              -- Onay durumu kontrolü
              (
                -- Onaylanmamış kayıtlar güncellenebilir
                approval_status = ${ApprovalStatus.pending.value}
                OR
                -- Reddedilmiş kayıtlar güncellenebilir
                approval_status = ${ApprovalStatus.rejected.value}
                OR
                -- Admin onaylanmış kayıtları da güncelleyebilir
                (approval_status = ${ApprovalStatus.approved.value} AND auth.uid() IN (
                  SELECT user_id FROM user_roles WHERE role = 'admin'
                ))
              )
            )
          );
          
        -- Silme politikası
        CREATE POLICY "${tableName}_delete_policy"
          ON $tableName
          FOR DELETE
          USING (
            auth.role() = 'authenticated' AND
            -- Sadece admin silebilir
            auth.uid() IN (SELECT user_id FROM user_roles WHERE role = 'admin')
          );
          
        -- Tetikleyiciler
        CREATE TRIGGER ${tableName}_before_update
          BEFORE UPDATE ON $tableName
          FOR EACH ROW
          EXECUTE FUNCTION check_approval_status();
          
        CREATE TRIGGER ${tableName}_after_update
          AFTER UPDATE ON $tableName
          FOR EACH ROW
          EXECUTE FUNCTION log_changes();
      ''';

      await _supabase.rpc('execute_sql', params: {'sql': policies});
    } catch (e) {
      print('RLS politikaları oluşturma hatası: $e');
      rethrow;
    }
  }

  /// SQLite tablosundan Supabase tablosuna şema eşleme
  Future<void> migrateSchemaToSupabase(String tableName) async {
    try {
      final tableInfo = await _db.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]);

      if (tableInfo.isEmpty) {
        throw Exception('Tablo bulunamadı: $tableName');
      }

      final sqliteSchema = tableInfo.first['sql'] as String;
      final supabaseSchema = _convertToSupabaseSchema(sqliteSchema);

      await _supabase
          .from('schema_migrations')
          .insert({
            'table_name': tableName,
            'sql': supabaseSchema,
          })
          .select()
          .then((value) => value);

      await _setupRLS(tableName);
    } catch (e) {
      print('Şema migrasyon hatası: $e');
      rethrow;
    }
  }

  /// SQLite şemasını Supabase formatına dönüştürür
  String _convertToSupabaseSchema(String sqliteSchema) {
    var schema = sqliteSchema
        .replaceAll('INTEGER', 'INTEGER')
        .replaceAll('REAL', 'DOUBLE PRECISION')
        .replaceAll('TEXT', 'TEXT')
        .replaceAll('BLOB', 'BYTEA');

    schema = schema.replaceAll('AUTOINCREMENT', '');

    schema = schema.replaceAll('id INTEGER PRIMARY KEY',
        'id uuid PRIMARY KEY DEFAULT uuid_generate_v4()');

    schema = schema
        .replaceAll('INTEGER NOT NULL DEFAULT 0', 'BOOLEAN DEFAULT FALSE')
        .replaceAll('INTEGER NOT NULL DEFAULT 1', 'BOOLEAN DEFAULT TRUE');

    schema = schema.replaceAll(
        'TEXT NOT NULL', 'TIMESTAMP WITH TIME ZONE DEFAULT NOW()');

    return schema;
  }

  /// İndeksleri oluşturur
  Future<void> _createIndexes(String tableName) async {
    try {
      final indexes = [
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_sync ON $tableName (is_synced)',
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_approval_status ON $tableName (approval_status)',
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_deleted ON $tableName (is_deleted)',
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_updated ON $tableName (updated_at)',
      ];

      // Transaction içinde indeksleri oluştur
      await _db.transaction((txn) async {
        for (var index in indexes) {
          await txn.execute(index);
        }
      });
    } catch (e) {
      print('İndeks oluşturma hatası: $e');
      rethrow;
    }
  }
}
