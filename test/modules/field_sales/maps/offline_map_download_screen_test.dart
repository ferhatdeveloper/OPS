// Dosya Adı: offline_map_download_screen_test.dart
// Açıklama: Offline harita indirme dens ekran smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/maps/model/offline_map_region.dart';
import 'package:exfin_ops/modules/field_sales/maps/view/offline_map_download_screen.dart';
import 'package:exfin_ops/modules/field_sales/maps/viewmodel/offline_map_tile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ensureStubL10nLoaded();
  });

  testWidgets('OfflineMapDownloadScreen dens liste gösterir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const regions = [
      OfflineMapRegion(
        id: 'r1',
        nameKey: 'field_sales.offline_maps.regions.erbil_center',
        south: 36.1,
        west: 44.0,
        north: 36.2,
        east: 44.1,
        minZoom: 12,
        maxZoom: 12,
      ),
    ];

    await pumpStubWithL10n(
      tester,
      const OfflineMapDownloadScreen(
        regions: regions,
        store: OfflineMapTileStore(delayBetweenTiles: Duration.zero),
      ),
    );

    expect(find.byType(OfflineMapDownloadScreen), findsOneWidget);
    expect(find.textContaining('İndir'), findsWidgets);
    expect(find.textContaining('Erbil'), findsOneWidget);
  });
}
