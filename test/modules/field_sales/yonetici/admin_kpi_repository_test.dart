// Dosya Adı: admin_kpi_repository_test.dart
// Açıklama: Yönetici KPI SQLite COUNT aggregate birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/model/admin_kpi_summary.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/viewmodel/admin_kpi_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  const repo = AdminKpiRepository();
  final day = DateTime(2026, 7, 26);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createOrdersTable);
        await db.execute(SqlQuerys.createInvoicesTable);
        await db.execute(SqlQuerys.createCollectionsTable);
        await db.execute(SqlQuerys.createVisitsTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AdminKpiRepository.fetchToday', () {
    test('boş tabloda sıfır döner', () async {
      final summary = await repo.fetchToday(db, day: day);
      expect(summary, AdminKpiSummary.zero);
    });

    test('bugünkü kayıtları sayar; iptal ve diğer günü dışlar', () async {
      await db.insert('orders', {
        'id': 'o-today',
        'order_date': '2026-07-26T09:00:00.000',
        'total_amount': 100,
        'status': 'Pending',
      });
      await db.insert('orders', {
        'id': 'o-cancel',
        'order_date': '2026-07-26T10:00:00.000',
        'total_amount': 50,
        'status': 'Cancelled',
      });
      await db.insert('orders', {
        'id': 'o-other',
        'order_date': '2026-07-25T09:00:00.000',
        'total_amount': 200,
        'status': 'Approved',
      });

      await db.insert('invoices', {
        'id': 'i-today',
        'invoice_date': '2026-07-26T11:00:00.000',
        'total_amount': 300,
        'status': 'Completed',
      });
      await db.insert('invoices', {
        'id': 'i-cancel',
        'invoice_date': '2026-07-26T12:00:00.000',
        'total_amount': 10,
        'status': 'Cancelled',
      });

      await db.insert('collections', {
        'id': 'c-today',
        'collection_date': '2026-07-26T13:00:00.000',
        'amount': 80,
        'status': 'Completed',
      });
      await db.insert('collections', {
        'id': 'c-other',
        'collection_date': '2026-07-20T13:00:00.000',
        'amount': 40,
        'status': 'Completed',
      });

      await db.insert('visits', {
        'id': 'v-today',
        'check_in_at': '2026-07-26T08:00:00.000',
        'status': 'Completed',
      });
      await db.insert('visits', {
        'id': 'v-other',
        'check_in_at': '2026-07-01T08:00:00.000',
        'status': 'Open',
      });

      final summary = await repo.fetchToday(db, day: day);
      expect(
        summary,
        const AdminKpiSummary(
          orderCount: 1,
          invoiceCount: 1,
          collectionCount: 1,
          visitCount: 1,
        ),
      );
    });
  });
}
