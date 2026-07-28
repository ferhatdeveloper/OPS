// Dosya Adı: whms_order_kpi_store_test.dart
// Açıklama: WHMS emir KPI store SQLite aggregate birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_status.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_type.dart';
import 'package:exfin_ops/modules/whms/reports/viewmodel/whms_order_kpi_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late WhmsOrderKpiStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createWhmsOrdersTable);
        await db.execute(SqlQuerys.createWhmsOrderLinesTable);
        await db.execute(SqlQuerys.createWhmsCountResultsTable);
      },
    );
    store = WhmsOrderKpiStore(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertOrder({
    required String id,
    required WhmsOrderType type,
    required WhmsOrderStatus status,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('whms_orders', {
      'id': id,
      'order_type': type.wireName,
      'status': status.wireName,
      'warehouse_code': 'MRK',
      'order_date': '2026-07-28',
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  test('empty → zero summary', () async {
    final s = await store.loadSummary();
    expect(s.totalOrders, 0);
    expect(s.openOrders, 0);
    expect(s.completedOrders, 0);
    expect(s.typeCounts, isEmpty);
    expect(s.countResultRows, 0);
  });

  test('orders + count variance aggregates', () async {
    await insertOrder(
      id: 'o1',
      type: WhmsOrderType.malKabul,
      status: WhmsOrderStatus.draft,
    );
    await insertOrder(
      id: 'o2',
      type: WhmsOrderType.pick,
      status: WhmsOrderStatus.inProgress,
    );
    await insertOrder(
      id: 'o3',
      type: WhmsOrderType.pick,
      status: WhmsOrderStatus.done,
    );
    await insertOrder(
      id: 'o4',
      type: WhmsOrderType.sevk,
      status: WhmsOrderStatus.assigned,
    );

    final now = DateTime.now().toIso8601String();
    await db.insert('whms_count_results', {
      'id': 'c1',
      'warehouse_code': 'MRK',
      'count_date': now,
      'lines_json': '[]',
      'variance_qty': -2.5,
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('whms_count_results', {
      'id': 'c2',
      'warehouse_code': 'MRK',
      'count_date': now,
      'lines_json': '[]',
      'variance_qty': 1.0,
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });

    final s = await store.loadSummary();
    expect(s.totalOrders, 4);
    expect(s.openOrders, 3); // draft+in_progress+assigned
    expect(s.completedOrders, 1);
    expect(s.draftOrders, 1);
    expect(s.inProgressOrders, 1);
    expect(s.typeCounts.length, 3);
    expect(
      s.typeCounts.firstWhere((t) => t.typeWire == 'pick').count,
      2,
    );
    expect(s.countResultRows, 2);
    expect(s.countVarianceSum, closeTo(-1.5, 0.001));
    expect(s.countVarianceAbsSum, closeTo(3.5, 0.001));

    final insight = s.toInsightRows();
    expect(insight.any((r) => r['metric'] == 'open_orders'), isTrue);
    expect(insight.any((r) => r['type'] == 'pick'), isTrue);
  });

  test('soft-deleted orders excluded', () async {
    await insertOrder(
      id: 'o1',
      type: WhmsOrderType.transfer,
      status: WhmsOrderStatus.done,
    );
    await db.update(
      'whms_orders',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: ['o1'],
    );
    final s = await store.loadSummary();
    expect(s.totalOrders, 0);
    expect(s.completedOrders, 0);
  });
}
