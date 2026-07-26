// Dosya Adı: invoice_untransferred_store_test.dart
// Açıklama: Transfer edilmeyen fatura store — SQLite + queue birim test
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_untransferred_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_untransferred_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late InvoiceUntransferredStore store;

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
        await database.execute(SqlQuerys.createInvoicesTable);
        await database.execute(SqlQuerys.createSyncQueueTable);
      },
    );
    store = InvoiceUntransferredStore(openDb: () async => db);
    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('is_synced=0 yükler, synced elenir', () async {
    await db.insert('invoices', {
      'id': 'inv-u',
      'customer_id': 'c1',
      'invoice_date': '2026-07-26T10:00:00.000',
      'total_amount': 100,
      'status': 'Completed',
      'invoice_type': 'field_sales.wholesale_invoice_8',
      'is_synced': 0,
      'approval_status': 1,
    });
    await db.insert('invoices', {
      'id': 'inv-s',
      'customer_id': 'c1',
      'invoice_date': '2026-07-25T10:00:00.000',
      'total_amount': 50,
      'status': 'Completed',
      'invoice_type': 'field_sales.wholesale_invoice_8',
      'is_synced': 1,
      'approval_status': 1,
    });

    final rows = await store.loadUnsynced();
    expect(rows.map((e) => e.id), ['inv-u']);
    expect(rows.first.customerCode, 'C001');
    expect(rows.first.docSide, InvoiceUntransferredDocSide.sales);
  });

  test('sync_queue invoice satırını birleştirir', () async {
    await db.insert('sync_queue', {
      'id': 'job-1',
      'entity_type': 'invoice',
      'entity_id': 'inv-q',
      'payload':
          '{"id":"inv-q","invoice_type":"field_sales.purchase_invoice",'
          '"customer_code":"S1","total_amount":9,'
          '"invoice_date":"2026-07-26T08:00:00.000"}',
      'priority': 1,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    final rows = await store.loadUnsynced();
    expect(rows, hasLength(1));
    expect(rows.first.id, 'inv-q');
    expect(rows.first.docSide, InvoiceUntransferredDocSide.purchase);
    expect(rows.first.queueJobId, 'job-1');
  });

  test('boş DB → boş liste', () async {
    final rows = await store.loadUnsynced();
    expect(rows, isEmpty);
  });
}
