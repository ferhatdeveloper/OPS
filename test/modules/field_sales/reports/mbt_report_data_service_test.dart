// Dosya Adı: mbt_report_data_service_test.dart
// Açıklama: MBT rapor SQLite satır servisi birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_action_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = MbtReportDataService();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MbtReportDataService boş şema', () {
    test('tablo yoksa boş satır döner', () async {
      final db = await openDatabase(inMemoryDatabasePath);
      addTearDown(() async => db.close());

      final rows = await service.fetchRows(
        reportId: 'cari_extre',
        snapshot: MbtReportParamSnapshot(
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31),
        ),
        db: db,
      );

      expect(rows, isEmpty);
    });
  });

  group('MbtReportDataService cari / borç', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createCustomersTable);
          await database.execute(SqlQuerys.createInvoicesTable);
          await database.execute(SqlQuerys.createCollectionsTable);
        },
      );

      await db.insert('customers', {
        'id': 'c1',
        'code': 'C001',
        'name': 'Alpha Market',
        'balance': 500.0,
      });

      await db.insert('invoices', {
        'id': 'inv-1',
        'customer_id': 'c1',
        'invoice_date': '2026-07-10T10:00:00.000',
        'total_amount': 1000.0,
        'status': 'Completed',
        'invoice_type': 'Sales',
      });

      await db.insert('collections', {
        'id': 'col-1',
        'customer_id': 'c1',
        'amount': 200.0,
        'payment_type': 'Cash',
        'collection_date': '2026-07-15T12:00:00.000',
        'status': 'Completed',
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('cari_extre fatura ve tahsilat satırları üretir', () async {
      final rows = await service.fetchRows(
        reportId: 'cari_extre',
        snapshot: MbtReportParamSnapshot(
          dateFrom: DateTime(2026, 7, 1),
          dateTo: DateTime(2026, 7, 31),
          code: 'C001',
        ),
        db: db,
      );

      expect(rows, hasLength(2));
      expect(rows.first.containsKey('debit'), isTrue);
      expect(rows.last['credit'], '200.00');
      expect(rows.last['balance'], '800.00');
    });

    test('borc_alacak cari bakiye listeler', () async {
      final rows = await service.fetchRows(
        reportId: 'borc_alacak',
        snapshot: const MbtReportParamSnapshot(code: 'C001'),
        db: db,
      );

      expect(rows, hasLength(1));
      expect(rows.first['code'], 'C001');
      expect(rows.first['balance'], '500.00');
    });
  });

  group('MbtReportDataService tahsilat', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createCustomersTable);
          await database.execute(SqlQuerys.createCollectionsTable);
        },
      );

      await db.insert('customers', {
        'id': 'c2',
        'code': 'C002',
        'name': 'Beta Bakkal',
      });

      await db.insert('collections', {
        'id': 'col-t',
        'customer_id': 'c2',
        'amount': 350.5,
        'payment_type': 'CreditCard',
        'collection_date': '2026-07-22T08:00:00.000',
        'due_date': '2026-08-01T00:00:00.000',
        'status': 'Completed',
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('tahsilat_listesi layout sütun id’lerini doldurur', () async {
      final rows = await service.fetchRows(
        reportId: 'tahsilat_listesi',
        snapshot: MbtReportParamSnapshot(
          dateFrom: DateTime(2026, 7, 20),
          dateTo: DateTime(2026, 7, 25),
        ),
        db: db,
      );

      expect(rows, hasLength(1));
      expect(rows.first['code'], 'C002');
      expect(rows.first['title'], 'Beta Bakkal');
      expect(rows.first['amount'], '350.50');
      expect(rows.first['txn_type'], 'CreditCard');
    });
  });
}
