// Dosya Adı: whms_order_bridges_test.dart
// Açıklama: Transfer/load emir köprü birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/bridge/whms_load_order_bridge.dart';
import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/engine/whms_fifo_rule_engine.dart';
import 'package:exfin_ops/modules/whms/engine/whms_load_order_consumer.dart';
import 'package:exfin_ops/modules/whms/engine/whms_order_load_bridge.dart';
import 'package:exfin_ops/modules/whms/queue/whms_order_to_transfer_bridge.dart';
import 'package:exfin_ops/modules/whms/queue/whms_transfer_queue_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WhmsOrderToTransferBridge', () {
    test('pending skips queue', () async {
      var called = false;
      final bridge = WhmsOrderToTransferBridge(
        transferBridge: WhmsTransferQueueBridge(
          mirrorOrder: false,
          enqueueFn: ({
            required entityType,
            required entityId,
            required payload,
            priority = 1,
          }) async {
            called = true;
          },
        ),
      );
      final r = await bridge.enqueueFromParams(
        orderId: 't1',
        fromWh: 'MRK',
        toWh: 'IAD',
        date: DateTime(2026, 7, 28),
        lines: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU',
            quantity: 1,
          ),
        ],
        approval: WhmsApprovalStatus.pending,
      );
      expect(r.status, WhmsTransferEnqueueStatus.skipped);
      expect(called, isFalse);
    });

    test('approved enqueues', () async {
      String? queuedId;
      final bridge = WhmsOrderToTransferBridge(
        transferBridge: WhmsTransferQueueBridge(
          mirrorOrder: false,
          enqueueFn: ({
            required entityType,
            required entityId,
            required payload,
            priority = 1,
          }) async {
            queuedId = entityId;
          },
        ),
      );
      final r = await bridge.enqueueFromParams(
        orderId: 't2',
        fromWh: 'MRK',
        toWh: 'IAD',
        date: DateTime(2026, 7, 28),
        lines: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU',
            quantity: 2,
          ),
        ],
        approval: WhmsApprovalStatus.approved,
      );
      expect(r.status, WhmsTransferEnqueueStatus.enqueued);
      expect(queuedId, 't2');
    });
  });

  group('WhmsLoadOrderBridge.allocateFefo', () {
    test('shortfall marks blocked when fefoEnforce', () {
      final r = WhmsLoadOrderBridge.allocateFefo(
        lines: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 10,
          ),
        ],
        batchesByProduct: {
          'SKU1': [
            WhmsFifoBatch(
              lot: 'L1',
              expiry: DateTime(2026, 8, 1),
              qty: 4,
            ),
          ],
        },
        today: DateTime(2026, 7, 28),
      );
      expect(r, hasLength(1));
      expect(r.first.blocked, isTrue);
      expect(r.first.plan.shortfallQty, 6);
    });
  });

  group('WhmsOrderLoadBridge', () {
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

    test('pending skips consume', () async {
      final r = await WhmsOrderLoadBridge.consumeFromParams(
        db: db,
        orderId: 'lo1',
        fromWh: 'MRK',
        toVehicleId: 'veh-1',
        date: DateTime(2026, 7, 28),
        lines: const [
          WhmsBridgeLine(
            productId: 'prd-1',
            productCode: 'SKU',
            quantity: 3,
          ),
        ],
        approval: WhmsApprovalStatus.pending,
      );
      expect(r.status, WhmsLoadOrderConsumeStatus.skipped);
    });
  });
}
