// Dosya Adı: partial_reports_alignment_test.dart
// Açıklama: Kısmi rapor sorgularının ad/kolon ayrımı (ziyaret/KPI/kasa/rota)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_action_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
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
        await database.execute(SqlQuerys.createInvoicesTable);
        await database.execute(SqlQuerys.createCollectionsTable);
        await database.execute(SqlQuerys.createOrdersTable);
        await database.execute(SqlQuerys.createCashCardsTable);
        await database.execute(SqlQuerys.createRoutesTable);
        await database.execute(SqlQuerys.createRouteCustomersTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha',
      'latitude': 41.01,
      'longitude': 28.97,
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta',
      'latitude': 41.02,
      'longitude': 28.98,
    });
    await db.insert('visits', {
      'id': 'v1',
      'customer_id': 'c1',
      'user_id': 'sp1',
      'check_in_at': '2026-07-28T09:00:00.000',
      'check_out_at': '2026-07-28T09:30:00.000',
      'status': 'completed',
    });
    await db.insert('visits', {
      'id': 'v2',
      'customer_id': 'c2',
      'user_id': 'sp1',
      'check_in_at': '2026-07-28T11:00:00.000',
      'status': 'open',
    });
    await db.insert('cash_cards', {
      'id': 'cc1',
      'code': '01',
      'name': 'Ana Kasa',
      'name_key': 'cash_main',
      'is_active': 1,
    });
    await db.insert('collections', {
      'id': 'col1',
      'customer_id': 'c1',
      'amount': 150,
      'payment_type': 'cash',
      'cash_code': '01',
      'collection_date': '2026-07-28T10:00:00.000',
    });
    await db.insert('routes', {
      'id': 'r1',
      'name': 'Pazartesi',
      'salesperson_id': 'sp1',
      'day_of_week': 1,
      'is_active': 1,
    });
    await db.insert('route_customers', {
      'id': 'rc1',
      'route_id': 'r1',
      'customer_id': 'c1',
      'visit_order': 1,
      'is_mandatory': 1,
    });
    await db.insert('route_customers', {
      'id': 'rc2',
      'route_id': 'r1',
      'customer_id': 'c2',
      'visit_order': 2,
      'is_mandatory': 1,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('plasiyer_gunluk günlük özet (adet)', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'plasiyer_gunluk',
      snapshot: MbtReportParamSnapshot(
        dateFrom: DateTime(2026, 7, 28),
        dateTo: DateTime(2026, 7, 28),
      ),
    );
    expect(rows, isNotEmpty);
    expect(rows.first['salesperson'], 'sp1');
    expect(rows.first['quantity'], '2');
  });

  test('plasiyer_ziyaret_ozet cari bazlı adet', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'plasiyer_ziyaret_ozet',
      snapshot: MbtReportParamSnapshot(
        dateFrom: DateTime(2026, 7, 28),
        dateTo: DateTime(2026, 7, 28),
      ),
    );
    expect(rows.length, greaterThanOrEqualTo(2));
    expect(rows.any((r) => r['code'] == 'C001'), isTrue);
    expect(rows.firstWhere((r) => r['code'] == 'C001')['amount'], '1.00');
  });

  test('yonetici_kpi sipariş satırı ekler', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'yonetici_kpi',
      snapshot: MbtReportParamSnapshot(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows.any((r) => r['code'] == 'SIPARIS'), isTrue);
    expect(rows.any((r) => r['code'] == 'SATIS'), isTrue);
  });

  test('finans_kasa_bakiye collections toplami', () async {
    final cols = ReportLayoutDefaults.forReportId('finans_kasa_bakiye')
        .visibleColumns
        .map((c) => c.id);
    expect(cols, contains('balance'));

    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'finans_kasa_bakiye',
      snapshot: const MbtReportParamSnapshot(),
    );
    expect(rows, isNotEmpty);
    expect(rows.first['balance'], '150.00');
  });

  test('plasiyer_rota durak arası mesafe', () async {
    final rows = await OtherReportQueryService.fetchRows(
      db: db,
      reportId: 'plasiyer_rota',
      snapshot: const MbtReportParamSnapshot(),
    );
    expect(rows, hasLength(2));
    expect(rows.first['distance'], '');
    expect(rows.last['distance'], isNotEmpty);
  });
}
