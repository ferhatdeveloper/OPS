// Dosya Adı: whms_load_order_bridge_test.dart
// Açıklama: Load emri store mirror + consumeFromStore testleri (P0 E)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/whms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late WhmsOrderStore store;

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
    store = WhmsOrderStore(openDb: () async => db);
    await store.ensureReady();
  });

  tearDown(() async {
    await db.close();
  });

  group('WhmsLoadOrderBridge', () {
    test('mirrorApproved pending → null', () async {
      final r = await WhmsLoadOrderBridge.mirrorApproved(
        dto: WhmsLoadOrderDto(
          id: 'lo-p',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 28),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 1,
            ),
          ],
          approval: WhmsApprovalStatus.pending,
        ),
        store: store,
      );
      expect(r, isNull);
    });

    test('mirror + consumeFromStore araç stoğuna yazar', () async {
      final mirrored = await WhmsLoadOrderBridge.mirrorApproved(
        dto: WhmsLoadOrderDto(
          id: 'lo-ok',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 28),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 5,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
        store: store,
        status: WhmsOrderStatus.assigned,
      );
      expect(mirrored?.orderType, WhmsOrderType.load);

      final outcome = await WhmsLoadOrderBridge.consumeFromStore(
        db: db,
        orderId: 'lo-ok',
        store: store,
      );
      expect(outcome.status, WhmsLoadOrderConsumeStatus.applied);

      final p = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((p.first['stock_quantity'] as num).toDouble(), 15);

      final after = await store.getById('lo-ok');
      expect(after?.status, WhmsOrderStatus.done);
    });
  });
}
