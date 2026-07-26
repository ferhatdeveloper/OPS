// Dosya Adı: logo_stock_balance_port_test.dart
// Açıklama: WHMS Faz 2.1 Logo StockBalancePort birim testleri
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
  late LocalWarehouseStockBalancePort local;

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
    await db.insert(WarehouseStocksTable.name, {
      'warehouse_code': 'MRK',
      'product_id': 'SKU-1',
      'quantity': 5.0,
      'is_synced': 0,
    });
    await db.insert('vehicles', {'id': 'veh-1', 'is_active': 1});
    await db.insert('vehicle_stocks', {
      'vehicle_id': 'veh-1',
      'product_id': 'SKU-1',
      'quantity': 3.0,
    });
    local = LocalWarehouseStockBalancePort(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LogoStockRowParser', () {
    test('QUANTITY ve WAREHOUSE normalize eder', () {
      expect(
        LogoStockRowParser.quantity({'QUANTITY': 12.5}),
        12.5,
      );
      expect(
        LogoStockRowParser.warehouseCode({'WAREHOUSE': 'mrk'}),
        'MRK',
      );
      expect(LogoStockRowParser.itemCode({'CODE': 'A1'}), 'A1');
    });
  });

  group('LogoStockBalancePort', () {
    test('MRK bakiyesini Logo satırından okur', () async {
      final port = LogoStockBalancePort(
        fallback: local,
        fetchStock: (_) async => [
          {
            'CODE': 'SKU-1',
            'WAREHOUSE_CODE': 'MRK',
            'QUANTITY': 42,
          },
        ],
        fetchInventory: () async => const [],
      );
      final bal = await port.getBalance(
        productId: 'SKU-1',
        warehouseCode: 'MRK',
      );
      expect(bal.quantity, 42);
      expect(bal.source, 'logo');
      expect(bal.bucket, StockBalanceBucket.warehouse);
    });

    test('IAD satırını filtreler; diğer ambarı saymaz', () async {
      final port = LogoStockBalancePort(
        fallback: local,
        fetchStock: (_) async => [
          {'CODE': 'SKU-1', 'warehouse_code': 'MRK', 'quantity': 10},
          {'CODE': 'SKU-1', 'warehouse_code': 'IAD', 'quantity': 7},
        ],
        fetchInventory: () async => const [],
      );
      final bal = await port.getBalance(
        productId: 'SKU-1',
        warehouseCode: 'IAD',
      );
      expect(bal.quantity, 7);
      expect(bal.source, 'logo');
    });

    test('ARC her zaman yerel van bakiyesine düşer', () async {
      var logoCalled = false;
      final port = LogoStockBalancePort(
        fallback: local,
        fetchStock: (_) async {
          logoCalled = true;
          return [
            {'CODE': 'SKU-1', 'QUANTITY': 99},
          ];
        },
        fetchInventory: () async => const [],
      );
      final bal = await port.getBalance(
        productId: 'SKU-1',
        warehouseCode: 'ARC',
        vehicleId: 'veh-1',
      );
      expect(logoCalled, isFalse);
      expect(bal.quantity, 3);
      expect(bal.source, 'local');
      expect(bal.bucket, StockBalanceBucket.van);
    });

    test('Logo hata verince yerel fallback', () async {
      final port = LogoStockBalancePort(
        fallback: local,
        fetchStock: (_) async => throw Exception('network'),
        fetchInventory: () async => const [],
      );
      final bal = await port.getBalance(
        productId: 'SKU-1',
        warehouseCode: 'MRK',
      );
      expect(bal.quantity, 5);
      expect(bal.source, 'local');
    });

    test('listByWarehouse Logo envanterini gruplar', () async {
      final port = LogoStockBalancePort(
        fallback: local,
        fetchStock: (_) async => const [],
        fetchInventory: () async => [
          {'CODE': 'A', 'warehouse_code': 'MRK', 'quantity': 1},
          {'CODE': 'A', 'warehouse_code': 'MRK', 'quantity': 2},
          {'CODE': 'B', 'warehouse_code': 'IAD', 'quantity': 9},
        ],
      );
      final list = await port.listByWarehouse(warehouseCode: 'MRK');
      expect(list.length, 1);
      expect(list.first.productId, 'A');
      expect(list.first.quantity, 3);
      expect(list.first.source, 'logo');
    });
  });
}
