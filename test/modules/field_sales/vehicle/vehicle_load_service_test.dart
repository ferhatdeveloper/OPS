// Dosya Adı: vehicle_load_service_test.dart
// Açıklama: Araç yükleme — merkez stock_quantity düşüm + vehicle_stocks artışı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/engine/vehicle_load_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VehicleLoadService.applyLoad', () {
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
            CREATE TABLE vehicle_stocks (
              vehicle_id TEXT,
              product_id TEXT,
              quantity REAL DEFAULT 0.0,
              updated_at TEXT,
              PRIMARY KEY (vehicle_id, product_id)
            )
          ''');
        },
      );

      await db.insert('products', {
        'id': 'prd-1',
        'code': 'P1',
        'name': 'Ürün 1',
        'stock_quantity': 100.0,
      });
      await db.insert('vehicle_stocks', {
        'vehicle_id': 'veh-1',
        'product_id': 'prd-1',
        'quantity': 10.0,
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('merkez stock_quantity düşer, araç stoğu artar', () async {
      await VehicleLoadService.applyLoad(
        db: db,
        vehicleId: 'veh-1',
        items: const [
          {'productId': 'prd-1', 'quantity': 15.0},
        ],
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
      expect((vehicle.first['quantity'] as num).toDouble(), 25.0);
    });

    test('yeni ürün satırı vehicle_stocks ekler', () async {
      await db.insert('products', {
        'id': 'prd-2',
        'code': 'P2',
        'name': 'Ürün 2',
        'stock_quantity': 50.0,
      });

      await VehicleLoadService.applyLoad(
        db: db,
        vehicleId: 'veh-1',
        items: const [
          {'productId': 'prd-2', 'quantity': 8.0},
        ],
      );

      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-2'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 42.0);

      final vehicle = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: ['veh-1', 'prd-2'],
      );
      expect(vehicle, hasLength(1));
      expect((vehicle.first['quantity'] as num).toDouble(), 8.0);
    });

    test('yetersiz merkez stoğunda StateError fırlatır', () async {
      expect(
        () => VehicleLoadService.applyLoad(
          db: db,
          vehicleId: 'veh-1',
          items: const [
            {'productId': 'prd-1', 'quantity': 999.0},
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('sıfır/negatif miktar satırlarını atlar', () async {
      await VehicleLoadService.applyLoad(
        db: db,
        vehicleId: 'veh-1',
        items: const [
          {'productId': 'prd-1', 'quantity': 0.0},
          {'productId': 'prd-1', 'quantity': -5.0},
        ],
      );

      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((product.first['stock_quantity'] as num).toDouble(), 100.0);
    });
  });
}
