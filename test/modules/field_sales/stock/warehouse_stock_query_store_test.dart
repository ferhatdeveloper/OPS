// Dosya Adı: warehouse_stock_query_store_test.dart
// Açıklama: Ambar stok sorgu store birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/warehouse_stock_query_store.dart';
import 'package:exfin_ops/modules/whms/whms.dart';

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
        await db.execute(SqlQuerys.createWarehouseStocksTable);
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            code TEXT,
            name TEXT,
            stock_quantity REAL DEFAULT 0.0
          )
        ''');
        await db.execute('''
          CREATE TABLE vehicles (
            id TEXT PRIMARY KEY,
            is_active INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE vehicle_stocks (
            vehicle_id TEXT,
            product_id TEXT,
            quantity REAL DEFAULT 0.0,
            PRIMARY KEY (vehicle_id, product_id)
          )
        ''');
      },
    );

    await db.insert('products', {
      'id': 'prd-1',
      'code': 'SKU-1',
      'name': 'Ürün Bir',
      'stock_quantity': 0,
    });
    await db.insert(WarehouseStocksTable.name, {
      'warehouse_code': 'MRK',
      'product_id': 'prd-1',
      'quantity': 12.0,
      'is_synced': 0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('MRK satırını ürün adı ile listeler', () async {
    final store = WarehouseStockQueryStore(dbOverride: db);
    final rows = await store.listForWarehouse('MRK');
    expect(rows.length, 1);
    expect(rows.first.productCode, 'SKU-1');
    expect(rows.first.productName, 'Ürün Bir');
    expect(rows.first.quantity, 12.0);
  });

  test('query ürün koduna göre süzülür', () async {
    final store = WarehouseStockQueryStore(dbOverride: db);
    final hit = await store.listForWarehouse('MRK', query: 'sku');
    expect(hit.length, 1);
    final miss = await store.listForWarehouse('MRK', query: 'yok');
    expect(miss, isEmpty);
  });
}
