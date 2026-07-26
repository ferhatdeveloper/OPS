// Dosya Adı: product_catalog_store_test.dart
// Açıklama: Ürün katalog dens SQLite store birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_row.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_seed.dart';
import 'package:exfin_ops/modules/field_sales/products/viewmodel/product_catalog_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('boş tablo loadAll seed satırlarını döner', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = ProductCatalogStore(openDb: () async => db);
    final rows = await store.loadAll();

    expect(rows.length, ProductCatalogSeed.defaultRows.length);
    expect(rows.any((r) => r.code == 'STK-001'), isTrue);
    expect(rows.any((r) => r.code == 'HIZ-001'), isTrue);
  });

  test('mevcut ürünler seed ile ezilmez', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = ProductCatalogStore(openDb: () async => db);
    await store.ensureReady();

    await db.delete(ProductCatalogStore.tableName);
    await db.insert(
      ProductCatalogStore.tableName,
      const ProductCatalogRow(
        id: 'live-1',
        code: 'LIVE-01',
        name: 'Canlı Ürün',
        price: 10,
      ).toMap(),
    );

    final rows = await store.loadAll();
    expect(rows, hasLength(1));
    expect(rows.single.code, 'LIVE-01');
  });

  test('search kod/ad/barkod filtreler', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = ProductCatalogStore(openDb: () async => db);
    final byCode = await store.loadAll(search: 'HIZ');
    expect(byCode.every((r) => r.code.contains('HIZ')), isTrue);
    expect(byCode, isNotEmpty);

    final byName = await store.loadAll(search: 'içecek');
    expect(byName.any((r) => r.code == 'STK-003'), isTrue);

    final miss = await store.loadAll(search: 'XXXX-YOK');
    expect(miss, isEmpty);
  });
}
