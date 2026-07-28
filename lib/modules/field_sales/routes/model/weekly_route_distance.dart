// Dosya Adı: weekly_route_distance.dart
// Açıklama: Haftalık rota — başlangıç noktasından en yakın→en uzak Haversine sıralama
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:math' as math;

import 'weekly_route_stop.dart';

/// {@template weekly_route_geo_point}
/// Lat/long başlangıç veya durak noktası.
///
/// Kullanım örneği:
/// ```dart
/// const p = WeeklyRouteGeoPoint(lat: 36.19, lng: 44.00);
/// ```
/// {@endtemplate}
class WeeklyRouteGeoPoint {
  /// [lat]: Enlem
  final double lat;

  /// [lng]: Boylam
  final double lng;

  /// {@macro weekly_route_geo_point}
  const WeeklyRouteGeoPoint({required this.lat, required this.lng});
}

/// {@template weekly_route_distance_sort_result}
/// Mesafeye göre sıralama özeti (UI SnackBar).
/// {@endtemplate}
class WeeklyRouteDistanceSortResult {
  /// [ordered]: Yeni sıra (visitOrder henüz persist edilmemiş olabilir)
  final List<WeeklyRouteStop> ordered;

  /// [missingCoordsCount]: Koordinatsız (listenin sonuna alınan) durak sayısı
  final int missingCoordsCount;

  /// {@macro weekly_route_distance_sort_result}
  const WeeklyRouteDistanceSortResult({
    required this.ordered,
    required this.missingCoordsCount,
  });
}

/// {@template weekly_route_distance}
/// Saf mesafe yardımcıları — UI / SQLite bağımlılığı yok.
///
/// Varsayım: Sıralama başlangıcı = cihaz GPS (veya enjekte origin).
/// Ambar tablosunda lat/long yok; depo kökeni henüz desteklenmiyor.
///
/// Kullanım örneği:
/// ```dart
/// final r = WeeklyRouteDistance.sortNearestToFarthest(
///   stops,
///   origin: WeeklyRouteGeoPoint(lat: 36.2, lng: 44.0),
/// );
/// ```
/// {@endtemplate}
class WeeklyRouteDistance {
  const WeeklyRouteDistance._();

  /// Dünya yarıçapı (km) — Haversine
  static const double earthRadiusKm = 6371.0;

  /// {@template weekly_route_distance_haversine}
  /// İki nokta arası yaklaşık km mesafe.
  ///
  /// Parametreler:
  /// - [a]: Başlangıç
  /// - [b]: Hedef
  ///
  /// Dönüş değeri:
  /// - [double]: km
  /// {@endtemplate}
  static double haversineKm(WeeklyRouteGeoPoint a, WeeklyRouteGeoPoint b) {
    final p = math.pi / 180.0;
    final dLat = (b.lat - a.lat) * p;
    final dLng = (b.lng - a.lng) * p;
    final lat1 = a.lat * p;
    final lat2 = b.lat * p;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  /// {@template weekly_route_distance_sort}
  /// Durakları origin'e göre en yakından en uzağa sıralar.
  /// Koordinatsız cariler listenin sonuna alınır (mevcut göreli sıra korunur).
  ///
  /// Parametreler:
  /// - [stops]: Kaynak duraklar
  /// - [origin]: Başlangıç (GPS / enjekte nokta)
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteDistanceSortResult]: Sıralı liste + eksik koordinat sayısı
  /// {@endtemplate}
  static WeeklyRouteDistanceSortResult sortNearestToFarthest(
    List<WeeklyRouteStop> stops, {
    required WeeklyRouteGeoPoint origin,
  }) {
    if (stops.isEmpty) {
      return const WeeklyRouteDistanceSortResult(
        ordered: [],
        missingCoordsCount: 0,
      );
    }

    final withCoords = <WeeklyRouteStop>[];
    final withoutCoords = <WeeklyRouteStop>[];
    for (final s in stops) {
      if (s.hasCoords) {
        withCoords.add(s);
      } else {
        withoutCoords.add(s);
      }
    }

    withCoords.sort((a, b) {
      final da = haversineKm(
        origin,
        WeeklyRouteGeoPoint(lat: a.latitude!, lng: a.longitude!),
      );
      final db = haversineKm(
        origin,
        WeeklyRouteGeoPoint(lat: b.latitude!, lng: b.longitude!),
      );
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
      return a.visitOrder.compareTo(b.visitOrder);
    });

    return WeeklyRouteDistanceSortResult(
      ordered: [...withCoords, ...withoutCoords],
      missingCoordsCount: withoutCoords.length,
    );
  }
}
