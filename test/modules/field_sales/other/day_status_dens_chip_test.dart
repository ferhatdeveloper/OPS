// Dosya Adı: day_status_dens_chip_test.dart
// Açıklama: Dashboard mesai dens chip l10n anahtarı ve store okuma testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/modules/field_sales/other/model/day_status_record.dart';
import 'package:exfin_ops/modules/field_sales/other/viewmodel/day_status_store.dart';
import 'package:exfin_ops/modules/field_sales/other/widgets/day_status_dens_chip.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DayStatusDensChip.labelKey', () {
    test('açık mesai doğru anahtar', () {
      expect(
        DayStatusDensChip.labelKey(true),
        'field_sales.day_status_open',
      );
    });

    test('kapalı mesai doğru anahtar', () {
      expect(
        DayStatusDensChip.labelKey(false),
        'field_sales.day_status_closed',
      );
    });
  });

  group('DayStatusDensChip widget', () {
    testWidgets('varsayılan kapalı metni gösterir', (tester) async {
      await pumpStubWithL10n(tester, const DayStatusDensChip());
      await tester.pumpAndSettle();

      expect(find.text('Kapalı'), findsOneWidget);
    });

    testWidgets('mesai açıkken açık metni gösterir', (tester) async {
      final store = DayStatusStore();
      await store.save(
        DayStatusRecord(
          plate: '34 ABC 01',
          startKm: 100,
          isDayStarted: true,
          completed: false,
          startTime: DateTime(2026, 7, 26, 8),
        ),
      );

      await pumpStubWithL10n(
        tester,
        DayStatusDensChip(store: store),
      );
      await tester.pumpAndSettle();

      expect(find.text('Açık'), findsOneWidget);
    });
  });
}
