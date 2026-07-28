// Dosya Adı: haversine_test.dart
// Açıklama: Paylaşılan haversine mesafe helper birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/core/geo/haversine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haversineMeters', () {
    test('aynı nokta 0 metre döner', () {
      expect(haversineMeters(41.0, 29.0, 41.0, 29.0), 0);
    });

    test('yaklaşık 111 m kuzey kayması (~0.001 lat)', () {
      final meters = haversineMeters(41.0, 29.0, 41.001, 29.0);
      expect(meters, greaterThan(100));
      expect(meters, lessThan(120));
    });

    test('haversineKm metre / 1000', () {
      final m = haversineMeters(41.0, 29.0, 41.01, 29.0);
      expect(haversineKm(41.0, 29.0, 41.01, 29.0), closeTo(m / 1000, 1e-9));
    });
  });
}
