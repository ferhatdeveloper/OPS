// Dosya Adı: einvoice_status_store_test.dart
// Açıklama: e-Fatura durum SQLite store birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_gib_status.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_status_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_status_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/einvoice_status_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('loadAll soft-delete hariç SQLite satırlarını döner', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = EinvoiceStatusStore(openDb: () async => db);
    await store.ensureReady();

    final live = EinvoiceStatusSeed.defaultRows.first;
    final deleted = live.copyWith(
      id: 'eis_deleted',
      documentNo: 'EF-DEL',
      isDeleted: 1,
    );

    await db.insert(EinvoiceStatusStore.tableName, live.toMap());
    await db.insert(EinvoiceStatusStore.tableName, deleted.toMap());

    final rows = await store.loadAll();
    expect(rows.length, 1);
    expect(rows.first.id, live.id);
    expect(rows.first.ettn, live.ettn);
    expect(rows.first.gibStatus, EinvoiceGibStatus.sent);
    expect(rows.any((r) => r.id == deleted.id), isFalse);
  });

  test('loadAll boş tabloda boş liste', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = EinvoiceStatusStore(openDb: () async => db);
    final rows = await store.loadAll();
    expect(rows, isEmpty);
  });

  test('fromMap round-trip store insert sonrası korunur', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = EinvoiceStatusStore(openDb: () async => db);
    await store.ensureReady();

    final row = EinvoiceStatusRecord(
      id: 'eis_round',
      documentNo: 'EF-R1',
      ettn: '11111111-2222-3333-4444-555555555555',
      gibStatus: EinvoiceGibStatus.accepted,
      docSide: EinvoiceDocSide.purchase,
      amount: 42.5,
    );
    await db.insert(EinvoiceStatusStore.tableName, row.toMap());

    final loaded = await store.loadAll();
    expect(loaded.single.ettn, row.ettn);
    expect(loaded.single.gibStatus, EinvoiceGibStatus.accepted);
    expect(loaded.single.docSide, EinvoiceDocSide.purchase);
    expect(loaded.single.amount, 42.5);
  });
}
