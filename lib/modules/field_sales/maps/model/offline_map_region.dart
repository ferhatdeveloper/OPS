// Dosya Adı: offline_map_region.dart
// Açıklama: İsteğe bağlı offline harita bölgesi (bbox + zoom aralığı)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:math' as math;

/// {@template offline_map_region}
/// OSM tabanlı raster karo indirme için WGS84 sınır kutusu (Carto CDN).
///
/// Kullanım örneği:
/// ```dart
/// final n = OfflineMapRegion.presets.first.estimateTileCount();
/// ```
/// {@endtemplate}
class OfflineMapRegion {
  /// [id]: Kalıcı kimlik (dizin / SharedPreferences)
  final String id;

  /// [nameKey]: l10n anahtarı (`field_sales.offline_maps.regions.*`)
  final String nameKey;

  /// [south]: Güney enlem
  final double south;

  /// [west]: Batı boylam
  final double west;

  /// [north]: Kuzey enlem
  final double north;

  /// [east]: Doğu boylam
  final double east;

  /// [minZoom]: İndirme alt zoom (dahil)
  final int minZoom;

  /// [maxZoom]: İndirme üst zoom (dahil)
  final int maxZoom;

  /// {@macro offline_map_region}
  const OfflineMapRegion({
    required this.id,
    required this.nameKey,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    this.minZoom = 12,
    this.maxZoom = 14,
  });

  /// Merkez nokta (harita odak)
  ({double lat, double lon}) get center => (
        lat: (south + north) / 2,
        lon: (west + east) / 2,
      );

  /// Yaklaşık karo sayısı (indirme öncesi uyarı)
  int estimateTileCount() {
    var total = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      final x0 = lonToTileX(west, z);
      final x1 = lonToTileX(east, z);
      final y0 = latToTileY(north, z);
      final y1 = latToTileY(south, z);
      final xMin = math.min(x0, x1);
      final xMax = math.max(x0, x1);
      final yMin = math.min(y0, y1);
      final yMax = math.max(y0, y1);
      total += (xMax - xMin + 1) * (yMax - yMin + 1);
    }
    return total;
  }

  /// Bölge karo koordinatları (z, x, y)
  Iterable<({int z, int x, int y})> tileCoordinates() sync* {
    for (var z = minZoom; z <= maxZoom; z++) {
      final x0 = lonToTileX(west, z);
      final x1 = lonToTileX(east, z);
      final y0 = latToTileY(north, z);
      final y1 = latToTileY(south, z);
      final xMin = math.min(x0, x1);
      final xMax = math.max(x0, x1);
      final yMin = math.min(y0, y1);
      final yMax = math.max(y0, y1);
      for (var x = xMin; x <= xMax; x++) {
        for (var y = yMin; y <= yMax; y++) {
          yield (z: z, x: x, y: y);
        }
      }
    }
  }

  /// Lon → slippy map X
  static int lonToTileX(double lon, int zoom) {
    final n = math.pow(2.0, zoom);
    return ((lon + 180.0) / 360.0 * n).floor().clamp(0, n.toInt() - 1);
  }

  /// Lat → slippy map Y
  static int latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = math.pow(2.0, zoom);
    final y = (1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        n;
    return y.floor().clamp(0, n.toInt() - 1);
  }

  /// Saha satış için hazır bölgeler (~15 km kutu, z12–14)
  static const List<OfflineMapRegion> presets = [
    OfflineMapRegion(
      id: 'istanbul_eu',
      nameKey: 'field_sales.offline_maps.regions.istanbul_eu',
      south: 40.95,
      west: 28.90,
      north: 41.10,
      east: 29.05,
    ),
    OfflineMapRegion(
      id: 'ankara_center',
      nameKey: 'field_sales.offline_maps.regions.ankara_center',
      south: 39.85,
      west: 32.75,
      north: 40.00,
      east: 32.95,
    ),
    OfflineMapRegion(
      id: 'erbil_center',
      nameKey: 'field_sales.offline_maps.regions.erbil_center',
      south: 36.12,
      west: 43.95,
      north: 36.28,
      east: 44.12,
    ),
    OfflineMapRegion(
      id: 'baghdad_center',
      nameKey: 'field_sales.offline_maps.regions.baghdad_center',
      south: 33.25,
      west: 44.30,
      north: 33.40,
      east: 44.50,
    ),
  ];
}
