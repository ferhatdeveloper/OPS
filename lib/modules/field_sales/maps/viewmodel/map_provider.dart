import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../service/database_service.dart';
import '../../../../service/location_service.dart';

class MapState {
  final List<CustomerMarker> customerMarkers;
  final List<LatLng> routePoints;
  final LatLng? currentLocation;
  final bool isLoading;
  final String? error;

  MapState({
    this.customerMarkers = const [],
    this.routePoints = const [],
    this.currentLocation,
    this.isLoading = false,
    this.error,
  });

  MapState copyWith({
    List<CustomerMarker>? customerMarkers,
    List<LatLng>? routePoints,
    LatLng? currentLocation,
    bool? isLoading,
    String? error,
  }) {
    return MapState(
      customerMarkers: customerMarkers ?? this.customerMarkers,
      routePoints: routePoints ?? this.routePoints,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerMarker {
  final String id;
  final String name;
  final LatLng position;
  final bool isVisited;

  CustomerMarker({
    required this.id,
    required this.name,
    required this.position,
    this.isVisited = false,
  });
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(MapState()) {
    loadCustomerMarkers();
    _initLocationTracking();
  }

  Future<void> loadCustomerMarkers() async {
    state = state.copyWith(isLoading: true);
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      // Fetch customers with coordinates
      // Assuming 'customers' table has latitude and longitude
      final customersResult = await db.query('customers');
      
      // Fetch visits today to mark as visited
      final today = DateTime.now().toIso8601String().split('T')[0];
      final visitsResult = await db.query('visits', 
        where: 'date(check_in_at) = ?', 
        whereArgs: [today]
      );
      
      final visitedIds = visitsResult.map((v) => v['customer_id'] as String).toSet();

      final markers = customersResult.map((c) {
        final lat = (c['latitude'] as num?)?.toDouble();
        final lng = (c['longitude'] as num?)?.toDouble();
        
        if (lat != null && lng != null) {
          return CustomerMarker(
            id: c['id'] as String,
            name: c['name'] as String,
            position: LatLng(lat, lng),
            isVisited: visitedIds.contains(c['id']),
          );
        }
        return null;
      }).whereType<CustomerMarker>().toList();

      // Simple route generation (connecting markers in order)
      // In a more advanced version, we'd call a routing API
      final routePoints = markers.map((m) => m.position).toList();

      state = state.copyWith(
        customerMarkers: markers, 
        routePoints: routePoints,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _initLocationTracking() async {
    try {
      await LocationService().initialize();
      
      // Fetch current session for user ID
      final dbService = await DatabaseService.getInstance();
      final session = await dbService.getUserSession();
      final userId = session?['id'] as String? ?? 'demo_user_id';

      // Start background tracking
      await LocationService().startTracking(userId);
      
      // Get initial position
      Position position = await Geolocator.getCurrentPosition();
      state = state.copyWith(currentLocation: LatLng(position.latitude, position.longitude));

      // Listen for updates (for UI only, service handles background)
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        state = state.copyWith(currentLocation: LatLng(position.latitude, position.longitude));
      });
    } catch (e) {
      debugPrint('Map Location Error: $e');
    }
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
