// Dosya Adı: whms_load_order_consumer_test.dart
// Açıklama: WHMS Faz 2.3 yükleme emri consume testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
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
      'stock_quantity': 20.0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('WhmsLoadOrderConsumer', () {
    test('pending emir skip', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        order: WhmsLoadOrderDto(
          id: 'lo1',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 26),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 5,
            ),
          ],
          approval: WhmsApprovalStatus.pending,
        ),
      );
      expect(r.status, WhmsLoadOrderConsumeStatus.skipped);
      final p = await db.query('products', where: 'id = ?', whereArgs: ['prd-1']);
      expect((p.first['stock_quantity'] as num).toDouble(), 20);
    });

    test('approved emir araç stoğuna uygular', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        order: WhmsLoadOrderDto(
          id: 'lo2',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 26),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 5,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );
      expect(r.status, WhmsLoadOrderConsumeStatus.applied);
      final p = await db.query('products', where: 'id = ?', whereArgs: ['prd-1']);
      expect((p.first['stock_quantity'] as num).toDouble(), 15);
      final v = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: ['veh-1', 'prd-1'],
      );
      expect((v.first['quantity'] as num).toDouble(), 5);
    });

    test('MRK dışı from reddedilir', () async {
      expect(
        () => WhmsLoadOrderConsumer.consume(
          db: db,
          order: WhmsLoadOrderDto(
            id: 'lo3',
            fromWarehouseCode: 'IAD',
            toVehicleId: 'veh-1',
            date: DateTime(2026, 7, 26),
            lines: const [
              WhmsBridgeLine(
                productId: 'prd-1',
                productCode: 'SKU',
                quantity: 1,
              ),
            ],
            approval: WhmsApprovalStatus.approved,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
