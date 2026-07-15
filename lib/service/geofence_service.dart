import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'database_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final double _proximityThreshold = 100.0; // meters
  final Set<String> _notifiedClientIds = {};

  /// Monitors location updates and checks for proximity to clients
  Future<void> checkProximity(Position position, String userId) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      // Fetch active route clients for today
      // Assuming 'visits' or a 'route_plans' table defines the daily goal
      // For now, let's check all customers with coordinates
      final customers = await db.query('customers', 
        where: 'latitude IS NOT NULL AND longitude IS NOT NULL'
      );

      for (var customer in customers) {
        final String customerId = customer['id'] as String;
        final String customerName = customer['name'] as String;
        final double lat = (customer['latitude'] as num).toDouble();
        final double lng = (customer['longitude'] as num).toDouble();

        double distance = Geolocator.distanceBetween(
          position.latitude, 
          position.longitude, 
          lat, 
          lng
        );

        if (distance <= _proximityThreshold) {
          if (!_notifiedClientIds.contains(customerId)) {
            _triggerProximityAlert(customerId, customerName, distance);
            _notifiedClientIds.add(customerId);
          }
        } else {
          // Reset notification if they move away, so it can trigger again later
          _notifiedClientIds.remove(customerId);
        }
      }
    } catch (e) {
      debugPrint('Geofence Error: $e');
    }
  }

  void _triggerProximityAlert(String customerId, String name, double distance) {
    NotificationService().showNotification(
      id: customerId.hashCode,
      title: '📍 Yakındaki Müşteri',
      body: '$name müşterisine yaklaştınız (${distance.toInt()}m). Ziyareti başlatmak ister misiniz?',
      payload: customerId,
    );
  }

  void clearCache() {
    _notifiedClientIds.clear();
  }
}
