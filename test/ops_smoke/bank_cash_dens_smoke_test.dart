// Dosya Adı: bank_cash_dens_smoke_test.dart
// Açıklama: OPS smoke — banka/kasa dens store CRUD (in-memory SQLite)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/bank_card_store.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/cash_movement_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('BankCardStore seed listActive smoke', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, _) async => d.execute(SqlQuerys.createBankCardsTable),
    );
    addTearDown(db.close);
    final store = BankCardStore(openDb: () async => db);
    await store.ensureReady();
    expect(await store.listActive(), isNotEmpty);
  });

  test('CashMovementStore listForCard smoke', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, _) async {
        await d.execute(SqlQuerys.createCollectionsTable);
      },
    );
    addTearDown(db.close);
    final store = CashMovementStore(openDb: () async => db);
    final rows = await store.listByCashCode('100 01 01');
    expect(rows, isEmpty);
  });
}
