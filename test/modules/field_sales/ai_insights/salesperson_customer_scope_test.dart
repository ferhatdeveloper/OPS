// Dosya Adı: salesperson_customer_scope_test.dart
// Açıklama: Plasiyer cari kapsamı — admin null, rota/ziyaret, fallback
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/auth/app_user_role.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/ai_insights/viewmodel/salesperson_customer_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
      onCreate: (database, version) async {
        await database.execute(SqlQuerys.createRoutesTable);
        await database.execute(SqlQuerys.createRouteCustomersTable);
        await database.execute(SqlQuerys.createVisitsTable);
        await database.execute(SqlQuerys.createCustomersTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('admin → filtre null (tüm cariler)', () async {
    final scope = SalespersonCustomerScope(db: db);
    final ids = await scope.resolveFilterIds(
      role: AppUserRole.admin,
      userId: 'u1',
    );
    expect(ids, isNull);
  });

  test('plasiyer rota carileri + visits birleşir', () async {
    await db.insert('routes', {
      'id': 'r1',
      'name': 'Pzt',
      'salesperson_id': 'sp1',
      'day_of_week': 1,
      'is_active': 1,
    });
    await db.insert('route_customers', {
      'id': 'rc1',
      'route_id': 'r1',
      'customer_id': 'c_route',
      'visit_order': 1,
    });
    await db.insert('visits', {
      'id': 'v1',
      'customer_id': 'c_visit',
      'user_id': 'sp1',
      'status': 'Completed',
      'is_synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    final scope = SalespersonCustomerScope(db: db);
    final r = await scope.resolve(
      role: AppUserRole.salesperson,
      userId: 'sp1',
    );
    expect(r.routeUnassigned, isFalse);
    expect(r.filterIds, containsAll(['c_route', 'c_visit']));
  });

  test('plasiyer atamasız → aktif cari fallback + routeUnassigned', () async {
    await db.insert('customers', {
      'id': 'c_active',
      'name': 'Aktif Cari',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('customers', {
      'id': 'c_off',
      'name': 'Pasif',
      'is_active': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    final scope = SalespersonCustomerScope(db: db);
    final r = await scope.resolve(
      role: AppUserRole.salesperson,
      userId: 'nobody',
    );
    expect(r.routeUnassigned, isTrue);
    expect(r.filterIds, isNotNull);
    expect(r.filterIds, contains('c_active'));
    expect(r.filterIds!.contains('c_off'), isFalse);
  });
}
