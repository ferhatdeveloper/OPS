// Dosya Adı: gps_tracking_map_smoke_test.dart
// Açıklama: GPS takip Liste|Harita dens chip + harita smoke
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/gps/model/personnel_live_location.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/personnel_location_trail_point.dart';
import 'package:exfin_ops/modules/field_sales/gps/view/gps_tracking_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  final sampleRows = <PersonnelLiveLocation>[
    PersonnelLiveLocation(
      userId: 'PLS01',
      salespersonCode: 'PLS01',
      displayName: 'Ali Eminönü',
      latitude: 41.0082,
      longitude: 28.9784,
      updatedAt: DateTime(2026, 7, 28, 10, 0),
      accuracy: 12,
    ),
    PersonnelLiveLocation(
      userId: 'PLS02',
      salespersonCode: 'PLS02',
      displayName: 'Veli Beşiktaş',
      latitude: 41.0422,
      longitude: 29.0067,
      updatedAt: DateTime(2026, 7, 28, 10, 5),
      accuracy: 18,
    ),
  ];

  final sampleTrail = <PersonnelLocationTrailPoint>[
    PersonnelLocationTrailPoint(
      id: 'tr1',
      salespersonCode: 'PLS01',
      latitude: 41.0080,
      longitude: 28.9780,
      recordedAt: DateTime(2026, 7, 28, 8, 0),
    ),
    PersonnelLocationTrailPoint(
      id: 'tr2',
      salespersonCode: 'PLS01',
      latitude: 41.0082,
      longitude: 28.9784,
      recordedAt: DateTime(2026, 7, 28, 9, 0),
    ),
  ];

  testWidgets('Liste|Harita chip ve liste satırları', (tester) async {
    await pumpStubWithL10n(
      tester,
      GpsTrackingScreen(records: sampleRows),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.gps_tracking');
    expectStubL10nSmoke(tester, 'field_sales.gps_view_list');
    expectStubL10nSmoke(tester, 'field_sales.gps_view_map');
    expect(find.textContaining('PLS01'), findsWidgets);
    expect(find.textContaining('Ali Eminönü'), findsOneWidget);
  });

  testWidgets('Harita görünümü + seçili trail nokta sayısı', (tester) async {
    await pumpStubWithL10n(
      tester,
      GpsTrackingScreen(
        records: sampleRows,
        injectedTrail: sampleTrail,
        initialMode: GpsTrackingViewMode.map,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expectStubL10nSmoke(tester, 'field_sales.gps_view_map');
    expectStubL10nSmoke(tester, 'field_sales.gps_select_person');

    // İlk kişi chip'ine dokun (yatay filtre)
    final aliChip = find.textContaining('Ali');
    expect(aliChip, findsWidgets);
    await tester.tap(aliChip.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.textContaining('2 konum'),
      findsOneWidget,
    );
    expectStubL10nSmoke(tester, 'field_sales.period_today');
  });
}
