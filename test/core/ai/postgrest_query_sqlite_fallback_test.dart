// Dosya Adı: postgrest_query_sqlite_fallback_test.dart
// Açıklama: PostgREST hata → SQLite allowlist fallback unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/features/ai_chat_sqlite_runner.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_runner.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_spec.dart';
import 'package:exfin_ops/core/tenant/postgrest_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Merkez her zaman hata — fallback zorunlu.
class _FailingPostgrestClient extends PostgrestHttpClient {
  _FailingPostgrestClient() : super();

  @override
  bool get isConfigured => true;

  @override
  Future<List<Map<String, dynamic>>> getRows(
    String path, {
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
  }) async {
    throw const PostgrestHttpException(
      statusCode: 500,
      message: 'center down',
    );
  }
}

/// Merkez URL yok.
class _UnconfiguredPostgrestClient extends PostgrestHttpClient {
  _UnconfiguredPostgrestClient() : super();

  @override
  bool get isConfigured => false;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      'file:ai_report_fb_${DateTime.now().microsecondsSinceEpoch}'
      '?mode=memory&cache=private',
      options: OpenDatabaseOptions(
        singleInstance: false,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
CREATE TABLE customers (
  id TEXT PRIMARY KEY, code TEXT, name TEXT, balance REAL,
  il TEXT, phone TEXT, is_active INTEGER, created_at TEXT
)''');
          await db.execute('''
CREATE TABLE routes (
  id TEXT PRIMARY KEY, name TEXT, is_active INTEGER
)''');
          await db.execute('''
CREATE TABLE route_customers (
  id TEXT PRIMARY KEY, route_id TEXT, customer_id TEXT, visit_order INTEGER
)''');
          await db.insert('customers', {
            'id': 'c1',
            'code': 'C001',
            'name': 'Rotalı Market',
            'balance': 10,
            'il': 'Ankara',
            'phone': '1',
            'is_active': 1,
            'created_at': '2026-01-01',
          });
          await db.insert('customers', {
            'id': 'c2',
            'code': 'C002',
            'name': 'Rutsuz Market',
            'balance': 20,
            'il': 'İzmir',
            'phone': '2',
            'is_active': 1,
            'created_at': '2026-01-02',
          });
          await db.insert('routes', {
            'id': 'r1',
            'name': 'Pazartesi',
            'is_active': 1,
          });
          await db.insert('route_customers', {
            'id': 'rc1',
            'route_id': 'r1',
            'customer_id': 'c1',
            'visit_order': 1,
          });
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('PostgrestQueryRunner SQLite fallback', () {
    test('HTTP hata → yerel satır + usedLocal', () async {
      final runner = PostgrestQueryRunner(
        client: _FailingPostgrestClient(),
        dbFactory: () async => db,
      );
      final r = await runner.run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name', 'balance'],
          limit: 50,
        ),
      );
      expect(r.ok, isTrue);
      expect(r.usedLocal, isTrue);
      expect(r.noteKey, 'field_sales.ai_reports.local_sqlite_note');
      expect(r.rows.length, greaterThanOrEqualTo(2));
      expect(
        r.rows.map((e) => e['code']).toList(),
        containsAll(['C001', 'C002']),
      );
    });

    test('merkez yapılandırılmamış → SQLite', () async {
      final runner = PostgrestQueryRunner(
        client: _UnconfiguredPostgrestClient(),
        dbFactory: () async => db,
      );
      final r = await runner.run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name'],
        ),
      );
      expect(r.ok, isTrue);
      expect(r.usedLocal, isTrue);
      expect(r.rows, isNotEmpty);
    });

    test('city alias → il kolonundan okur', () async {
      final runner = PostgrestQueryRunner(
        client: _FailingPostgrestClient(),
        dbFactory: () async => db,
      );
      final r = await runner.run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'city'],
          limit: 10,
        ),
      );
      expect(r.ok, isTrue);
      expect(r.rows.any((e) => e['city'] == 'İzmir'), isTrue);
    });
  });

  group('customersWithoutRoute SQLite', () {
    test('title hint → yalnız rutsuz müşteri', () async {
      final runner = PostgrestQueryRunner(
        client: _FailingPostgrestClient(),
        dbFactory: () async => db,
      );
      final r = await runner.run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name'],
          limit: 100,
        ),
        reportTitle: 'Rut planı olmayan müşteriler',
      );
      expect(r.ok, isTrue);
      expect(r.usedLocal, isTrue);
      expect(r.rows.map((e) => e['code']).toList(), ['C002']);
      expect(r.localFilterNoteKey, isNotNull);
    });

    test('AiChatSqliteRunner intent doğrudan', () async {
      final r = await AiChatSqliteRunner(db: db).run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name'],
        ),
        intent: LocalSqliteIntent.customersWithoutRoute,
      );
      expect(r.ok, isTrue);
      expect(r.rows, hasLength(1));
      expect(r.rows.first['code'], 'C002');
      expect(r.filterNoteKey, 'field_sales.ai_reports.note_without_route');
    });

    test('route tabloları yok → customers + açıklama', () async {
      final bare = await databaseFactoryFfi.openDatabase(
        'file:ai_report_bare_${DateTime.now().microsecondsSinceEpoch}'
        '?mode=memory&cache=private',
        options: OpenDatabaseOptions(
          singleInstance: false,
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
CREATE TABLE customers (
  id TEXT PRIMARY KEY, code TEXT, name TEXT, balance REAL,
  il TEXT, phone TEXT, is_active INTEGER, created_at TEXT
)''');
            await db.insert('customers', {
              'id': 'x1',
              'code': 'X1',
              'name': 'Tek',
              'balance': 1,
              'il': 'A',
              'is_active': 1,
            });
          },
        ),
      );
      final r = await AiChatSqliteRunner(db: bare).run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name'],
        ),
        intent: LocalSqliteIntent.customersWithoutRoute,
      );
      expect(r.ok, isTrue);
      expect(r.rows, hasLength(1));
      expect(
        r.filterNoteKey,
        'field_sales.ai_reports.note_without_route_fallback',
      );
      await bare.close();
    });
  });

  group('LocalSqliteIntentDetect', () {
    test('Türkçe başlık', () {
      expect(
        LocalSqliteIntentDetect.fromTitle('Rut planı olmayan müşteriler'),
        LocalSqliteIntent.customersWithoutRoute,
      );
    });

    test('ilgisiz başlık', () {
      expect(
        LocalSqliteIntentDetect.fromTitle('Aktif cariler'),
        LocalSqliteIntent.none,
      );
    });
  });
}
