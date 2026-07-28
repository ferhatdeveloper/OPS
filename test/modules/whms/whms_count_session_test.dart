// Dosya Adı: whms_count_session_test.dart
// Açıklama: Sayım oturumu taslak persist + tamamla ONAY/kuyruk testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/count/model/whms_count_order.dart';
import 'package:exfin_ops/modules/whms/count/model/whms_count_result_line.dart';
import 'package:exfin_ops/modules/whms/count/queue/whms_count_queue_bridge.dart';
import 'package:exfin_ops/modules/whms/count/viewmodel/whms_count_order_store.dart';
import 'package:exfin_ops/modules/whms/count/viewmodel/whms_count_result_store.dart';
import 'package:exfin_ops/modules/whms/count/viewmodel/whms_count_session.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late WhmsCountOrderStore orderStore;
  late WhmsCountResultStore resultStore;
  late WhmsCountSession session;
  final enqueued = <Map<String, dynamic>>[];

  setUp(() async {
    enqueued.clear();
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(SqlQuerys.createWhmsCountOrdersTable);
          await db.execute(SqlQuerys.createWhmsCountResultsTable);
        },
      ),
    );
    orderStore = WhmsCountOrderStore(openDb: () async => db);
    resultStore = WhmsCountResultStore(openDb: () async => db);
    session = WhmsCountSession(
      orderStore: orderStore,
      resultStore: resultStore,
      openDb: () async => db,
      bridge: WhmsCountQueueBridge(
        enqueueFn: ({
          required entityType,
          required entityId,
          required payload,
          priority = 1,
        }) async {
          enqueued.add({
            'entityType': entityType,
            'entityId': entityId,
            'payload': payload,
          });
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('saveDraft SQLite persist + inProgress', () async {
    final order = await orderStore.insertDraft(warehouseCode: 'MRK');
    final lines = [
      const WhmsCountResultLine(
        productId: 'p1',
        productCode: 'SKU-1',
        systemQty: 10,
        countedQty: 9,
      ),
    ];
    final row = await session.saveDraft(order: order, lines: lines);
    expect(row.orderId, order.id);
    expect(row.approval, WhmsApprovalStatus.pending);
    expect(row.varianceQty, -1);

    final loaded = await session.loadDraftLines(order.id);
    expect(loaded.lines, hasLength(1));
    expect(loaded.lines.first.countedQty, 9);
    expect(loaded.lines.first.variance, -1);

    final refreshed = await orderStore.getById(order.id);
    expect(refreshed?.status, WhmsCountOrderStatus.inProgress);
  });

  test('complete ONAY=1 + stock_count kuyruk', () async {
    final order = await orderStore.insertDraft(warehouseCode: 'MRK');
    final lines = [
      const WhmsCountResultLine(
        productId: 'p1',
        productCode: 'SKU-1',
        systemQty: 5,
        countedQty: 7,
      ),
    ];
    final outcome = await session.complete(order: order, lines: lines);
    expect(outcome.result.approval, WhmsApprovalStatus.approved);
    expect(outcome.enqueue.status, WhmsCountEnqueueStatus.enqueued);
    expect(enqueued, hasLength(1));
    expect(enqueued.first['entityType'], 'stock_count');

    final refreshed = await orderStore.getById(order.id);
    expect(refreshed?.status, WhmsCountOrderStatus.completed);
    expect(refreshed?.approval, WhmsApprovalStatus.approved);
  });

  test('complete satırsız StateError', () async {
    final order = await orderStore.insertDraft(warehouseCode: 'MRK');
    expect(
      () => session.complete(order: order, lines: const []),
      throwsA(isA<StateError>()),
    );
  });

  test('WhmsCountResultLine fromMap actual_qty alias', () {
    final line = WhmsCountResultLine.fromMap({
      'product_code': 'SKU-2',
      'system_qty': 3,
      'actual_qty': 4,
      'product_name': 'Test',
    });
    expect(line.productCode, 'SKU-2');
    expect(line.countedQty, 4);
    expect(line.variance, 1);
    expect(line.productName, 'Test');
  });
}
