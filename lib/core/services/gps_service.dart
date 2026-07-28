// Dosya Adı: gps_service.dart
// Açıklama: GPS konum takibi, check-in yarıçap ve proximity köprüsü
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../modules/field_sales/gps/model/live_location_quality.dart';
import '../../modules/field_sales/gps/model/personnel_live_location.dart';
import '../../modules/field_sales/gps/viewmodel/geofence_settings_store.dart';
import '../../service/database_service.dart';
import '../../service/geofence_service.dart';
import '../../service/postgres_service.dart';
import '../geo/haversine.dart';
import '../tenant/postgrest_http_client.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  /// [_geofenceStore]: Check-in yarıçap / fail-closed prefs
  final GeofenceSettingsStore _geofenceStore = const GeofenceSettingsStore();

  StreamSubscription<Position>? _positionStream;

  /// [_heartbeat]: Sabitken de canlı snapshot yenileme
  Timer? _heartbeat;

  /// [_activeUserId]: Canlı oturum kullanıcı id
  String _activeUserId = '';

  /// [_salespersonCode]: Plasiyer kodu (gps_logs)
  String _salespersonCode = '';

  /// [_tracking]: Oturum açık mı
  bool _tracking = false;

  /// [_lastSyncedLat/_lastSyncedLng]: Son canlı sync konumu
  double? _lastSyncedLat;
  double? _lastSyncedLng;

  /// [_lastLogAt]: Son gps_logs satırı
  DateTime? _lastLogAt;

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
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      timeLimit: const Duration(seconds: 8),
    );
  }

  /// Platforma göre yüksek doğruluk + sık güncelleme ayarı.
  LocationSettings _trackingSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: LiveLocationQuality.distanceFilterMeters,
        intervalDuration: LiveLocationQuality.streamInterval,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: LiveLocationQuality.distanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: LiveLocationQuality.distanceFilterMeters,
    );
  }

  Future<void> startTracking({
    String userId = '',
    String salespersonCode = '',
  }) async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    _activeUserId = userId.trim();
    _salespersonCode = salespersonCode.trim().isEmpty
        ? _activeUserId
        : salespersonCode.trim();
    _tracking = true;

    await _positionStream?.cancel();
    _heartbeat?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _trackingSettings(),
    ).listen((Position position) {
      unawaited(_onPosition(position, forProximity: true));
    });

    // Mesafe filtresi sabitken susar; heartbeat canlılığı korur.
    _heartbeat = Timer.periodic(
      LiveLocationQuality.heartbeatInterval,
      (_) => unawaited(_heartbeatTick()),
    );
    unawaited(_heartbeatTick());
  }

  Future<void> _heartbeatTick() async {
    if (!_tracking) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 6),
      );
      await _onPosition(pos, forProximity: false);
    } catch (_) {
      // Timeout / izin — bir sonraki tick dener
    }
  }

  Future<void> _onPosition(
    Position position, {
    required bool forProximity,
  }) async {
    final fixAge = DateTime.now().difference(position.timestamp);
    final syncOk = LiveLocationQuality.acceptsFix(
      accuracyMeters: position.accuracy,
      fixAge: fixAge,
      maxAccuracyMeters: LiveLocationQuality.maxSyncAccuracyMeters,
    );
    if (syncOk) {
      await _persistAndSync(position);
    }

    if (!forProximity) return;
    final proximityOk = LiveLocationQuality.acceptsFix(
      accuracyMeters: position.accuracy,
      fixAge: fixAge,
      maxAccuracyMeters: LiveLocationQuality.maxProximityAccuracyMeters,
    );
    if (!proximityOk) return;
    unawaited(
      GeofenceService().checkProximity(position, _activeUserId),
    );
  }

  void stopTracking() {
    _tracking = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _persistAndSync(Position pos) async {
    final now = DateTime.now();
    final movedEnough = _lastSyncedLat == null ||
        haversineMeters(
              _lastSyncedLat!,
              _lastSyncedLng!,
              pos.latitude,
              pos.longitude,
            ) >=
            LiveLocationQuality.distanceFilterMeters;
    final logDue = _lastLogAt == null ||
        now.difference(_lastLogAt!) >= const Duration(seconds: 30);

    if (movedEnough || logDue) {
      final id = now.millisecondsSinceEpoch.toString();
      try {
        final dbService = await DatabaseService.getInstance();
        final db = await dbService.getDatabase();
        await db.insert('gps_logs', {
          'id': id,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'timestamp': now.toIso8601String(),
          'salesperson_code': _salespersonCode,
          'label': _salespersonCode,
          'accuracy': pos.accuracy,
          'is_synced': 0,
          'is_deleted': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        _lastLogAt = now;
      } catch (_) {
        // Offline / tablo yok — proximity yine çalışabilir
      }
    }

    final live = PersonnelLiveLocation(
      userId: _activeUserId.isEmpty ? _salespersonCode : _activeUserId,
      salespersonCode: _salespersonCode,
      displayName: _salespersonCode,
      latitude: pos.latitude,
      longitude: pos.longitude,
      updatedAt: now,
      accuracy: pos.accuracy,
      isSynced: false,
    );
    await _trySyncLive(live);
    _lastSyncedLat = pos.latitude;
    _lastSyncedLng = pos.longitude;
  }

  Future<void> _trySyncLive(PersonnelLiveLocation live) async {
    try {
      final client = PostgrestHttpClient();
      if (client.isConfigured) {
        await client.postRow(
          '/live_location_snapshots',
          {
            'user_id': live.userId,
            'salesperson_code': live.salespersonCode,
            'latitude': live.latitude,
            'longitude': live.longitude,
            'accuracy': live.accuracy,
            'last_update': live.updatedAt.toIso8601String(),
          },
          extraHeaders: {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
          returnRepresentation: false,
        );
        return;
      }
    } catch (e) {
      debugPrint('GpsService postgrest live: $e');
    }

    try {
      final uid = int.tryParse(live.userId);
      if (uid == null) return;
      final pg = await PostgresService.getInstance();
      await pg.updateLiveLocation(
        userId: uid,
        latitude: live.latitude,
        longitude: live.longitude,
        accuracy: live.accuracy,
      );
    } catch (e) {
      debugPrint('GpsService postgres live: $e');
    }
  }

  Future<bool> isWithinVisitRange(double targetLat, double targetLng) async {
    final settings = await _geofenceStore.load();
    if (!settings.enabled) return true;

    final pos = await getCurrentPosition();
    if (pos == null) {
      return !settings.failClosed;
    }

    final distance = haversineMeters(
      pos.latitude,
      pos.longitude,
      targetLat,
      targetLng,
    );
    return distance <= settings.radiusMeters;
  }
}
