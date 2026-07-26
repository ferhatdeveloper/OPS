// Dosya Adı: invoice_pending_store_test.dart
// Açıklama: Bekleyen fatura dens SQLite store birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_pending_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_pending_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_pending_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('loadPending yalnızca onay/status bekleyenleri döner', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = InvoicePendingStore(openDb: () async => db);
    await store.ensureReady();

    final pending = InvoicePendingSeed.defaultRows.first;
    final approved = InvoicePendingRecord(
      id: 'inv_done_001',
      customerId: 'c_done',
      invoiceDate: DateTime(2026, 7, 20),
      totalAmount: 50,
      status: 'Completed',
      invoiceType: 'field_sales.wholesale_invoice',
      approvalStatus: 1,
      isSynced: 0,
    );

    await db.insert(InvoicePendingStore.tableName, pending.toMap());
    await db.insert(InvoicePendingStore.tableName, approved.toMap());

    final rows = await store.loadPending();
    expect(rows.length, 1);
    expect(rows.first.id, pending.id);
    expect(rows.first.approvalStatus, 0);
    expect(rows.any((r) => r.id == approved.id), isFalse);
  });

  test('loadPending boş tabloda boş liste', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = InvoicePendingStore(openDb: () async => db);
    final rows = await store.loadPending();
    expect(rows, isEmpty);
  });

  test('status=Pending approval=1 yine bekleyen sayılır', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = InvoicePendingStore(openDb: () async => db);
    await store.ensureReady();

    final row = InvoicePendingRecord(
      id: 'inv_status_pending',
      customerId: 'c2',
      invoiceDate: DateTime(2026, 7, 22),
      totalAmount: 12,
      status: 'Pending',
      approvalStatus: 1,
    );
    await db.insert(InvoicePendingStore.tableName, row.toMap());

    final loaded = await store.loadPending();
    expect(loaded.single.id, row.id);
  });
}
