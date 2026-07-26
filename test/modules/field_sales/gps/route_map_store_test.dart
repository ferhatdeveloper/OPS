// Dosya Adı: route_map_store_test.dart
// Açıklama: Rota haritası dens ziyaret noktaları SQLite seed/JOIN testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/route_visit_point_seed.dart';
import 'package:exfin_ops/modules/field_sales/gps/viewmodel/route_map_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late RouteMapStore store;

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
        await db.execute(SqlQuerys.createRoutesTable);
        await db.execute(SqlQuerys.createRouteCustomersTable);
        await db.execute(SqlQuerys.createVisitsTable);
      },
    );
    store = RouteMapStore(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RouteMapStore', () {
    test('ensureReady boş route_customers için seed yazar', () async {
      final points = await store.loadVisitPoints();

      expect(points, hasLength(RouteVisitPointSeed.defaultPoints.length));
      expect(points.first.visitOrder, 1);
      expect(points.first.customerCode, 'RM001');
      expect(points.first.hasCoords, isTrue);
      expect(points.first.customerName, 'Alpha Market');
      expect(points.last.visitOrder, 3);
      expect(points.last.isMandatory, isFalse);
    });

    test('seedIfEmpty ikinci çağrıda çoğaltmaz', () async {
      await store.ensureReady();
      await store.seedIfEmpty(db);

      final countRow = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM route_customers',
      );
      final count = (countRow.first['c'] as num?)?.toInt() ?? 0;
      expect(count, RouteVisitPointSeed.defaultPoints.length);
    });

    test('bugünkü visit satırı isVisited işaretler', () async {
      await store.ensureReady();
      final today = DateTime.now().toIso8601String();
      await db.insert('visits', {
        'id': 'v-seed-1',
        'customer_id': 'seed-rm-c1',
        'check_in_at': today,
        'status': 'Completed',
        'is_synced': 0,
      });

      final points = await store.loadVisitPoints();
      final first = points.firstWhere((p) => p.customerId == 'seed-rm-c1');
      final second = points.firstWhere((p) => p.customerId == 'seed-rm-c2');

      expect(first.isVisited, isTrue);
      expect(second.isVisited, isFalse);
    });

    test('mevcut route_customers seed atlar ve JOIN döner', () async {
      await db.insert('customers', {
        'id': 'c-live',
        'code': 'L001',
        'name': 'Live Market',
        'latitude': 36.2,
        'longitude': 44.0,
      });
      await db.insert('routes', {
        'id': 'r-live',
        'name': 'Live Route',
        'day_of_week': 1,
        'is_active': 1,
      });
      await db.insert('route_customers', {
        'id': 'rc-live',
        'route_id': 'r-live',
        'customer_id': 'c-live',
        'visit_order': 1,
        'is_mandatory': 1,
      });

      final points = await store.loadVisitPoints();
      expect(points, hasLength(1));
      expect(points.first.customerCode, 'L001');
      expect(points.first.routeName, 'Live Route');
      expect(points.first.latitude, 36.2);
    });
  });
}
