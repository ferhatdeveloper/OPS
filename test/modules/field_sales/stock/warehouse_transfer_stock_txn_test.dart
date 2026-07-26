// Dosya Adı: warehouse_transfer_stock_txn_test.dart
// Açıklama: Ambar transferi yerel stok txn (WHMS prep R3 / B2-27) birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/stock/engine/warehouse_transfer_stock_txn.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_master_seed.dart';

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
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            code TEXT,
            name TEXT NOT NULL,
            stock_quantity REAL DEFAULT 0.0,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE vehicles (
            id TEXT PRIMARY KEY,
            plate TEXT NOT NULL,
            is_active INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE vehicle_stocks (
            vehicle_id TEXT,
            product_id TEXT,
            quantity REAL DEFAULT 0.0,
            updated_at TEXT,
            PRIMARY KEY (vehicle_id, product_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE warehouses (
            id TEXT PRIMARY KEY,
            code TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            is_active INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE warehouse_stocks (
            warehouse_code TEXT NOT NULL,
            product_id TEXT NOT NULL,
            quantity REAL NOT NULL DEFAULT 0,
            is_synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT,
            updated_at TEXT,
            PRIMARY KEY (warehouse_code, product_id)
          )
        ''');
      },
    );

    for (final map in WarehouseMasterSeed.defaultMaps) {
      await db.insert('warehouses', {
        'id': map['id'],
        'code': map['code'],
        'name': map['name'],
        'type': map['type'],
        'is_active': 1,
      });
    }

    await db.insert('products', {
      'id': 'prd-1',
      'code': 'P1',
      'name': 'Ürün 1',
      'stock_quantity': 100.0,
    });
    await db.insert('vehicles', {
      'id': 'veh-1',
      'plate': '34ABC123',
      'is_active': 1,
    });
    await db.insert('vehicle_stocks', {
      'vehicle_id': 'veh-1',
      'product_id': 'prd-1',
      'quantity': 20.0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('WarehouseTransferStockTxn.applyLine', () {
    test('merkez → araç: products düşer, vehicle_stocks artar', () async {
      await WarehouseTransferStockTxn.applyLine(
        db: db,
        fromWarehouse: 'MRK',
        toWarehouse: 'ARC',
        productId: 'prd-1',
        quantity: 15,
        vehicleId: 'veh-1',
      );

      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 85.0);

      final vehicle = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: ['veh-1', 'prd-1'],
      );
      expect((vehicle.first['quantity'] as num).toDouble(), 35.0);
    });

    test('araç → merkez: vehicle_stocks düşer, products artar', () async {
      await WarehouseTransferStockTxn.applyLine(
        db: db,
        fromWarehouse: 'Araç Depo',
        toWarehouse: 'Merkez Depo',
        productId: 'prd-1',
        quantity: 10,
        vehicleId: 'veh-1',
      );

      final vehicle = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: ['veh-1', 'prd-1'],
      );
      expect((vehicle.first['quantity'] as num).toDouble(), 10.0);

      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 110.0);
    });

    test('yetersiz merkez stoğunda StateError ve stok değişmez', () async {
      expect(
        () => WarehouseTransferStockTxn.applyLine(
          db: db,
          fromWarehouse: 'MRK',
          toWarehouse: 'ARC',
          productId: 'prd-1',
          quantity: 999,
          vehicleId: 'veh-1',
        ),
        throwsA(isA<StateError>()),
      );

      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 100.0);
    });

    test('bilinmeyen ambar StateError', () async {
      expect(
        () => WarehouseTransferStockTxn.applyLine(
          db: db,
          fromWarehouse: 'XYZ-UNKNOWN',
          toWarehouse: 'MRK',
          productId: 'prd-1',
          quantity: 1,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('aynı txn rollback: hata sonrası ürün stoğu eski kalır', () async {
      try {
        await db.transaction((txn) async {
          await WarehouseTransferStockTxn.applyLine(
            db: txn,
            fromWarehouse: 'MRK',
            toWarehouse: 'ARC',
            productId: 'prd-1',
            quantity: 5,
            vehicleId: 'veh-1',
          );
          throw StateError('forced');
        });
      } catch (_) {}

      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 100.0);

      final vehicle = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: ['veh-1', 'prd-1'],
      );
      expect((vehicle.first['quantity'] as num).toDouble(), 20.0);
    });

    test('araç satırı yoksa hedefe insert eder', () async {
      await db.insert('products', {
        'id': 'prd-2',
        'code': 'P2',
        'name': 'Ürün 2',
        'stock_quantity': 50.0,
      });

      await WarehouseTransferStockTxn.applyLine(
        db: db,
        fromWarehouse: 'MRK',
        toWarehouse: 'ARC',
        productId: 'prd-2',
        quantity: 7,
        vehicleId: 'veh-1',
      );

      final vehicle = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: ['veh-1', 'prd-2'],
      );
      expect(vehicle, hasLength(1));
      expect((vehicle.first['quantity'] as num).toDouble(), 7.0);
    });

    test('MRK → IAD warehouse_stocks taşır (R1)', () async {
      await WarehouseTransferStockTxn.applyLine(
        db: db,
        fromWarehouse: 'MRK',
        toWarehouse: 'IAD',
        productId: 'prd-1',
        quantity: 12,
      );

      final mrk = await db.query(
        'warehouse_stocks',
        where: 'warehouse_code = ? AND product_id = ?',
        whereArgs: ['MRK', 'prd-1'],
      );
      expect((mrk.first['quantity'] as num).toDouble(), 88.0);

      final iad = await db.query(
        'warehouse_stocks',
        where: 'warehouse_code = ? AND product_id = ?',
        whereArgs: ['IAD', 'prd-1'],
      );
      expect((iad.first['quantity'] as num).toDouble(), 12.0);

      // products aggregate değişmez (merkez↔merkez)
      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 100.0);
    });
  });
}
