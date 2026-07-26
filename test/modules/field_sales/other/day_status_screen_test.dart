// Dosya Adı: day_status_screen_test.dart
// Açıklama: DayStatusScreen MBT alanları widget smoke testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/modules/field_sales/eod/view/day_close_screen.dart';
import 'package:exfin_ops/modules/field_sales/eod/view/day_open_screen.dart';
import 'package:exfin_ops/modules/field_sales/other/view/day_status_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'DayStatusScreen MBT alanları ve Kaydet görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(tester, const DayStatusScreen());
      await tester.pumpAndSettle();

      expect(find.text('Plaka'), findsWidgets);
      expect(find.text('Başlangıç KM'), findsWidgets);
      expect(find.text('Bitiş KM'), findsWidgets);
      expect(find.text('Tamamlandı?'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    },
  );

  testWidgets(
    'DayOpenScreen plaka + başlangıç KM + Kaydet gösterir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(tester, const DayOpenScreen());
      await tester.pumpAndSettle();

      expect(find.text('Plaka'), findsWidgets);
      expect(find.text('Başlangıç KM'), findsWidgets);
      expect(find.text('Bitiş KM'), findsNothing);
      expect(find.text('Tamamlandı?'), findsNothing);
      expect(find.text('Kaydet'), findsOneWidget);
    },
  );

  testWidgets(
    'DayCloseScreen bitiş KM + Tamamlandı? + Kaydet gösterir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(tester, const DayCloseScreen());
      await tester.pumpAndSettle();

      expect(find.text('Plaka'), findsWidgets);
      expect(find.text('Bitiş KM'), findsWidgets);
      expect(find.text('Tamamlandı?'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    },
  );

  testWidgets(
    'DayStatusScreen Kaydet plaka/km kaydeder',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(tester, const DayStatusScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '34 MBT 01',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '1000');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Güne başarıyla başlandı.'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('day_status_plate'), '34 MBT 01');
      expect(prefs.getInt('day_status_start_km'), 1000);
      expect(prefs.getBool('day_status_is_started'), isTrue);
    },
  );
}
