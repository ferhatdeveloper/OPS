// Dosya Adı: route_optimization_service.dart
// Açıklama: Rota nearest-neighbor optimizasyonu (paylaşılan haversine)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../core/geo/haversine.dart';
import '../modules/field_sales/routes/model/route_model.dart';

class RouteOptimizationService {
  static final RouteOptimizationService _instance =
      RouteOptimizationService._internal();
  factory RouteOptimizationService() => _instance;
  RouteOptimizationService._internal();

  /// Optimizes a list of route customers using a Nearest Neighbor algorithm
  List<RouteCustomerModel> optimizeRoute(
    List<RouteCustomerModel> originalSteps,
    double startLat,
    double startLng,
  ) {
    if (originalSteps.isEmpty) return originalSteps;

    final unvisited = List<RouteCustomerModel>.from(originalSteps);
    final optimized = <RouteCustomerModel>[];

    var currentLat = startLat;
    var currentLng = startLng;

    while (unvisited.isNotEmpty) {
      var nearest = unvisited.first;
      var minDistance = double.maxFinite;
      var nearestIndex = 0;

      for (var i = 0; i < unvisited.length; i++) {
        final destLat = unvisited[i].latitude ?? currentLat;
        final destLng = unvisited[i].longitude ?? currentLng;
        final dist = haversineKm(
          currentLat,
          currentLng,
          destLat,
          destLng,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearest = unvisited[i];
          nearestIndex = i;
        }
      }

      optimized.add(nearest);
      unvisited.removeAt(nearestIndex);
      currentLat = nearest.latitude ?? currentLat;
      currentLng = nearest.longitude ?? currentLng;
    }

    return optimized;
  }
}
