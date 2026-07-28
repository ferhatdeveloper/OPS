// Dosya Adı: bank_card_store_test.dart
// Açıklama: bank_cards dens CRUD birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/bank_card_store.dart';

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
        await db.execute(SqlQuerys.createBankCardsTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('seed + create + update + softDelete', () async {
    final store = BankCardStore(openDb: () async => db);
    await store.ensureReady();
    final seeded = await store.listActive();
    expect(seeded, isNotEmpty);

    final created = await store.create(code: '102 99 01', name: 'TEST BANK');
    expect(created.code, '102 99 01');

    await store.update(
      BankCardRecord(
        id: created.id,
        code: created.code,
        name: 'TEST BANK 2',
        nameKey: '',
        createdAt: created.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
    final found = await store.findByCode('102 99 01');
    expect(found?.name, 'TEST BANK 2');

    await store.softDelete(created.id);
    final after = await store.listActive();
    expect(after.any((r) => r.id == created.id), isFalse);
  });
}
