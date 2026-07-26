// Dosya Adı: sales_target_store_test.dart
// Açıklama: Satış hedefleri SQLite store + seed birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/targets/model/sales_target_record.dart';
import 'package:exfin_ops/modules/field_sales/targets/model/sales_target_seed.dart';
import 'package:exfin_ops/modules/field_sales/targets/viewmodel/sales_target_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('seedIfEmpty boş tabloda dens satır ekler', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = SalesTargetStore(openDb: () async => db);
    await store.ensureReady();

    final rows = await store.loadAll();
    expect(rows.length, SalesTargetSeed.defaultRows.length);
    expect(rows.any((r) => r.type == 'Sales'), isTrue);
    expect(rows.any((r) => r.type == 'Collection'), isTrue);
    expect(rows.any((r) => r.type == 'Visit'), isTrue);
    expect(
      rows.firstWhere((r) => r.id == 'st_seed_sales_mehmet').achievementPercent,
      greaterThanOrEqualTo(100),
    );
  });

  test('seedIfEmpty dolu tabloda tekrar eklemez', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = SalesTargetStore(openDb: () async => db);
    await store.ensureReady();
    await store.ensureReady();

    final rows = await store.loadAll();
    expect(rows.length, SalesTargetSeed.defaultRows.length);
  });

  test('loadByType Sales filtresi', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = SalesTargetStore(openDb: () async => db);
    final sales = await store.loadByType('Sales');
    expect(sales, isNotEmpty);
    expect(sales.every((r) => r.type == 'Sales'), isTrue);
    expect(sales.length, SalesTargetSeed.salesRows.length);
  });

  test('fromMap round-trip insert sonrası korunur', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = SalesTargetStore(openDb: () async => db);
    await store.ensureReady();

    final row = const SalesTargetRecord(
      id: 'st_round',
      userId: 'Test Plasiyer',
      targetAmount: 42.5,
      achievedAmount: 10,
      period: '2026-Q3',
      type: 'Sales',
    );
    await db.insert(SalesTargetStore.tableName, row.toMap());

    final loaded = await store.loadAll();
    final found = loaded.firstWhere((r) => r.id == row.id);
    expect(found.userId, row.userId);
    expect(found.targetAmount, 42.5);
    expect(found.achievedAmount, 10);
    expect(found.period, '2026-Q3');
  });
}
