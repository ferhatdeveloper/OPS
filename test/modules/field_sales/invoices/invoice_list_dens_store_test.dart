// Dosya Adı: invoice_list_dens_store_test.dart
// Açıklama: Fatura listesi dens — SQLite invoices sorgu testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_list_dens_store.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/mbt_sales_purchase_queue_body.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late InvoiceListDensStore store;

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
      },
    );
    store = InvoiceListDensStore(openDb: () async => db);

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta Tedarik',
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('InvoiceListDensStore', () {
    test('SQLite invoices satırlarını dens kaydına çevirir', () async {
      await db.insert('invoices', {
        'id': 'inv-sales-1',
        'customer_id': 'c1',
        'invoice_date': '2026-07-20T10:00:00.000',
        'total_amount': 1500.5,
        'status': 'Completed',
        'invoice_type': 'field_sales.wholesale_invoice',
        'is_synced': 0,
        'approval_status': 1,
      });
      await db.insert('invoices', {
        'id': 'inv-purchase-1',
        'customer_id': 'c2',
        'invoice_date': '2026-07-18T09:00:00.000',
        'total_amount': 800,
        'status': 'Completed',
        'invoice_type': 'field_sales.purchase_invoice',
        'is_synced': 1,
        'approval_status': 1,
      });

      final rows = await store.loadAll();

      expect(rows, hasLength(2));
      expect(rows.first.id, 'inv-sales-1');
      expect(rows.first.customerCode, 'C001');
      expect(rows.first.customerName, 'Alpha Market');
      expect(rows.first.docSide, MbtQueueDocSide.sales);
      expect(rows.first.totalAmount, 1500.5);

      final purchase = rows.firstWhere((r) => r.id == 'inv-purchase-1');
      expect(purchase.docSide, MbtQueueDocSide.purchase);
      expect(purchase.customerName, 'Beta Tedarik');
    });

    test('boş tabloda boş liste döner', () async {
      final rows = await store.loadAll();
      expect(rows, isEmpty);
    });
  });
}
