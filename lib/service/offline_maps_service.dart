// Dosya Adı: offline_maps_service.dart
// Açıklama: Offline harita — OfflineMapTileStore köprüsü (eski API uyumu)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';

import '../modules/field_sales/maps/model/offline_map_region.dart';
import '../modules/field_sales/maps/viewmodel/offline_map_tile_store.dart';
import 'notification_service.dart';

/// Harita sağlayıcı (çevrimiçi Carto / yerel karo)
enum MapProvider { osmOnline, offlineTiles }

/// {@template offline_maps_service}
/// İsteğe bağlı bölge indirme köprüsü — MVP raster karo.
/// Sesli turn-by-turn yok; harita çizgisi + offline karo.
/// {@endtemplate}
class OfflineMapsService {
  static final OfflineMapsService _instance = OfflineMapsService._internal();

  factory OfflineMapsService() => _instance;

  OfflineMapsService._internal();

  /// [tileStore]: Gerçek karo deposu
  final OfflineMapTileStore tileStore = const OfflineMapTileStore(
    delayBetweenTiles: Duration(milliseconds: 40),
  );

  MapProvider _currentProvider = MapProvider.osmOnline;

  /// Bölge adına göre preset bulur (dashboard uyumu)
  OfflineMapRegion? resolveRegionByName(String regionName) {
    final q = regionName.toLowerCase();
    for (final r in OfflineMapRegion.presets) {
      final matchBaghdad =
          (q.contains('bağdat') || q.contains('baghdad')) &&
              r.id == 'baghdad_center';
      if (r.id.contains(q) ||
          r.nameKey.toLowerCase().contains(q) ||
          (q.contains('istanbul') && r.id == 'istanbul_eu') ||
          (q.contains('ankara') && r.id == 'ankara_center') ||
          (q.contains('erbil') && r.id == 'erbil_center') ||
          matchBaghdad) {
        return r;
      }
    }
    return OfflineMapRegion.presets.first;
  }

  /// İsteğe bağlı bölge indirme
  Future<void> downloadRegion(String regionName) async {
    final region = resolveRegionByName(regionName);
    if (region == null) return;

    debugPrint('OfflineMaps: Starting download for ${region.id}...');
    await tileStore.downloadRegion(region);
    debugPrint('OfflineMaps: ${region.id} downloaded successfully.');

    try {
      await NotificationService().showNotification(
        id: 600,
        title: 'Harita İndirildi',
        body: '${region.id} bölgesi çevrimdışı kullanım için hazır.',
      );
    } catch (_) {
      // Bildirim opsiyonel
    }
  }

  /// Bağlantıya göre sağlayıcı ipucu
  Future<void> updateProvider(bool isOnline) async {
    final hasOffline = await tileStore.hasAnyOfflineTiles();
    if (isOnline) {
      _currentProvider = MapProvider.osmOnline;
    } else if (hasOffline) {
      _currentProvider = MapProvider.offlineTiles;
      debugPrint('OfflineMaps: Offline tiles available.');
    }
  }

  /// Uygulama içi yol — polyline MVP; sesli TBT yok
  Future<void> startNavigation({
    required double destLat,
    required double destLng,
    String? instruction,
  }) async {
    debugPrint(
      'OfflineMaps: In-app route target $destLat,$destLng '
      '(polyline only; no voice TBT). $instruction',
    );
  }

  MapProvider get currentProvider => _currentProvider;

  Future<bool> get hasOfflineData => tileStore.hasAnyOfflineTiles();
}
