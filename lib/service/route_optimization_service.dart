import 'dart:math';
import '../modules/field_sales/routes/model/route_model.dart';

class RouteOptimizationService {
  static final RouteOptimizationService _instance = RouteOptimizationService._internal();
  factory RouteOptimizationService() => _instance;
  RouteOptimizationService._internal();

  /// Optimizes a list of route customers using a Nearest Neighbor algorithm (Simple TSP)
  List<RouteCustomerModel> optimizeRoute(List<RouteCustomerModel> originalSteps, double startLat, double startLng) {
    if (originalSteps.isEmpty) return originalSteps;

    List<RouteCustomerModel> unvisited = List.from(originalSteps);
    List<RouteCustomerModel> optimized = [];

    double currentLat = startLat;
    double currentLng = startLng;

    while (unvisited.isNotEmpty) {
      RouteCustomerModel nearest = unvisited.first;
      double minDistance = double.maxFinite;
      int nearestIndex = 0;

      for (int i = 0; i < unvisited.length; i++) {
        // Use real lat/lng from customer model
        double destLat = unvisited[i].latitude ?? currentLat;
        double destLng = unvisited[i].longitude ?? currentLng;
        
        double dist = _calculateDistance(currentLat, currentLng, destLat, destLng);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = unvisited[i];
          nearestIndex = i;
        }
      }

      optimized.add(nearest);
      unvisited.removeAt(nearestIndex);
      
      // Update current location to the visited customer
      currentLat = nearest.latitude ?? currentLat;
      currentLng = nearest.longitude ?? currentLng;
    }

    return optimized;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
