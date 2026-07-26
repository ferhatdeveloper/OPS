// Dosya Adı: local_warehouse_stock_balance_port_test.dart
// Açıklama: WHMS Faz 1 yerel StockBalancePort birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
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
      'stock_quantity': 40.0,
    });
    await db.insert(WarehouseStocksTable.name, {
      'warehouse_code': 'MRK',
      'product_id': 'prd-1',
      'quantity': 25.0,
      'is_synced': 0,
    });
    await db.insert('vehicles', {'id': 'veh-1', 'is_active': 1});
    await db.insert('vehicle_stocks', {
      'vehicle_id': 'veh-1',
      'product_id': 'prd-1',
      'quantity': 8.0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalWarehouseStockBalancePort', () {
    test('MRK warehouse_stocks bakiyesini okur', () async {
      final port = LocalWarehouseStockBalancePort(db);
      final bal = await port.getBalance(
        productId: 'prd-1',
        warehouseCode: 'MRK',
      );
      expect(bal.quantity, 25.0);
      expect(bal.bucket, StockBalanceBucket.warehouse);
      expect(bal.source, 'local');
    });

    test('ARC vehicle_stocks bakiyesini okur', () async {
      final port = LocalWarehouseStockBalancePort(db);
      final bal = await port.getBalance(
        productId: 'prd-1',
        warehouseCode: 'ARC',
        vehicleId: 'veh-1',
      );
      expect(bal.quantity, 8.0);
      expect(bal.bucket, StockBalanceBucket.van);
      expect(bal.vehicleId, 'veh-1');
    });

    test('IAD satırı yoksa 0 döner', () async {
      final port = LocalWarehouseStockBalancePort(db);
      final bal = await port.getBalance(
        productId: 'prd-1',
        warehouseCode: 'IAD',
      );
      expect(bal.quantity, 0.0);
      expect(bal.bucket, StockBalanceBucket.warehouse);
    });
  });
}
