// Dosya Adı: competitor_survey_dens_form_test.dart
// Açıklama: Rakip anket dens form widget smoke testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/surveys/view/competitor_survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'CompetitorSurveyScreen dens alanları ve Kaydet görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(tester, const CompetitorSurveyScreen());
      await tester.pumpAndSettle();

      expect(find.text('Rakip Anketi'), findsOneWidget);
      expect(find.text('Rakip Marka'), findsWidgets);
      expect(find.text('Rakip Ürün'), findsWidgets);
      expect(find.text('Gözlemlenen Fiyat'), findsWidgets);
      expect(find.text('Kaydet'), findsOneWidget);
    },
  );
}
