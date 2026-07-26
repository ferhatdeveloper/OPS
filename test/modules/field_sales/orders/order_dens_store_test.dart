// Dosya Adı: order_dens_store_test.dart
// Açıklama: Sipariş dens store kapsam süzgeçleri (SQLite FFI)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_scope.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_dens_store.dart';

void main() {
  late Database db;
  late OrderDensStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
    await db.insert('customers', {
      'id': 'C-1',
      'code': 'C001',
      'name': 'Demo Cari',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    final now = DateTime.now().toIso8601String();
    await db.insert('orders', {
      'id': 'ord-synced',
      'customer_id': 'C-1',
      'order_date': now,
      'total_amount': 100,
      'status': 'Approved',
      'is_synced': 1,
      'order_type': 'sales',
      'created_at': now,
    });
    await db.insert('orders', {
      'id': 'ord-pending',
      'customer_id': 'C-1',
      'order_date': now,
      'total_amount': 50,
      'status': 'Pending',
      'is_synced': 0,
      'order_type': 'sales',
      'created_at': now,
    });
    await db.insert('orders', {
      'id': 'ord-purchase',
      'customer_id': 'C-1',
      'order_date': now,
      'total_amount': 75,
      'status': 'Proposal',
      'is_synced': 0,
      'order_type': 'purchase',
      'created_at': now,
    });
    store = OrderDensStore(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('tracking tüm siparişleri döner', () async {
    final rows = await store.query(OrderDensScope.tracking);
    expect(rows.length, 3);
    expect(rows.first.displayTitle, contains('Demo Cari'));
  });

  test('transferred yalnızca is_synced=1', () async {
    final rows = await store.query(OrderDensScope.transferred);
    expect(rows.map((r) => r.id), ['ord-synced']);
  });

  test('untransferred is_synced=0', () async {
    final rows = await store.query(OrderDensScope.untransferred);
    expect(rows.length, 2);
    expect(rows.every((r) => !r.isSynced), isTrue);
  });

  test('pending Pending/Proposal', () async {
    final rows = await store.query(OrderDensScope.pending);
    expect(rows.length, 2);
    expect(
      rows.map((r) => r.id).toSet(),
      {'ord-pending', 'ord-purchase'},
    );
  });
}
