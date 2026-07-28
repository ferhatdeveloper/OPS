import 'package:latlong2/latlong.dart';

import '../../../../core/geo/haversine.dart';
import '../model/route_model.dart';

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
        LatLng(
          unvisited.first.latitude ?? 0.0,
          unvisited.first.longitude ?? 0.0,
        );

    while (unvisited.isNotEmpty) {
      RouteCustomerModel? nearest;
      double minDistance = double.infinity;
      int nearestIndex = -1;

      for (int i = 0; i < unvisited.length; i++) {
        final c = unvisited[i];
        if (c.latitude == null || c.longitude == null) continue;

        final dist = haversineKm(
          currentPos.latitude,
          currentPos.longitude,
          c.latitude!,
          c.longitude!,
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
}
