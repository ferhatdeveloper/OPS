// Dosya Adı: schema_manager_test.dart
// Açıklama: SchemaManager için test senaryoları
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

import 'package:exfin_ops/core/sync/schema_manager.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'schema_manager_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<SupabaseClient>(as: #MockSupabaseClient),
  MockSpec<SupabaseQueryBuilder>(as: #MockSupabaseQueryBuilder),
  MockSpec<PostgrestFilterBuilder<List<Map<String, dynamic>>>>(
    as: #MockPostgrestFilterBuilder,
  ),
  MockSpec<PostgrestTransformBuilder<List<Map<String, dynamic>>>>(
    as: #MockPostgrestTransformBuilder,
  ),
])
void main() {
  late Database db;
  late SchemaManager schemaManager;
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late MockPostgrestTransformBuilder mockTransformBuilder;

  setUp(() async {
    // SQLite FFI başlat
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Geçici veritabanı oluştur
    final databasePath = await getDatabasesPath();
    final dbPath = path.join(databasePath, 'test.db');
    db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Test için gerekli tabloları oluştur
          await db.execute(SqlQuerys.createSyncMetadataTable);
        },
      ),
    );

    // Mock nesneleri oluştur
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockTransformBuilder = MockPostgrestTransformBuilder();

    // SchemaManager örneği oluştur
    schemaManager = SchemaManager(db);

    // Mock davranışları ayarla
    when(mockSupabase.from(any)).thenAnswer((_) => mockQueryBuilder);
    when(mockQueryBuilder.select(any)).thenAnswer((_) => mockFilterBuilder);
    when(mockQueryBuilder.insert(any)).thenAnswer((_) => mockFilterBuilder);
    when(mockQueryBuilder.update(any)).thenAnswer((_) => mockFilterBuilder);
    when(mockQueryBuilder.delete()).thenAnswer((_) => mockFilterBuilder);

    // FilterBuilder davranışlarını ayarla
    when(mockFilterBuilder.select(any)).thenAnswer((_) => mockTransformBuilder);
    when(mockFilterBuilder.eq(any, any)).thenAnswer((_) => mockFilterBuilder);
    when(mockFilterBuilder.neq(any, any)).thenAnswer((_) => mockFilterBuilder);
    when(mockFilterBuilder.limit(any)).thenAnswer((_) => mockTransformBuilder);

    // TransformBuilder davranışlarını ayarla
    when(mockTransformBuilder.single()).thenAnswer((_) =>
        mockFilterBuilder as PostgrestFilterBuilder<Map<String, dynamic>>);
    when(mockTransformBuilder.then(any, onError: anyNamed('onError')))
        .thenAnswer((invocation) async {
      return [
        {'table_name': 'test_table', 'sql': SqlQuerys.createTestTable}
      ];
    });
  });

  tearDown(() async {
    // Veritabanını kapat ve sil
    await db.close();
    await deleteDatabase(await getDatabasesPath());
  });

  group('SchemaManager Tests', () {
    test('createSqliteTable should create table with correct schema', () async {
      // Test verileri
      const tableName = 'test_table';
      final columns = [
        'name TEXT NOT NULL',
        'age INTEGER',
        'is_active INTEGER DEFAULT 1',
      ];

      // Tabloyu oluştur
      await schemaManager.createSqliteTable(tableName, columns);

      // Tablo varlığını kontrol et - SqlQuerys.dart kullanarak
      final tables = await db.rawQuery(SqlQuerys.getTableExistsSql(tableName));

      expect(tables.length, 1);
      expect(tables.first['name'], tableName);

      // İndeksleri kontrol et - SqlQuerys.dart kullanarak
      final indexes =
          await db.rawQuery(SqlQuerys.getTableIndexesSql(tableName));

      expect(indexes.length, 5); // 5 indeks oluşturulmalı
    });

    test('should validate table schema correctly', () async {
      // Test verileri - duplicate column olmayacak şekilde düzenle
      const tableName = 'validation_test_table';
      final columns = [
        'name TEXT NOT NULL',
        'age INTEGER',
        'is_active INTEGER DEFAULT 1',
      ];

      // Tabloyu oluştur
      await schemaManager.createSqliteTable(tableName, columns);

      // Tablo şemasını kontrol et - SqlQuerys.dart kullanarak
      final tableInfo = await db.rawQuery(SqlQuerys.getTableInfoSql(tableName));

      // Temel kolonlar + otomatik eklenen kolonlar (id, created_at, updated_at, is_synced, is_deleted, approval_status)
      expect(tableInfo.length, 9); // 3 test kolonu + 6 otomatik kolon

      // Gerekli kolonların varlığını kontrol et
      final columnNames =
          tableInfo.map((col) => col['name'] as String).toList();
      expect(columnNames, contains('id'));
      expect(columnNames, contains('name'));
      expect(columnNames, contains('age'));
      expect(columnNames, contains('is_active'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
      expect(columnNames, contains('is_deleted'));
      expect(columnNames, contains('is_synced'));
      expect(columnNames, contains('approval_status'));
    });

    test('should handle table creation with SqlQuerys constants', () async {
      // SqlQuerys.dart'tan test tablosu oluştur
      await db.execute(SqlQuerys.createTestTable);

      // Tablo varlığını kontrol et
      final tables =
          await db.rawQuery(SqlQuerys.getTableExistsSql('test_table'));
      expect(tables.length, 1);

      // Test verisi ekle
      await db.execute(SqlQuerys.insertTestData, [
        'Test User',
        25,
        1,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ]);

      // Test verisini sorgula
      final results = await db.rawQuery(SqlQuerys.selectTestData);
      expect(results.length, 1);
      expect(results.first['name'], 'Test User');
      expect(results.first['age'], 25);
    });

    test('should handle table operations with SqlQuerys functions', () async {
      const tableName = 'dynamic_test_table';

      // Dinamik tablo oluştur
      final createSql = SqlQuerys.getSelectWithWhereSql(tableName, '1=1');
      expect(createSql, contains('SELECT * FROM $tableName WHERE 1=1'));

      // Dinamik kolon listesi ile sorgu
      final columns = ['id', 'name', 'age'];
      final selectSql =
          SqlQuerys.getSelectColumnsSql(tableName, columns, where: 'age > 18');
      expect(selectSql,
          contains('SELECT id, name, age FROM $tableName WHERE age > 18'));

      // Dinamik insert sorgusu
      final insertSql = SqlQuerys.getInsertSql(tableName, columns);
      expect(insertSql,
          contains('INSERT INTO $tableName (id, name, age) VALUES (?, ?, ?)'));

      // Dinamik update sorgusu
      final updateSql =
          SqlQuerys.getUpdateSql(tableName, ['name', 'age'], 'id = ?');
      expect(updateSql,
          contains('UPDATE $tableName SET name = ?, age = ? WHERE id = ?'));

      // Dinamik delete sorgusu
      final deleteSql = SqlQuerys.getDeleteSql(tableName, 'id = ?');
      expect(deleteSql, contains('DELETE FROM $tableName WHERE id = ?'));
    });
  });
}
