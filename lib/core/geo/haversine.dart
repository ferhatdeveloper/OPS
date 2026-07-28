// Dosya Adı: haversine.dart
// Açıklama: İki lat/long noktası arası mesafe (metre) — paylaşılan helper
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:math' as math;

/// {@template haversine_meters}
/// Dünya yüzeyinde iki WGS84 noktası arasındaki yaklaşık mesafe (metre).
///
/// Rota sıralama, geofence / proximity ve check-in kontrolleri için
/// ortak yardımcı — Geolocator bağımlılığı yoktur (offline / unit test).
///
/// Kullanım örneği:
/// ```dart
/// final m = haversineMeters(41.01, 28.97, 41.02, 28.98);
/// ```
/// {@endtemplate}
double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusM = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusM * c;
}

/// {@template haversine_km}
/// [haversineMeters] sonucunu kilometreye çevirir.
/// {@endtemplate}
double haversineKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  return haversineMeters(lat1, lon1, lat2, lon2) / 1000.0;
}

double _toRadians(double degrees) => degrees * math.pi / 180.0;
