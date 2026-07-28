// Dosya Adı: weekly_route_plan_store_test.dart
// Açıklama: Haftalık rota planı SQLite CRUD + mesafe + personel kapsamı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/weekly_route_distance.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/weekly_route_weekday.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/weekly_route_plan_store.dart';

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
        await db.execute(SqlQuerys.createUsersTable);
        await db.execute(SqlQuerys.createCustomersTable);
        await db.execute(SqlQuerys.createRoutesTable);
        await db.execute(SqlQuerys.createRouteCustomersTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
      'address': 'Erbil',
      'latitude': 36.21,
      'longitude': 44.00,
      'is_active': 1,
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta Bakkal',
      'address': 'Ankara',
      'latitude': 36.50,
      'longitude': 44.00,
      'is_active': 1,
    });
    await db.insert('customers', {
      'id': 'c3',
      'code': 'C003',
      'name': 'Gamma (no GPS)',
      'address': '?',
      'is_active': 1,
    });

    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': 'u1',
      'username': 'pls01',
      'email': 'a@t.com',
      'full_name': 'Ali Plasiyer',
      'role': 'sales',
      'is_active': 1,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('users', {
      'id': 'u2',
      'username': 'pls02',
      'email': 'b@t.com',
      'full_name': 'Ayşe Plasiyer',
      'role': 'sales',
      'is_active': 1,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('WeeklyRoutePlanStore', () {
    test('güne cari ekle / kaldır / sırala + bugünkü yükleme', () async {
      final store = WeeklyRoutePlanStore(openDb: () async => db);
      const monday = WeeklyRouteWeekday(WeeklyRouteWeekday.monday);

      var stops = await store.loadStopsForDay(monday);
      expect(stops, isEmpty);

      final a = await store.addStop(weekday: monday, customerId: 'c1');
      final b = await store.addStop(weekday: monday, customerId: 'c2');
      expect(a, isNotNull);
      expect(b, isNotNull);

      stops = await store.loadStopsForDay(monday);
      expect(stops.length, 2);
      expect(stops.first.customerId, 'c1');
      expect(stops.first.visitOrder, 1);
      expect(stops.last.customerId, 'c2');
      expect(stops.last.visitOrder, 2);

      final dup = await store.addStop(weekday: monday, customerId: 'c1');
      expect(dup, isNull);

      await store.moveStop(
        weekday: monday,
        stopId: stops.first.id,
        delta: 1,
      );
      stops = await store.loadStopsForDay(monday);
      expect(stops.first.customerId, 'c2');
      expect(stops.last.customerId, 'c1');

      await store.removeStop(weekday: monday, stopId: stops.first.id);
      stops = await store.loadStopsForDay(monday);
      expect(stops.length, 1);
      expect(stops.first.customerId, 'c1');
      expect(stops.first.visitOrder, 1);

      final today = await store.loadTodaysStops(now: DateTime(2026, 7, 27));
      expect(today.length, 1);
      expect(today.first.dayOfWeek, 1);
    });

    test('farklı günler izole plan tutar', () async {
      final store = WeeklyRoutePlanStore(openDb: () async => db);
      const mon = WeeklyRouteWeekday(1);
      const tue = WeeklyRouteWeekday(2);

      await store.addStop(weekday: mon, customerId: 'c1');
      await store.addStop(weekday: tue, customerId: 'c2');

      final monStops = await store.loadStopsForDay(mon);
      final tueStops = await store.loadStopsForDay(tue);
      expect(monStops.single.customerId, 'c1');
      expect(tueStops.single.customerId, 'c2');
      expect(monStops.single.routeId, isNot(tueStops.single.routeId));
    });

    test('personel bazlı planlar izole; listSalespersons', () async {
      final store = WeeklyRoutePlanStore(openDb: () async => db);
      const mon = WeeklyRouteWeekday(1);

      await store.addStop(
        weekday: mon,
        customerId: 'c1',
        salespersonId: 'u1',
      );
      await store.addStop(
        weekday: mon,
        customerId: 'c2',
        salespersonId: 'u2',
      );
      await store.addStop(weekday: mon, customerId: 'c3');

      final u1 = await store.loadStopsForDay(mon, salespersonId: 'u1');
      final u2 = await store.loadStopsForDay(mon, salespersonId: 'u2');
      final shared = await store.loadStopsForDay(mon);

      expect(u1.single.customerId, 'c1');
      expect(u2.single.customerId, 'c2');
      expect(shared.single.customerId, 'c3');
      expect(u1.single.routeId, contains('weekly-route-sp-u1'));
      expect(u2.single.routeId, isNot(u1.single.routeId));

      final staff = await store.listSalespersons();
      expect(staff.map((s) => s.id).toSet(), containsAll(['u1', 'u2']));
    });

    test('mesafeye göre yeniden numaralandırır (yakın→uzak)', () async {
      final store = WeeklyRoutePlanStore(openDb: () async => db);
      const mon = WeeklyRouteWeekday(1);

      await store.addStop(weekday: mon, customerId: 'c2');
      await store.addStop(weekday: mon, customerId: 'c1');
      await store.addStop(weekday: mon, customerId: 'c3');

      final result = await store.reorderStopsByDistance(
        weekday: mon,
        origin: const WeeklyRouteGeoPoint(lat: 36.20, lng: 44.00),
      );

      expect(
        result.ordered.map((s) => s.customerId).toList(),
        ['c1', 'c2', 'c3'],
      );
      expect(result.ordered.map((s) => s.visitOrder).toList(), [1, 2, 3]);
      expect(result.missingCoordsCount, 1);
      expect(result.ordered.first.hasCoords, isTrue);
      expect(result.ordered.last.hasCoords, isFalse);
    });

    test('cari ziyaret günleri set / load / filtre', () async {
      final store = WeeklyRoutePlanStore(openDb: () async => db);
      const mon = WeeklyRouteWeekday(1);
      const wed = WeeklyRouteWeekday(3);
      const fri = WeeklyRouteWeekday(5);

      await store.setCustomerWeekdays(
        customerId: 'c1',
        weekdays: {mon, wed, fri},
      );

      var days = await store.loadWeekdaysForCustomer('c1');
      expect(days.map((d) => d.dayOfWeek).toSet(), {1, 3, 5});

      final monIds = await store.loadCustomerIdsForDay(mon);
      expect(monIds, contains('c1'));
      expect(monIds, isNot(contains('c2')));

      await store.toggleCustomerWeekday(
        customerId: 'c1',
        weekday: wed,
        selected: false,
      );
      days = await store.loadWeekdaysForCustomer('c1');
      expect(days.map((d) => d.dayOfWeek).toSet(), {1, 5});

      await store.toggleCustomerWeekday(
        customerId: 'c2',
        weekday: mon,
        selected: true,
      );
      final monIds2 = await store.loadCustomerIdsForDay(mon);
      expect(monIds2, containsAll(['c1', 'c2']));

      final all = [
        {'id': 'c1'},
        {'id': 'c2'},
        {'id': 'c3'},
      ];
      final filtered = WeeklyRoutePlanStore.filterCustomersByRouteDay(
        customers: all,
        idOf: (m) => m['id']!,
        routeCustomerIds: monIds2,
      );
      expect(filtered.map((m) => m['id']), ['c1', 'c2']);

      final unfiltered = WeeklyRoutePlanStore.filterCustomersByRouteDay(
        customers: all,
        idOf: (m) => m['id']!,
        routeCustomerIds: null,
      );
      expect(unfiltered.length, 3);
    });
  });
}
