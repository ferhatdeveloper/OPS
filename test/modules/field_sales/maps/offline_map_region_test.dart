// Dosya Adı: offline_map_region_test.dart
// Açıklama: OfflineMapRegion karo sayımı / koordinat birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/maps/model/offline_map_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineMapRegion', () {
    test('presets dolu ve id benzersiz', () {
      final ids = OfflineMapRegion.presets.map((r) => r.id).toSet();
      expect(OfflineMapRegion.presets, isNotEmpty);
      expect(ids.length, OfflineMapRegion.presets.length);
    });

    test('küçük bbox tile sayısı makul (< 2000)', () {
      const tiny = OfflineMapRegion(
        id: 'tiny',
        nameKey: 'x',
        south: 41.00,
        west: 29.00,
        north: 41.02,
        east: 29.02,
        minZoom: 12,
        maxZoom: 14,
      );
      final n = tiny.estimateTileCount();
      expect(n, greaterThan(0));
      expect(n, lessThan(2000));
      expect(tiny.tileCoordinates().length, n);
    });

    test('lonToTileX / latToTileY aralık içinde', () {
      final x = OfflineMapRegion.lonToTileX(29.0, 12);
      final y = OfflineMapRegion.latToTileY(41.0, 12);
      expect(x, inInclusiveRange(0, 4095));
      expect(y, inInclusiveRange(0, 4095));
    });

    test('erbil preset merkez Irak civarı', () {
      final erbil = OfflineMapRegion.presets
          .firstWhere((r) => r.id == 'erbil_center');
      expect(erbil.center.lat, closeTo(36.2, 0.2));
      expect(erbil.center.lon, closeTo(44.0, 0.2));
    });
  });
}
