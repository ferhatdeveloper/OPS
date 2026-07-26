// Dosya Adı: orders_untransferred_query_test.dart
// Açıklama: K06 — OrderDensStore untransferred + sync_queue join testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_scope.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_dens_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('OrderDensStore untransferred + sync_queue', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createCustomersTable);
          await database.execute(SqlQuerys.createOrdersTable);
          await database.execute(SqlQuerys.createSyncQueueTable);
        },
      );
      await db.insert('customers', {
        'id': 'cust-1',
        'code': 'ARP001',
        'name': 'ABC Market',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('is_synced=0 döner; synced dışlanır', () async {
      await db.insert('orders', {
        'id': 'ord-unsynced',
        'customer_id': 'cust-1',
        'order_date': '2026-07-26T10:00:00.000',
        'total_amount': 150.5,
        'status': 'Pending',
        'is_synced': 0,
        'order_type': 'sales',
        'created_at': '2026-07-26T10:00:00.000',
      });
      await db.insert('orders', {
        'id': 'ord-synced',
        'customer_id': 'cust-1',
        'order_date': '2026-07-25T10:00:00.000',
        'total_amount': 99,
        'status': 'Approved',
        'is_synced': 1,
        'order_type': 'sales',
        'created_at': '2026-07-25T10:00:00.000',
      });

      final store = OrderDensStore(openDb: () async => db);
      final rows = await store.query(OrderDensScope.untransferred);
      expect(rows, hasLength(1));
      expect(rows.first.id, 'ord-unsynced');
      expect(rows.first.customerCode, 'ARP001');
      expect(rows.first.orderType, OrderType.sales);
      expect(rows.first.isSynced, isFalse);
    });

    test('sync_queue join: retry_count + last_error taşır', () async {
      await db.insert('orders', {
        'id': 'ord-q',
        'customer_id': 'cust-1',
        'order_date': '2026-07-26T12:00:00.000',
        'total_amount': 40,
        'status': 'Pending',
        'is_synced': 0,
        'order_type': 'purchase',
        'created_at': '2026-07-26T12:00:00.000',
      });
      await db.insert('sync_queue', {
        'id': 'job-1',
        'entity_type': 'order',
        'entity_id': 'ord-q',
        'payload': '{}',
        'priority': 1,
        'retry_count': 2,
        'last_error': 'timeout',
        'created_at': '2026-07-26T12:01:00.000',
      });

      final store = OrderDensStore(openDb: () async => db);
      final rows = await store.query(OrderDensScope.untransferred);
      expect(rows, hasLength(1));
      expect(rows.first.orderType, OrderType.purchase);
      expect(rows.first.queueJobId, 'job-1');
      expect(rows.first.retryCount, 2);
      expect(rows.first.lastError, 'timeout');
    });
  });
}
