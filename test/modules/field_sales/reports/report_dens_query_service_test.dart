// Dosya Adı: report_dens_query_service_test.dart
// Açıklama: Satış/tahsilat/ziyaret dens satırlarının SQLite tarih filtresi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_dens_query_service.dart';

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
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createCustomersTable);
        await db.execute(SqlQuerys.createInvoicesTable);
        await db.execute(SqlQuerys.createCollectionsTable);
        await db.execute(SqlQuerys.createVisitsTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta Bakkal',
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportDensQueryService satış', () {
    test('tarih aralığındaki faturaları satıra dönüştürür', () async {
      await db.insert('invoices', {
        'id': 'inv-in',
        'customer_id': 'c1',
        'invoice_date': '2026-07-20T10:00:00.000',
        'total_amount': 1500.5,
        'status': 'Completed',
        'invoice_type': 'Sales',
      });
      await db.insert('invoices', {
        'id': 'inv-out',
        'customer_id': 'c2',
        'invoice_date': '2026-06-01T10:00:00.000',
        'total_amount': 99,
        'status': 'Completed',
        'invoice_type': 'Sales',
      });

      final rows = await ReportDensQueryService.fetchRows(
        db: db,
        kind: ReportDensKind.sales,
        dateFrom: DateTime(2026, 7, 15),
        dateTo: DateTime(2026, 7, 25),
      );

      expect(rows, hasLength(1));
      expect(rows.first.title, 'Alpha Market');
      expect(rows.first.subtitle, contains('20.07.2026'));
      expect(rows.first.value, contains('1500.50'));
    });
  });

  group('ReportDensQueryService tahsilat', () {
    test('tarih aralığındaki tahsilatları satıra dönüştürür', () async {
      await db.insert('collections', {
        'id': 'col-1',
        'customer_id': 'c2',
        'amount': 250,
        'payment_type': 'Cash',
        'collection_date': '2026-07-22T12:00:00.000',
        'status': 'Completed',
      });

      final rows = await ReportDensQueryService.fetchRows(
        db: db,
        kind: ReportDensKind.collection,
        dateFrom: DateTime(2026, 7, 20),
        dateTo: DateTime(2026, 7, 26),
      );

      expect(rows, hasLength(1));
      expect(rows.first.title, 'Beta Bakkal');
      expect(rows.first.subtitle, contains('Cash'));
      expect(rows.first.value, contains('250.00'));
    });
  });

  group('ReportDensQueryService ziyaret', () {
    test('tarih aralığındaki ziyaretleri satıra dönüştürür', () async {
      await db.insert('visits', {
        'id': 'v1',
        'customer_id': 'c1',
        'check_in_at': '2026-07-21T09:00:00.000',
        'status': 'Completed',
        'duration_minutes': 35,
      });

      final rows = await ReportDensQueryService.fetchRows(
        db: db,
        kind: ReportDensKind.visit,
        dateFrom: DateTime(2026, 7, 20),
        dateTo: DateTime(2026, 7, 26),
      );

      expect(rows, hasLength(1));
      expect(rows.first.title, 'Alpha Market');
      expect(rows.first.subtitle, contains('Completed'));
      expect(rows.first.value, '35 dk');
    });

    test('aralık dışı ziyaretleri dışlar', () async {
      await db.insert('visits', {
        'id': 'v-old',
        'customer_id': 'c1',
        'check_in_at': '2026-01-01T09:00:00.000',
        'status': 'Completed',
        'duration_minutes': 10,
      });

      final rows = await ReportDensQueryService.fetchRows(
        db: db,
        kind: ReportDensKind.visit,
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 26),
      );

      expect(rows, isEmpty);
    });
  });
}
