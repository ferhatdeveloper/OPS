// Dosya Adı: whms_load_fifo_gate_test.dart
// Açıklama: Load FIFO allocate kapısı testleri (P0 E)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

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

  group('WhmsLoadFifoGate + consume', () {
    test('kural yoksa consume eskisi gibi geçer', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        order: WhmsLoadOrderDto(
          id: 'lo-nofifo',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 28),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 2,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );
      expect(r.status, WhmsLoadOrderConsumeStatus.applied);
    });

    test('allocate shortfall → StateError messageKey', () async {
      expect(
        () => WhmsLoadOrderConsumer.consume(
          db: db,
          today: DateTime(2026, 7, 28),
          rulesByProductCode: const {
            'SKU': WhmsFifoRule(
              productCode: 'SKU',
              fifoDays: 0,
              fefoEnforce: true,
            ),
          },
          batchesByProductCode: {
            'SKU': [
              WhmsFifoBatch(
                lot: 'L1',
                expiry: DateTime(2026, 9, 1),
                qty: 1,
              ),
            ],
          },
          order: WhmsLoadOrderDto(
            id: 'lo-short',
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
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            WhmsFifoMessageKeys.insufficient,
          ),
        ),
      );
    });

    test('allocate yeterli → applyLoad', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        today: DateTime(2026, 7, 28),
        rulesByProductCode: const {
          'SKU': WhmsFifoRule(
            productCode: 'SKU',
            fifoDays: 0,
            fefoEnforce: true,
          ),
        },
        batchesByProductCode: {
          'SKU': [
            WhmsFifoBatch(
              lot: 'L1',
              expiry: DateTime(2026, 8, 15),
              qty: 10,
            ),
          ],
        },
        order: WhmsLoadOrderDto(
          id: 'lo-ok',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 28),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 4,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );
      expect(r.status, WhmsLoadOrderConsumeStatus.applied);
      final p = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-1'],
      );
      expect((p.first['stock_quantity'] as num).toDouble(), 16);
    });
  });

  group('WhmsFifoRuleEngine.allocate', () {
    test('pickFefoBatches ile aynı plan', () {
      const rule = WhmsFifoRule(
        productCode: 'SKU',
        fifoDays: 0,
        fefoEnforce: true,
      );
      final batches = [
        WhmsFifoBatch(
          lot: 'B',
          expiry: DateTime(2026, 10, 1),
          qty: 3,
        ),
        WhmsFifoBatch(
          lot: 'A',
          expiry: DateTime(2026, 8, 1),
          qty: 2,
        ),
      ];
      final a = WhmsFifoRuleEngine.allocate(
        qty: 3,
        today: DateTime(2026, 7, 28),
        rule: rule,
        availableBatches: batches,
      );
      final b = WhmsFifoRuleEngine.pickFefoBatches(
        qty: 3,
        today: DateTime(2026, 7, 28),
        rule: rule,
        availableBatches: batches,
      );
      expect(a.fulfilledQty, b.fulfilledQty);
      expect(a.slices.first.batch.lot, 'A');
    });
  });
}
