// Dosya Adı: weekly_route_distance_test.dart
// Açıklama: Haftalık rota mesafe sıralama (yakın→uzak) birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/routes/model/weekly_route_distance.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/weekly_route_stop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyRouteDistance', () {
    const origin = WeeklyRouteGeoPoint(lat: 36.20, lng: 44.00);

    WeeklyRouteStop stop({
      required String id,
      required int order,
      double? lat,
      double? lng,
    }) {
      return WeeklyRouteStop(
        id: id,
        routeId: 'r1',
        customerId: id,
        visitOrder: order,
        dayOfWeek: 1,
        customerName: id,
        latitude: lat,
        longitude: lng,
      );
    }

    test('en yakından en uzağa sıralar; koordinatsız sonda', () {
      final far = stop(id: 'far', order: 1, lat: 36.50, lng: 44.00);
      final near = stop(id: 'near', order: 2, lat: 36.21, lng: 44.00);
      final mid = stop(id: 'mid', order: 3, lat: 36.30, lng: 44.00);
      final none = stop(id: 'none', order: 4);

      final result = WeeklyRouteDistance.sortNearestToFarthest(
        [far, near, mid, none],
        origin: origin,
      );

      expect(
        result.ordered.map((s) => s.id).toList(),
        ['near', 'mid', 'far', 'none'],
      );
      expect(result.missingCoordsCount, 1);
    });

    test('0,0 koordinat geçersiz sayılır', () {
      final zero = stop(id: 'z', order: 1, lat: 0, lng: 0);
      final ok = stop(id: 'ok', order: 2, lat: 36.22, lng: 44.01);
      final result = WeeklyRouteDistance.sortNearestToFarthest(
        [zero, ok],
        origin: origin,
      );
      expect(result.ordered.map((s) => s.id).toList(), ['ok', 'z']);
      expect(result.missingCoordsCount, 1);
    });

    test('haversine simetrik ve pozitif', () {
      const a = WeeklyRouteGeoPoint(lat: 36.2, lng: 44.0);
      const b = WeeklyRouteGeoPoint(lat: 36.3, lng: 44.1);
      final d1 = WeeklyRouteDistance.haversineKm(a, b);
      final d2 = WeeklyRouteDistance.haversineKm(b, a);
      expect(d1, closeTo(d2, 0.0001));
      expect(d1, greaterThan(0));
    });
  });
}
