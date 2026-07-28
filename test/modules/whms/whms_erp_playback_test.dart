// Dosya Adı: whms_erp_playback_test.dart
// Açıklama: Logo/ERP simülasyonu — seed → mal kabul → transfer → sayım →
//   pick/seri → load FIFO+picking → KPI; her adımda ONAY + JobQueue assert
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/whms/whms.dart';

/// Sahte JobQueue satırı — ERP sync stub.
class _QueueRow {
  _QueueRow({
    required this.entityType,
    required this.entityId,
    required this.payload,
  });

  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late WhmsLocationStore locationStore;
  late WhmsOrderStore orderStore;
  late WhmsFifoRuleStore fifoStore;
  late WhmsCountOrderStore countOrderStore;
  late WhmsCountResultStore countResultStore;
  late WhmsCountSession countSession;
  late WhmsOrderKpiStore kpiStore;
  late WhmsOrderQueueBridge orderQueue;
  late WhmsTransferQueueBridge transferQueue;
  late List<_QueueRow> jobQueue;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    jobQueue = <_QueueRow>[];

    Future<void> enqueueFn({
      required String entityType,
      required String entityId,
      required Map<String, dynamic> payload,
      int priority = 1,
    }) async {
      jobQueue.add(
        _QueueRow(
          entityType: entityType,
          entityId: entityId,
          payload: Map<String, dynamic>.from(payload),
        ),
      );
    }

    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createWarehousesTable);
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            code TEXT,
            name TEXT,
            stock_quantity REAL DEFAULT 0.0,
            require_serial INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT
          )
        ''');
        await db.execute(SqlQuerys.createWarehouseStocksTable);
        await db.execute(SqlQuerys.createWhmsLocationsTable);
        await db.execute(SqlQuerys.createWhmsOrdersTable);
        await db.execute(SqlQuerys.createWhmsOrderLinesTable);
        await db.execute(SqlQuerys.createWhmsFifoRulesTable);
        await db.execute(SqlQuerys.createWhmsCountOrdersTable);
        await db.execute(SqlQuerys.createWhmsCountResultsTable);
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

    Future<Database> openDb() async => db;

    locationStore = WhmsLocationStore(openDb: openDb);
    orderStore = WhmsOrderStore(
      openDb: openDb,
      productSerialStore: WhmsProductSerialRuleStore(
        openDb: openDb,
        overrideRules: const {'prd-seri': true},
      ),
    );
    fifoStore = WhmsFifoRuleStore(openDb: openDb);
    countOrderStore = WhmsCountOrderStore(openDb: openDb);
    countResultStore = WhmsCountResultStore(openDb: openDb);
    countSession = WhmsCountSession(
      orderStore: countOrderStore,
      resultStore: countResultStore,
      openDb: openDb,
      bridge: WhmsCountQueueBridge(enqueueFn: enqueueFn),
    );
    kpiStore = WhmsOrderKpiStore(openDb: openDb);
    orderQueue = WhmsOrderQueueBridge(enqueueFn: enqueueFn);
    transferQueue = WhmsTransferQueueBridge(
      mirrorOrder: false,
      enqueueFn: enqueueFn,
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// JobQueue satırı: entity + ONAY=1.
  void expectQueueRow({
    required String entityType,
    required String entityId,
  }) {
    final hit = jobQueue.where(
      (r) => r.entityType == entityType && r.entityId == entityId,
    );
    expect(hit, isNotEmpty, reason: 'JobQueue $entityType/$entityId');
    expect(hit.first.payload['ONAY'], 1);
  }

  test('ERP playback: seed → mal kabul → transfer → sayım → '
      'pick/seri → load FIFO+picking → KPI', () async {
    // ─── 1) Seed: ambar + lokasyon + ürün/stok ───────────────────────────
    final now = DateTime.now().toIso8601String();
    await db.insert('warehouses', {
      'id': 'wh-mrk',
      'code': 'MRK',
      'name': 'Merkez',
      'type': 'main',
      'is_active': 1,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('warehouses', {
      'id': 'wh-iad',
      'code': 'IAD',
      'name': 'Iade',
      'type': 'return',
      'is_active': 1,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });

    await locationStore.upsert(
      const WhmsLocation(
        id: 'loc-a01',
        warehouseCode: 'MRK',
        code: 'A-01-01',
        aisle: 'A',
        rack: '01',
        bin: '01',
        barcode: 'LOC-A01',
        routeSeq: 10,
      ),
    );
    await locationStore.upsert(
      const WhmsLocation(
        id: 'loc-b01',
        warehouseCode: 'MRK',
        code: 'B-01-01',
        aisle: 'B',
        rack: '01',
        bin: '01',
        barcode: 'LOC-B01',
        routeSeq: 20,
      ),
    );

    await db.insert('products', {
      'id': 'prd-1',
      'code': 'SKU-1',
      'name': 'Ürün 1',
      'stock_quantity': 100.0,
      'require_serial': 0,
      'updated_at': now,
    });
    await db.insert('products', {
      'id': 'prd-seri',
      'code': 'SKU-SERI',
      'name': 'Seri Ürün',
      'stock_quantity': 50.0,
      'require_serial': 1,
      'updated_at': now,
    });
    await db.insert('warehouse_stocks', {
      'warehouse_code': 'MRK',
      'product_id': 'prd-1',
      'quantity': 100.0,
      'is_synced': 0,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('warehouse_stocks', {
      'warehouse_code': 'MRK',
      'product_id': 'prd-seri',
      'quantity': 50.0,
      'is_synced': 0,
      'created_at': now,
      'updated_at': now,
    });

    await fifoStore.upsert(
      const WhmsFifoRule(
        productCode: 'SKU-1',
        fifoDays: 0,
        fefoEnforce: true,
        warnDays: 7,
      ),
    );

    final locs = await locationStore.listActive(warehouseCode: 'MRK');
    expect(locs, hasLength(2));
    final stockRows = await db.query('warehouse_stocks');
    expect(stockRows, hasLength(2));
    final kpi0 = await kpiStore.loadSummary();
    expect(kpi0.totalOrders, 0);

    // ─── 2) Mal kabul → satır + lokasyon → putaway onay + kuyruk ─────────
    final receipt = await orderStore.createDraft(
      orderType: WhmsOrderType.malKabul,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      lines: const [
        WhmsOrderLineDto(
          id: 'ln-mk-1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'prd-1',
          productCode: 'SKU-1',
          quantity: 10,
          locationCode: 'A-01-01',
        ),
      ],
    );
    expect(receipt.status, WhmsOrderStatus.draft);
    expect(receipt.approval, WhmsApprovalStatus.pending);

    final putawayDone = await orderStore.confirmReceiptPutaway(
      orderId: receipt.id,
      lines: [
        receipt.lines.first.copyWith(
          locationCode: 'A-01-01',
          quantityDone: 10,
        ),
      ],
    );
    expect(putawayDone.status, WhmsOrderStatus.done);
    expect(putawayDone.approval, WhmsApprovalStatus.approved);
    expect(putawayDone.lines.first.locationCode, 'A-01-01');

    final enqueueReceipt = await orderQueue.enqueueIfApproved(putawayDone);
    expect(enqueueReceipt.status, WhmsOrderEnqueueStatus.enqueued);
    expectQueueRow(
      entityType: WhmsPayloadMapper.entityTypeForOrder(
        WhmsOrderType.malKabul,
      ),
      entityId: putawayDone.id,
    );

    // ─── 3) Transfer: ürün → ambar A→B → onay + kuyruk ───────────────────
    final transfer = await orderStore.createDraft(
      orderType: WhmsOrderType.transfer,
      fromWarehouseCode: 'MRK',
      toWarehouseCode: 'IAD',
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      lines: const [
        WhmsOrderLineDto(
          id: 'ln-tr-1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'prd-1',
          productCode: 'SKU-1',
          quantity: 3,
          lotNo: 'LOT-PLAY',
        ),
      ],
    );
    expect(transfer.fromWarehouseCode, 'MRK');
    expect(transfer.toWarehouseCode, 'IAD');
    expect(transfer.approval, WhmsApprovalStatus.pending);

    await orderStore.setApproval(
      transfer.id,
      WhmsApprovalStatus.approved,
    );
    final transferApproved = await orderStore.getById(transfer.id);
    expect(transferApproved?.approval, WhmsApprovalStatus.approved);

    final transferDto = transferApproved!.toTransferDto();
    expect(transferDto, isNotNull);
    final enqueueTransfer = await transferQueue.enqueueIfApproved(
      transferDto!,
    );
    expect(enqueueTransfer.status, WhmsTransferEnqueueStatus.enqueued);
    expectQueueRow(
      entityType: WhmsPayloadMapper.stockTransferEntityType,
      entityId: transfer.id,
    );

    // Ayrıca tip-genel order queue (aynı ONAY=1)
    final orderAsTransfer = await orderStore.setStatus(
      transfer.id,
      WhmsOrderStatus.done,
    );
    final enqueueTransferOrder = await orderQueue.enqueueIfApproved(
      orderAsTransfer!,
    );
    expect(enqueueTransferOrder.status, WhmsOrderEnqueueStatus.enqueued);

    // ─── 4) Sayım: emir → fiili → tamamla (variance + kuyruk) ────────────
    final countOrder = await countOrderStore.insertDraft(
      warehouseCode: 'MRK',
      locationCode: 'A-01-01',
    );
    expect(countOrder.approval, WhmsApprovalStatus.pending);

    final countLines = [
      const WhmsCountResultLine(
        productId: 'prd-1',
        productCode: 'SKU-1',
        systemQty: 100,
        countedQty: 97,
      ),
    ];
    final draftSaved = await countSession.saveDraft(
      order: countOrder,
      lines: countLines,
    );
    expect(draftSaved.varianceQty, -3);
    expect(draftSaved.approval, WhmsApprovalStatus.pending);

    final countOutcome = await countSession.complete(
      order: countOrder,
      lines: countLines,
      existingResultId: draftSaved.id,
    );
    expect(countOutcome.result.approval, WhmsApprovalStatus.approved);
    expect(countOutcome.result.varianceQty, -3);
    expect(countOutcome.enqueue.status, WhmsCountEnqueueStatus.enqueued);
    expectQueueRow(
      entityType: WhmsPayloadMapper.countResultEntityType,
      entityId: countOutcome.result.id,
    );
    final countRefreshed = await countOrderStore.getById(countOrder.id);
    expect(countRefreshed?.status, WhmsCountOrderStatus.completed);
    expect(countRefreshed?.approval, WhmsApprovalStatus.approved);

    // ─── 5) Pick (rota) + seri ───────────────────────────────────────────
    final pick = await orderStore.createDraft(
      orderType: WhmsOrderType.pick,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      requireSerial: false,
      lines: const [
        WhmsOrderLineDto(
          id: 'ln-pk-1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'prd-seri',
          productCode: 'SKU-SERI',
          quantity: 2,
          routeSeq: 20,
          locationCode: 'B-01-01',
        ),
        WhmsOrderLineDto(
          id: 'ln-pk-2',
          orderId: 'tmp',
          lineNo: 2,
          productId: 'prd-1',
          productCode: 'SKU-1',
          quantity: 4,
          routeSeq: 10,
          locationCode: 'A-01-01',
        ),
      ],
    );

    final sorted = WhmsPickSerialRule.sortByRouteSeq(pick.lines);
    expect(sorted.map((l) => l.id).toList(), ['ln-pk-2', 'ln-pk-1']);

    // Seri zorunlu ürün → seri yokken completePick hata
    expect(
      () => orderStore.completePick(pick.id),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          WhmsPickSerialRule.errorSerialRequired,
        ),
      ),
    );

    await orderStore.updateLinePickScan(
      orderId: pick.id,
      lineId: 'ln-pk-2',
      quantityDone: 4,
    );
    await orderStore.updateLinePickScan(
      orderId: pick.id,
      lineId: 'ln-pk-1',
      serialNo: 'SN-PLAY-001',
      quantityDone: 2,
    );

    final pickDone = await orderStore.completePick(pick.id);
    expect(pickDone?.status, WhmsOrderStatus.done);
    await orderStore.setApproval(pick.id, WhmsApprovalStatus.approved);
    final pickApproved = await orderStore.getById(pick.id);
    expect(pickApproved?.approval, WhmsApprovalStatus.approved);
    expect(
      pickApproved?.lines
          .firstWhere((l) => l.id == 'ln-pk-1')
          .serialNo,
      'SN-PLAY-001',
    );

    final enqueuePick = await orderQueue.enqueueIfApproved(pickApproved!);
    expect(enqueuePick.status, WhmsOrderEnqueueStatus.enqueued);
    expectQueueRow(
      entityType: WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.pick),
      entityId: pick.id,
    );

    // ─── 6) Sevk/load FIFO + picking control (enforce) ───────────────────
    final load = await orderStore.createDraft(
      orderType: WhmsOrderType.load,
      fromWarehouseCode: 'MRK',
      warehouseCode: 'MRK',
      toVehicleId: 'veh-play-1',
      orderDate: '2026-07-28',
      lines: const [
        WhmsOrderLineDto(
          id: 'ln-ld-1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'prd-1',
          productCode: 'SKU-1',
          quantity: 5,
        ),
      ],
    );
    await orderStore.setApproval(load.id, WhmsApprovalStatus.approved);
    final loadDone = await orderStore.setStatus(
      load.id,
      WhmsOrderStatus.done,
    );
    expect(loadDone?.approval, WhmsApprovalStatus.approved);

    // Picking control: eksik → block
    expect(
      () => WhmsPickingControlGate.assertAllowed(
        planned: const [
          WhmsBridgeLine(
            productId: 'prd-1',
            productCode: 'SKU-1',
            quantity: 5,
          ),
        ],
        actual: const [
          WhmsBridgeLine(
            productId: 'prd-1',
            productCode: 'SKU-1',
            quantity: 3,
          ),
        ],
      ),
      throwsA(isA<StateError>()),
    );

    // Eşleşen fiili + FIFO allocate → araç stoğu
    final loadDto = WhmsLoadOrderDto(
      id: load.id,
      fromWarehouseCode: 'MRK',
      toVehicleId: 'veh-play-1',
      date: DateTime(2026, 7, 28),
      lines: const [
        WhmsBridgeLine(
          productId: 'prd-1',
          productCode: 'SKU-1',
          quantity: 5,
        ),
      ],
      approval: WhmsApprovalStatus.approved,
    );
    final consume = await WhmsLoadOrderConsumer.consume(
      db: db,
      order: loadDto,
      enforcePickingControl: true,
      pickedLines: const [
        WhmsBridgeLine(
          productId: 'prd-1',
          productCode: 'SKU-1',
          quantity: 5,
        ),
      ],
      enforceFifo: true,
      today: DateTime(2026, 7, 28),
      rulesByProductCode: const {
        'SKU-1': WhmsFifoRule(
          productCode: 'SKU-1',
          fifoDays: 0,
          fefoEnforce: true,
        ),
      },
      batchesByProductCode: {
        'SKU-1': [
          WhmsFifoBatch(
            lot: 'LOT-PLAY',
            expiry: DateTime(2026, 9, 1),
            qty: 20,
          ),
        ],
      },
    );
    expect(consume.status, WhmsLoadOrderConsumeStatus.applied);

    final vehStock = await db.query(
      'vehicle_stocks',
      where: 'vehicle_id = ? AND product_id = ?',
      whereArgs: <Object?>['veh-play-1', 'prd-1'],
    );
    expect(vehStock, isNotEmpty);
    expect((vehStock.first['quantity'] as num).toDouble(), 5);

    final enqueueLoad = await orderQueue.enqueueIfApproved(loadDone!);
    expect(enqueueLoad.status, WhmsOrderEnqueueStatus.enqueued);
    expectQueueRow(
      entityType: WhmsPayloadMapper.loadOrderEntityType,
      entityId: load.id,
    );

    // ─── 7) Rapor KPI: sayılar artmış mı ────────────────────────────────
    final kpi = await kpiStore.loadSummary();
    expect(kpi.totalOrders, greaterThan(kpi0.totalOrders));
    // mal_kabul + transfer + pick + load = 4 whms_orders
    expect(kpi.totalOrders, 4);
    expect(kpi.completedOrders, greaterThanOrEqualTo(3));
    expect(kpi.countResultRows, greaterThanOrEqualTo(1));
    expect(kpi.countVarianceSum, -3);
    final typeWires = kpi.typeCounts.map((t) => t.typeWire).toSet();
    expect(typeWires, contains(WhmsOrderType.malKabul.wireName));
    expect(typeWires, contains(WhmsOrderType.transfer.wireName));
    expect(typeWires, contains(WhmsOrderType.pick.wireName));
    expect(typeWires, contains(WhmsOrderType.load.wireName));

    // ─── 8) Genel: JobQueue satırları + ONAY assert özeti ────────────────
    expect(jobQueue.length, greaterThanOrEqualTo(5));
    for (final row in jobQueue) {
      expect(row.payload['ONAY'], 1, reason: row.entityType);
    }

    final allOrders = await orderStore.list();
    for (final o in allOrders) {
      if (o.status == WhmsOrderStatus.done) {
        expect(
          o.approval,
          WhmsApprovalStatus.approved,
          reason: '${o.orderType.wireName}/${o.id}',
        );
      }
    }
  });
}
