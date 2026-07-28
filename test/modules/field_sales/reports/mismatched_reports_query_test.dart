// Dosya Adı: mismatched_reports_query_test.dart
// Açıklama: 4 uyumsuz MBT rapor sorgu/layout adı uyumu testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_action_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_data_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/other/viewmodel/other_report_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('layout sütun id’leri adı yansıtır', () {
    test('yonetici_leaderboard rank/points', () {
      final cols = ReportLayoutDefaults.forReportId('yonetici_leaderboard')
          .visibleColumns
          .map((c) => c.id)
          .toList();
      expect(cols, containsAll(['rank', 'points', 'target', 'achieved']));
      expect(cols, isNot(contains('date')));
    });

    test('yonetici_period_compare previous/current/growth', () {
      final cols = ReportLayoutDefaults.forReportId('yonetici_period_compare')
          .visibleColumns
          .map((c) => c.id)
          .toList();
      expect(cols, ['code', 'title', 'period', 'previous', 'current', 'growth']);
    });

    test('ops_target target/achieved/percent', () {
      final cols = ReportLayoutDefaults.forReportId('ops_target')
          .visibleColumns
          .map((c) => c.id)
          .toList();
      expect(cols, containsAll(['target', 'achieved', 'percent', 'period']));
    });

    test('plasiyer_rota visit_order/weekday (visits değil)', () {
      final cols = ReportLayoutDefaults.forReportId('plasiyer_rota')
          .visibleColumns
          .map((c) => c.id)
          .toList();
      expect(cols.first, 'visit_order');
      expect(cols, contains('weekday'));
      expect(cols, isNot(contains('visit_time')));
      expect(cols, isNot(contains('amount')));
    });
  });

  group('OtherReportQueryService leaderboard / period / rota', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createCustomersTable);
          await database.execute(SqlQuerys.createInvoicesTable);
          await database.execute(SqlQuerys.createCollectionsTable);
          await database.execute(SqlQuerys.createVisitsTable);
          await database.execute(SqlQuerys.createTargetsTable);
          await database.execute(SqlQuerys.createPlasiyerProfileTable);
          await database.execute(SqlQuerys.createRoutesTable);
          await database.execute(SqlQuerys.createRouteCustomersTable);
        },
      );

      await db.insert('plasiyer_profile', {
        'id': 'p1',
        'name': 'Ahmet Yılmaz',
        'total_points': 1200,
        'level': 2,
      });
      await db.insert('plasiyer_profile', {
        'id': 'p2',
        'name': 'Mehmet Kaya',
        'total_points': 2400,
        'level': 3,
      });

      await db.insert('customers', {
        'id': 'c1',
        'code': 'C001',
        'name': 'Alpha Market',
      });
      await db.insert('routes', {
        'id': 'r-mon',
        'name': 'Pazartesi',
        'salesperson_id': 'sp1',
        'day_of_week': 1,
        'is_active': 1,
      });
      await db.insert('route_customers', {
        'id': 'rc1',
        'route_id': 'r-mon',
        'customer_id': 'c1',
        'visit_order': 1,
        'is_mandatory': 1,
      });

      await db.insert('invoices', {
        'id': 'inv-a',
        'customer_id': 'c1',
        'invoice_date': '2026-07-10T10:00:00.000',
        'total_amount': 1000.0,
        'status': 'Completed',
        'invoice_type': 'Sales',
      });
      await db.insert('invoices', {
        'id': 'inv-b',
        'customer_id': 'c1',
        'invoice_date': '2026-06-10T10:00:00.000',
        'total_amount': 500.0,
        'status': 'Completed',
        'invoice_type': 'Sales',
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('yonetici_leaderboard puan sıralaması', () async {
      final rows = await OtherReportQueryService.fetchRows(
        db: db,
        reportId: 'yonetici_leaderboard',
        snapshot: const MbtReportParamSnapshot(),
      );
      expect(rows, hasLength(2));
      expect(rows.first['rank'], '1');
      expect(rows.first['title'], 'Mehmet Kaya');
      expect(rows.first['points'], '2400');
      expect(rows.last['rank'], '2');
    });

    test('yonetici_period_compare previous/current satırları', () async {
      final rows = await OtherReportQueryService.fetchRows(
        db: db,
        reportId: 'yonetici_period_compare',
        snapshot: MbtReportParamSnapshot(
          dateFrom: DateTime(2026, 7, 1),
          dateTo: DateTime(2026, 7, 31),
        ),
      );
      expect(rows, hasLength(3));
      final sales = rows.firstWhere((r) => r['code'] == 'SATIS');
      expect(sales.containsKey('previous'), isTrue);
      expect(sales.containsKey('current'), isTrue);
      expect(sales.containsKey('growth'), isTrue);
      expect(sales['current'], '1000.00');
      expect(sales['previous'], '500.00');
    });

    test('plasiyer_rota rota durakları döner', () async {
      final rows = await OtherReportQueryService.fetchRows(
        db: db,
        reportId: 'plasiyer_rota',
        snapshot: const MbtReportParamSnapshot(),
      );
      expect(rows, hasLength(1));
      expect(rows.first['visit_order'], '1');
      expect(rows.first['weekday'], '1');
      expect(rows.first['code'], 'C001');
      expect(rows.first['title'], 'Alpha Market');
      expect(rows.first.containsKey('visit_time'), isFalse);
    });
  });

  group('MbtReportDataService ops_target', () {
    test('targets satırlarını hedef kolonlarıyla döner', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createTargetsTable);
        },
      );
      addTearDown(() async => db.close());

      await db.insert('targets', {
        'id': 't1',
        'user_id': 'Ahmet Yılmaz',
        'target_amount': 100000,
        'achieved_amount': 75000,
        'period': '2026-07',
        'type': 'Sales',
      });

      const service = MbtReportDataService();
      final rows = await service.fetchRows(
        reportId: 'ops_target',
        snapshot: const MbtReportParamSnapshot(),
        db: db,
      );

      expect(rows, hasLength(1));
      expect(rows.first['title'], 'Ahmet Yılmaz');
      expect(rows.first['target'], '100000.00');
      expect(rows.first['achieved'], '75000.00');
      expect(rows.first['percent'], '75.00');
      expect(rows.first['period'], '2026-07');
    });
  });
}
