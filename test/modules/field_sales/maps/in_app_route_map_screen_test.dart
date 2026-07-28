// Dosya Adı: in_app_route_map_screen_test.dart
// Açıklama: Uygulama içi rota haritası dens smoke (enjekte noktalar)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/route_visit_point.dart';
import 'package:exfin_ops/modules/field_sales/maps/view/in_app_route_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ensureStubL10nLoaded();
  });

  testWidgets('InAppRouteMapScreen polyline noktaları ile açılır',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const points = [
      RouteVisitPoint(
        id: '1',
        routeId: 'r',
        customerId: 'c1',
        visitOrder: 1,
        customerName: 'A',
        latitude: 36.19,
        longitude: 44.01,
      ),
      RouteVisitPoint(
        id: '2',
        routeId: 'r',
        customerId: 'c2',
        visitOrder: 2,
        customerName: 'B',
        latitude: 36.20,
        longitude: 44.02,
      ),
    ];

    await pumpStubWithL10n(
      tester,
      const InAppRouteMapScreen(points: points),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(InAppRouteMapScreen), findsOneWidget);
    expect(find.textContaining('km'), findsWidgets);
  });

  testWidgets('boş noktalarda empty mesajı', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      const InAppRouteMapScreen(points: []),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('ziyaret'), findsWidgets);
  });
}
