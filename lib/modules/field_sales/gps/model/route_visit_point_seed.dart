// Dosya Adı: route_visit_point_seed.dart
// Açıklama: Rota haritası dens ziyaret noktası stub seed (Erbil bölgesi)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'route_visit_point.dart';

/// {@template route_visit_point_seed}
/// MBT Rota Haritası dens seed — SQLite boşken örnek ziyaret noktaları.
///
/// Kullanım örneği:
/// ```dart
/// final points = RouteVisitPointSeed.defaultPoints;
/// ```
/// {@endtemplate}
class RouteVisitPointSeed {
  RouteVisitPointSeed._();

  /// [routeId]: Seed rota kimliği
  static const String routeId = 'seed-route-map-01';

  /// [routeName]: Seed rota adı
  static const String routeName = 'Demo Rota — Erbil';

  /// Seed müşteri satırları (customers tablosu).
  static List<Map<String, dynamic>> get customerMaps {
    final now = DateTime.now().toIso8601String();
    return [
      {
        'id': 'seed-rm-c1',
        'code': 'RM001',
        'name': 'Alpha Market',
        'address': 'Erbil — Ankawa',
        'latitude': 36.2305,
        'longitude': 43.9925,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'seed-rm-c2',
        'code': 'RM002',
        'name': 'Beta Gıda',
        'address': 'Erbil — 100m Street',
        'latitude': 36.1910,
        'longitude': 44.0090,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'seed-rm-c3',
        'code': 'RM003',
        'name': 'Gamma Ticaret',
        'address': 'Erbil — Downtown',
        'latitude': 36.1912,
        'longitude': 44.0091,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
    ];
  }

  /// Seed rota satırı (routes tablosu).
  static Map<String, dynamic> get routeMap {
    final now = DateTime.now();
    return {
      'id': routeId,
      'name': routeName,
      'salesperson_id': 'seed-sp-01',
      'day_of_week': now.weekday,
      'is_active': 1,
      'is_synced': 0,
      'created_at': now.toIso8601String(),
    };
  }

  /// Yer tutucu dens ziyaret noktaları.
  static final List<RouteVisitPoint> defaultPoints = [
    const RouteVisitPoint(
      id: 'seed-rm-rc1',
      routeId: routeId,
      routeName: routeName,
      customerId: 'seed-rm-c1',
      customerCode: 'RM001',
      customerName: 'Alpha Market',
      customerAddress: 'Erbil — Ankawa',
      visitOrder: 1,
      latitude: 36.2305,
      longitude: 43.9925,
    ),
    const RouteVisitPoint(
      id: 'seed-rm-rc2',
      routeId: routeId,
      routeName: routeName,
      customerId: 'seed-rm-c2',
      customerCode: 'RM002',
      customerName: 'Beta Gıda',
      customerAddress: 'Erbil — 100m Street',
      visitOrder: 2,
      latitude: 36.1910,
      longitude: 44.0090,
    ),
    const RouteVisitPoint(
      id: 'seed-rm-rc3',
      routeId: routeId,
      routeName: routeName,
      customerId: 'seed-rm-c3',
      customerCode: 'RM003',
      customerName: 'Gamma Ticaret',
      customerAddress: 'Erbil — Downtown',
      visitOrder: 3,
      isMandatory: false,
      latitude: 36.1912,
      longitude: 44.0091,
    ),
  ];

  /// route_customers insert map listesi.
  static List<Map<String, dynamic>> get routeCustomerMaps =>
      defaultPoints.map((p) => p.toRouteCustomerMap()).toList(growable: false);
}
