// Dosya Adı: customer_movement_insert_test.dart
// Açıklama: Fatura/tahsilat → customer_movements insert birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('movementFromInvoice: satış borç, iade/alış alacak', () {
    final sales = CustomerExtractStore.movementFromInvoice(
      invoiceId: 'inv-1',
      customerId: 'C-100',
      invoiceDate: DateTime(2026, 7, 1),
      totalAmount: 1500,
      invoiceType: 'field_sales.van_sales',
    );
    expect(sales.id, 'inv-inv-1');
    expect(sales.debit, 1500);
    expect(sales.credit, 0);

    final ret = CustomerExtractStore.movementFromInvoice(
      invoiceId: 'inv-2',
      customerId: 'C-100',
      invoiceDate: DateTime(2026, 7, 2),
      totalAmount: 200,
      invoiceType: 'field_sales.return_invoice',
    );
    expect(ret.debit, 0);
    expect(ret.credit, 200);

    final purchase = CustomerExtractStore.movementFromInvoice(
      invoiceId: 'inv-3',
      customerId: 'C-100',
      invoiceDate: DateTime(2026, 7, 3),
      totalAmount: 300,
      invoiceType: 'field_sales.purchase_invoice',
    );
    expect(purchase.debit, 0);
    expect(purchase.credit, 300);
  });

  test('movementFromCollection: tahsilat alacak, ödeme borç, virman null', () {
    final cash = CustomerExtractStore.movementFromCollection(
      collectionId: 'col-1',
      customerId: 'C-100',
      collectionDate: DateTime(2026, 7, 10),
      amount: 500,
      paymentType: 'cash',
      documentNo: 'THS-1',
    );
    expect(cash, isNotNull);
    expect(cash!.credit, 500);
    expect(cash.debit, 0);
    expect(cash.documentNo, 'THS-1');

    final out = CustomerExtractStore.movementFromCollection(
      collectionId: 'col-2',
      customerId: 'C-100',
      collectionDate: DateTime(2026, 7, 11),
      amount: 100,
      paymentType: 'CashOut',
    );
    expect(out!.debit, 100);
    expect(out.credit, 0);

    final virman = CustomerExtractStore.movementFromCollection(
      collectionId: 'col-3',
      customerId: '',
      collectionDate: DateTime(2026, 7, 12),
      amount: 50,
      paymentType: 'virman',
    );
    expect(virman, isNull);
  });

  test('insert: fatura + tahsilat satırları customer_movements', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());
    await db.execute(SqlQuerys.createCustomerMovementsTable);

    final store = CustomerExtractStore(openDb: () async => db);
    await store.insert(
      CustomerExtractStore.movementFromInvoice(
        invoiceId: 'F-9',
        customerId: 'C-200',
        invoiceDate: DateTime(2026, 7, 15),
        totalAmount: 990,
        invoiceType: 'wholesale',
      ),
    );
    await store.insert(
      CustomerExtractStore.movementFromCollection(
        collectionId: 'T-9',
        customerId: 'C-200',
        collectionDate: DateTime(2026, 7, 16),
        amount: 90,
        paymentType: 'cash',
        documentNo: 'MK-9',
      )!,
    );

    final rows = await store.query(
      customerId: 'C-200',
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 31),
    );
    expect(rows.length, 2);
    expect(rows.first.debit, 990);
    expect(rows.last.credit, 90);
  });
}
