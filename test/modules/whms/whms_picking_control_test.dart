// Dosya Adı: whms_picking_control_test.dart
// Açıklama: Sevkiyat son kontrol (picking control) unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/whms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WhmsPickingControlEngine', () {
    test('eşleşme → allow', () {
      final r = WhmsPickingControlEngine.compare(
        planned: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 10,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 10,
          ),
        ],
      );
      expect(r.isAllowed, isTrue);
      expect(r.messageKey, WhmsPickingMessageKeys.allow);
    });

    test('eksik → block (standard)', () {
      final r = WhmsPickingControlEngine.compare(
        planned: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 10,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 7,
          ),
        ],
      );
      expect(r.isBlocked, isTrue);
      expect(r.messageKey, WhmsPickingMessageKeys.blockShort);
      expect(r.mismatches.single.kind, WhmsPickingVarianceKind.short);
    });

    test('fazla → warn (standard)', () {
      final r = WhmsPickingControlEngine.compare(
        planned: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 5,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 8,
          ),
        ],
      );
      expect(r.isWarned, isTrue);
      expect(r.messageKey, WhmsPickingMessageKeys.warnOver);
    });

    test('yanlış ürün → block', () {
      final r = WhmsPickingControlEngine.compare(
        planned: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 5,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 5,
          ),
          WhmsBridgeLine(
            productId: 'p2',
            productCode: 'SKU2',
            quantity: 1,
          ),
        ],
      );
      expect(r.isBlocked, isTrue);
      expect(r.messageKey, WhmsPickingMessageKeys.blockWrong);
    });

    test('warnAll politikası → eksik warn', () {
      final r = WhmsPickingControlEngine.compare(
        planned: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'A',
            quantity: 3,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'A',
            quantity: 1,
          ),
        ],
        policy: WhmsPickingControlPolicy.warnAll,
      );
      expect(r.isWarned, isTrue);
      expect(r.messageKey, WhmsPickingMessageKeys.warnShort);
    });

    test('order lines quantity vs quantityDone', () {
      final r = WhmsPickingControlEngine.compareOrderLines(
        lines: const [
          WhmsOrderLineDto(
            id: 'l1',
            orderId: 'o1',
            lineNo: 1,
            productId: 'p1',
            productCode: 'SKU',
            quantity: 4,
            quantityDone: 4,
          ),
        ],
      );
      expect(r.isAllowed, isTrue);
    });
  });

  group('WhmsPickingControlGate', () {
    test('block → StateError messageKey', () {
      expect(
        () => WhmsPickingControlGate.assertAllowed(
          planned: const [
            WhmsBridgeLine(
              productId: 'p1',
              productCode: 'A',
              quantity: 2,
            ),
          ],
          actual: const [],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            WhmsPickingMessageKeys.blockShort,
          ),
        ),
      );
    });

    test('warn + onay yok → StateError', () {
      expect(
        () => WhmsPickingControlGate.assertAllowed(
          planned: const [
            WhmsBridgeLine(
              productId: 'p1',
              productCode: 'A',
              quantity: 2,
            ),
          ],
          actual: const [
            WhmsBridgeLine(
              productId: 'p1',
              productCode: 'A',
              quantity: 5,
            ),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            WhmsPickingMessageKeys.warnOver,
          ),
        ),
      );
    });

    test('warn + acknowledge → geçer', () {
      final r = WhmsPickingControlGate.assertAllowed(
        planned: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'A',
            quantity: 2,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'A',
            quantity: 5,
          ),
        ],
        acknowledgeWarnings: true,
      );
      expect(r.isWarned, isTrue);
    });
  });

  group('WhmsLoadOrderConsumer + picking', () {
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

    test('picking kapısı kapalı → eski davranış', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        order: WhmsLoadOrderDto(
          id: 'lo-pick-off',
          fromWarehouseCode: 'MRK',
          toVehicleId: 'veh-1',
          date: DateTime(2026, 7, 28),
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 3,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );
      expect(r.status, WhmsLoadOrderConsumeStatus.applied);
    });

    test('eksik fiili → consume engellenir', () async {
      expect(
        () => WhmsLoadOrderConsumer.consume(
          db: db,
          enforcePickingControl: true,
          pickedLines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU',
              quantity: 1,
            ),
          ],
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
            WhmsPickingMessageKeys.blockShort,
          ),
        ),
      );
    });

    test('eşleşen fiili → applyLoad fiili miktar', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        enforcePickingControl: true,
        pickedLines: const [
          WhmsBridgeLine(
            productId: 'prd-1',
            productCode: 'SKU',
            quantity: 4,
          ),
        ],
        order: WhmsLoadOrderDto(
          id: 'lo-ok-pick',
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

    test('fazla + onay → fiili uygulanır', () async {
      final r = await WhmsLoadOrderConsumer.consume(
        db: db,
        enforcePickingControl: true,
        acknowledgePickingWarnings: true,
        pickedLines: const [
          WhmsBridgeLine(
            productId: 'prd-1',
            productCode: 'SKU',
            quantity: 6,
          ),
        ],
        order: WhmsLoadOrderDto(
          id: 'lo-over',
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
      expect((p.first['stock_quantity'] as num).toDouble(), 14);
    });
  });
}
