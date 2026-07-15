import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:exfin_ops/service/postgres_service.dart';
import 'package:exfin_ops/service/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:exfin_ops/service/geofence_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  Future<void> initialize() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
  }

  /// Initializes the background service for location tracking
  static Future<void> initializeBackgroundService() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('Background service is only supported on Android and iOS.');
      return;
    }
    
    // Create the background notification channel explicitly to prevent Android 14+ BadNotification crash
    if (Platform.isAndroid) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidNotificationChannel = AndroidNotificationChannel(
        'exfin_ops_location', // id
        'EXFINOPS Konum Takibi', // name
        description: 'Arka planda konum takip ediliyor...',
        importance: Importance.low, // importance must be at low or higher level
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'exfin_ops_location',
        initialNotificationTitle: 'EXFINOPS Konum Takibi',
        initialNotificationContent: 'Arka planda konum takip ediliyor...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Background Tracking Logic
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        
        // Broadcast for UI listeners if app is open
        service.invoke('update', {
          "latitude": position.latitude,
          "longitude": position.longitude,
          "accuracy": position.accuracy,
          "recordedAt": DateTime.now().toIso8601String(),
        });

        // In a real production app, we would also trigger a light sync here
        debugPrint('Background Location Update: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Background Location Error: $e');
      }
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  Future<void> startTracking(String userId) async {
    if (_isTracking) return;
    _isTracking = true;

    // Start UI-level tracking
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        await _handleLocationUpdate(userId, position);
      },
      onError: (e) => debugPrint('Location Stream Error: $e')
    );

    // Also wake up background service
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _isTracking = false;
    
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  Future<void> _handleLocationUpdate(String userId, Position position) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      
      await db.insert('location_history', {
        'id': const Uuid().v4(),
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'recorded_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });

      final postgre = await PostgresService.getInstance();
      await postgre.query('''
        INSERT INTO live_locations (user_id, latitude, longitude, updated_at)
        VALUES (@user_id, @latitude, @longitude, NOW())
        ON CONFLICT (user_id) DO UPDATE SET 
          latitude = EXCLUDED.latitude, 
          longitude = EXCLUDED.longitude, 
          updated_at = NOW()
      ''', params: {
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      // 3. Geofence Check
      await GeofenceService().checkProximity(position, userId);
    } catch (e) {
      debugPrint('Error handling location update: $e');
    }
  }
}
