// Dosya Adı: partial_reports_query_test.dart
// Açıklama: Kısmen paylaşımlı ziyaret raporları — ayrık sorgu çıktıları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_action_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/other/viewmodel/other_report_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(SqlQuerys.createCustomersTable);
        await database.execute(SqlQuerys.createVisitsTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha',
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta',
    });

    await db.insert('visits', {
      'id': 'v1',
      'customer_id': 'c1',
      'user_id': 'sp1',
      'check_in_at': '2026-07-20T09:00:00.000',
      'check_out_at': '2026-07-20T09:30:00.000',
      'status': 'Completed',
    });
    await db.insert('visits', {
      'id': 'v2',
      'customer_id': 'c1',
      'user_id': 'sp1',
      'check_in_at': '2026-07-20T11:00:00.000',
      'status': 'Completed',
    });
    await db.insert('visits', {
      'id': 'v3',
      'customer_id': 'c2',
      'user_id': 'sp1',
      'check_in_at': '2026-07-21T10:00:00.000',
      'status': 'Open',
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('plasiyer_gunluk günlük özet satırı üretir', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'plasiyer_gunluk',
      snapshot: MbtReportParamSnapshot(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, hasLength(2));
    final day20 = rows.firstWhere((r) => r['date'] == '20.07.2026');
    expect(day20['amount'], '2.00');
    expect(day20['salesperson'], 'sp1');
  });

  test('plasiyer_ziyaret_ozet cari bazlı adet', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'plasiyer_ziyaret_ozet',
      snapshot: MbtReportParamSnapshot(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, hasLength(2));
    final alpha = rows.firstWhere((r) => r['code'] == 'C001');
    expect(alpha['amount'], '2.00');
    expect(alpha['title'], 'Alpha');
  });

  test('ziyaret_listesi satır bazlı visit_time içerir', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'ziyaret_listesi',
      snapshot: MbtReportParamSnapshot(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows.length, greaterThanOrEqualTo(3));
    expect(rows.first.containsKey('visit_time'), isTrue);
  });
}
