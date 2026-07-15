import 'dart:math';
import '../model/route_model.dart';
import 'package:latlong2/latlong.dart';

class RouteOptimizer {
  /// Optimizes the visit order using a Greedy (Nearest Neighbor) approach.
  static List<RouteCustomerModel> optimize(
    List<RouteCustomerModel> customers, {
    LatLng? startLocation,
  }) {
    if (customers.isEmpty) return [];
    
    List<RouteCustomerModel> unvisited = List.from(customers);
    List<RouteCustomerModel> optimized = [];
    
    // Start from provided location or the first customer in the original list
    LatLng currentPos = startLocation ?? 
        LatLng(unvisited.first.latitude ?? 0.0, unvisited.first.longitude ?? 0.0);
    
    while (unvisited.isNotEmpty) {
      RouteCustomerModel? nearest;
      double minDistance = double.infinity;
      int nearestIndex = -1;
      
      for (int i = 0; i < unvisited.length; i++) {
        final c = unvisited[i];
        if (c.latitude == null || c.longitude == null) continue;
        
        double dist = _calculateDistance(
          currentPos.latitude, 
          currentPos.longitude, 
          c.latitude!, 
          c.longitude!
        );
        
        if (dist < minDistance) {
          minDistance = dist;
          nearest = c;
          nearestIndex = i;
        }
      }
      
      if (nearest != null) {
        optimized.add(nearest);
        unvisited.removeAt(nearestIndex);
        currentPos = LatLng(nearest.latitude!, nearest.longitude!);
      } else {
        // If no more customers have coordinates, add remaining and break
        optimized.addAll(unvisited);
        break;
      }
    }
    
    return optimized;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
