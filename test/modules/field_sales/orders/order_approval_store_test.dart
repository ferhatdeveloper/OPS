// Dosya Adı: order_approval_store_test.dart
// Açıklama: Sipariş onaylama dens Öneri/Sevk SQLite sorgu + status update
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_approval_store.dart';

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
        await db.execute(SqlQuerys.createCustomersTable);
        await db.execute(SqlQuerys.createOrdersTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta Tedarik',
    });

    final now = DateTime.now();
    Future<void> insertOrder({
      required String id,
      required String customerId,
      required String status,
      required String orderType,
      required double amount,
      DateTime? date,
    }) async {
      final d = date ?? now;
      await db.insert('orders', {
        'id': id,
        'customer_id': customerId,
        'order_date': d.toIso8601String(),
        'total_amount': amount,
        'status': status,
        'is_synced': 0,
        'order_type': orderType,
        'created_at': d.toIso8601String(),
      });
    }

    await insertOrder(
      id: 'o-pending',
      customerId: 'c1',
      status: 'Pending',
      orderType: 'sales',
      amount: 100,
    );
    await insertOrder(
      id: 'o-proposal',
      customerId: 'c1',
      status: 'Proposal',
      orderType: 'purchase',
      amount: 200,
    );
    await insertOrder(
      id: 'o-ship',
      customerId: 'c2',
      status: 'Shippable',
      orderType: 'sales',
      amount: 300,
    );
    await insertOrder(
      id: 'o-notship',
      customerId: 'c2',
      status: 'NotShippable',
      orderType: 'sales',
      amount: 50,
    );
    await insertOrder(
      id: 'o-old',
      customerId: 'c1',
      status: 'Pending',
      orderType: 'sales',
      amount: 10,
      date: now.subtract(const Duration(days: 90)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Öneri sekmesi Pending/Proposal döner; eski dönem dışı', () async {
    final store = OrderApprovalStore(openDb: () async => db);
    final now = DateTime.now();
    final rows = await store.query(
      tab: OrderApprovalDensTab.proposal,
      periodFrom: now.subtract(const Duration(days: 30)),
      periodTo: now,
    );
    final ids = rows.map((r) => r.id).toSet();
    expect(ids, containsAll(['o-pending', 'o-proposal']));
    expect(ids, isNot(contains('o-ship')));
    expect(ids, isNot(contains('o-old')));
    expect(rows.first.displayTitle, contains('Alpha'));
  });

  test('Sevk Edilebilir Approved/Shippable; tip filtresi', () async {
    final store = OrderApprovalStore(openDb: () async => db);
    final now = DateTime.now();
    final rows = await store.query(
      tab: OrderApprovalDensTab.dispatch,
      sevkShippable: true,
      orderType: OrderType.sales,
      periodFrom: now.subtract(const Duration(days: 30)),
      periodTo: now,
    );
    expect(rows.map((r) => r.id), ['o-ship']);
  });

  test('Sevk Edilemez NotShippable', () async {
    final store = OrderApprovalStore(openDb: () async => db);
    final now = DateTime.now();
    final rows = await store.query(
      tab: OrderApprovalDensTab.dispatch,
      sevkShippable: false,
      periodFrom: now.subtract(const Duration(days: 30)),
      periodTo: now,
    );
    expect(rows.map((r) => r.id), ['o-notship']);
  });

  test('updateStatus Pending → Shippable; tip korunur', () async {
    final store = OrderApprovalStore(openDb: () async => db);
    final n = await store.updateStatus(
      id: 'o-pending',
      status: 'Shippable',
    );
    expect(n, 1);

    final now = DateTime.now();
    final proposal = await store.query(
      tab: OrderApprovalDensTab.proposal,
      periodFrom: now.subtract(const Duration(days: 30)),
      periodTo: now,
    );
    expect(proposal.map((r) => r.id), isNot(contains('o-pending')));

    final sevk = await store.query(
      tab: OrderApprovalDensTab.dispatch,
      sevkShippable: true,
      periodFrom: now.subtract(const Duration(days: 30)),
      periodTo: now,
    );
    final moved = sevk.firstWhere((r) => r.id == 'o-pending');
    expect(moved.status, 'Shippable');
    expect(moved.orderType, OrderType.sales);
  });

  test('statusL10nKey bilinen kodlar', () {
    expect(
      OrderApprovalStore.statusL10nKey('Proposal'),
      'field_sales.order_list_dens.status_proposal',
    );
    expect(
      OrderApprovalStore.statusL10nKey('Not_Shippable'),
      'field_sales.order_list_dens.status_not_shippable',
    );
  });
}
