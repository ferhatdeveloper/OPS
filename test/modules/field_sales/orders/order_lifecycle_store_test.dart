// Dosya Adı: order_lifecycle_store_test.dart
// Açıklama: Sipariş soft-delete / cancel + sync_queue birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_dens_store.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_scope.dart';

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
        await db.execute(SqlQuerys.createOrdersTable);
        await db.execute(SqlQuerys.createOrderItemsTable);
        await db.execute(SqlQuerys.createSyncQueueTable);
        await db.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id TEXT PRIMARY KEY,
            code TEXT,
            name TEXT
          )
        ''');
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> _seedOrder({
    required String id,
    int isSynced = 0,
    String status = 'Pending',
  }) async {
    await db.insert('orders', {
      'id': id,
      'customer_id': 'c1',
      'order_date': DateTime.now().toIso8601String(),
      'total_amount': 10,
      'status': status,
      'is_synced': isSynced,
      'is_deleted': 0,
      'approval_status': 0,
      'order_type': 'sales',
    });
    await db.insert('order_items', {
      'id': '${id}_i1',
      'order_id': id,
      'product_id': 'p1',
      'quantity': 1,
      'price': 10,
      'vat_amount': 0,
      'total_amount': 10,
    });
  }

  test('softDeleteLocal siler ve sync_queue delete ekler', () async {
    await _seedOrder(id: 'ord-del');
    final store = OrderDensStore(openDb: () async => db);
    final ok = await store.softDeleteLocal('ord-del');
    expect(ok, isTrue);

    final rows = await store.query(OrderDensScope.untransferred);
    expect(rows.any((r) => r.id == 'ord-del'), isFalse);

    final queue = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: ['ord-del'],
    );
    expect(queue, isNotEmpty);
    expect(
      (jsonDecode(queue.first['payload'] as String) as Map)['op'],
      'delete',
    );
  });

  test('cancelLocal status Cancelled + sync_queue cancel', () async {
    await _seedOrder(id: 'ord-can');
    final store = OrderDensStore(openDb: () async => db);
    final ok = await store.cancelLocal('ord-can');
    expect(ok, isTrue);

    final header = await store.fetchOrderHeader('ord-can');
    expect(header?['status'], 'Cancelled');

    final queue = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: ['ord-can'],
    );
    expect(
      queue.any(
        (r) =>
            (jsonDecode(r['payload'] as String) as Map)['op'] == 'cancel',
      ),
      isTrue,
    );
  });

  test('synced sipariş soft-delete false', () async {
    await _seedOrder(id: 'ord-sync', isSynced: 1);
    final store = OrderDensStore(openDb: () async => db);
    expect(await store.softDeleteLocal('ord-sync'), isFalse);
    expect(await store.cancelLocal('ord-sync'), isFalse);
  });
}
