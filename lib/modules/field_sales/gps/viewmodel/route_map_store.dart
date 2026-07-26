// Dosya Adı: route_map_store.dart
// Açıklama: Rota haritası dens ziyaret noktaları SQLite okuma + seed
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/route_visit_point.dart';
import '../model/route_visit_point_seed.dart';

/// {@template route_map_store}
/// Aktif rota ziyaret noktalarını SQLite'tan yükler; boşsa seed yazar.
///
/// Kullanım örneği:
/// ```dart
/// final store = RouteMapStore();
/// final points = await store.loadVisitPoints();
/// ```
/// {@endtemplate}
class RouteMapStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro route_map_store}
  const RouteMapStore({this.openDb});

  /// {@template route_map_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template route_map_store_ensure}
  /// routes / route_customers / customers / visits tablolarını oluşturur;
  /// ziyaret noktası yoksa seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createRoutesTable);
    await db.execute(SqlQuerys.createRouteCustomersTable);
    await db.execute(SqlQuerys.createVisitsTable);
    await seedIfEmpty(db);
  }

  /// {@template route_map_store_seed_if_empty}
  /// `route_customers` boşsa demo rota + cari + noktaları yazar.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM route_customers'),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    for (final c in RouteVisitPointSeed.customerMaps) {
      batch.insert(
        'customers',
        c,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    batch.insert(
      'routes',
      RouteVisitPointSeed.routeMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (final rc in RouteVisitPointSeed.routeCustomerMaps) {
      batch.insert(
        'route_customers',
        rc,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template route_map_store_load_visit_points}
  /// Aktif rota ziyaret noktalarını sırayla yükler; bugünkü ziyaretleri işaretler.
  ///
  /// Dönüş değeri:
  /// - [List<RouteVisitPoint>]: Dens ziyaret noktaları
  /// {@endtemplate}
  Future<List<RouteVisitPoint>> loadVisitPoints() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.rawQuery(SqlQuerys.routeMapVisitPointsSql);
    final points = maps.map(RouteVisitPoint.fromMap).toList(growable: false);

    final today = DateTime.now().toIso8601String().split('T').first;
    final visits = await db.query(
      'visits',
      columns: ['customer_id'],
      where: 'date(check_in_at) = date(?)',
      whereArgs: [today],
    );
    final visitedIds = visits
        .map((v) => v['customer_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    if (visitedIds.isEmpty) return points;
    return points
        .map(
          (p) => visitedIds.contains(p.customerId)
              ? p.copyWith(isVisited: true)
              : p,
        )
        .toList(growable: false);
  }
}
