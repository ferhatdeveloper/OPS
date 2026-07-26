import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../modules/field_sales/gps/viewmodel/geofence_settings_store.dart';
import '../../service/database_service.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  /// [_geofenceStore]: Check-in yarıçap / fail-closed prefs
  final GeofenceSettingsStore _geofenceStore = const GeofenceSettingsStore();

  StreamSubscription<Position>? _positionStream;

  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> startTracking() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen((Position position) {
      _savePositionToDb(position);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _savePositionToDb(Position pos) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.insert('gps_logs', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });
      print('GPS Location saved: \${pos.latitude}, \${pos.longitude}');
    } catch (e) {
      print('GPS Save Error: \$e');
    }
  }

  Future<bool> isWithinVisitRange(double targetLat, double targetLng) async {
    final settings = await _geofenceStore.load();
    if (!settings.enabled) return true;

    final pos = await getCurrentPosition();
    if (pos == null) {
      // fail-closed: GPS yoksa ziyaret engellenir
      return !settings.failClosed;
    }

    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      targetLat,
      targetLng,
    );
    return distance <= settings.radiusMeters;
  }
}
