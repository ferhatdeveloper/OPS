import 'package:flutter/foundation.dart';
import 'notification_service.dart';

enum MapProvider { google, offlineSdk }

class OfflineMapsService {
  static final OfflineMapsService _instance = OfflineMapsService._internal();
  factory OfflineMapsService() => _instance;
  OfflineMapsService._internal();

  bool _isMapDownloaded = false;
  MapProvider _currentProvider = MapProvider.google;

  /// Simulates downloading a map region for offline use
  Future<void> downloadRegion(String regionName) async {
    debugPrint('OfflineMaps: Starting download for \$regionName...');
    
    // In a real implementation (e.g. Magic Lane or Mapbox), 
    // we would call the SDK's download manager.
    await Future.delayed(const Duration(seconds: 3));
    
    _isMapDownloaded = true;
    debugPrint('OfflineMaps: \$regionName downloaded successfully.');
    
    NotificationService().showNotification(
      id: 600,
      title: '🗺️ Harita İndirildi',
      body: '\$regionName bölgesi çevrimdışı kullanım için hazır.',
    );
  }

  /// Switches provider based on internet connectivity
  void updateProvider(bool isOnline) {
    if (isOnline) {
      _currentProvider = MapProvider.google;
    } else if (_isMapDownloaded) {
      _currentProvider = MapProvider.offlineSdk;
      debugPrint('OfflineMaps: Connection lost. Switching to Offline Navigation.');
    }
  }

  /// Calculates a route using the current provider
  Future<void> startNavigation({
    required double destLat,
    required double destLng,
    String? instruction,
  }) async {
    if (_currentProvider == MapProvider.offlineSdk) {
      debugPrint('OfflineMaps: Local routing calculated for \$destLat, \$destLng');
      // Trigger offline voice guidance mock
      _playVoiceInstruction('500 metre sonra sağa dönün.');
    } else {
      debugPrint('OfflineMaps: Google Maps Navigation started.');
    }
  }

  void _playVoiceInstruction(String text) {
    debugPrint('TTS (Offline): \$text');
  }

  MapProvider get currentProvider => _currentProvider;
  bool get hasOfflineData => _isMapDownloaded;
}
