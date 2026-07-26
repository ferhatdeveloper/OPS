// Dosya Adı: shelf_audit_dens_form_test.dart
// Açıklama: Raf denetimi dens form widget smoke testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/surveys/view/shelf_audit_screen.dart';
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
    'ShelfAuditScreen dens alanları ve Kaydet görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(tester, const ShelfAuditScreen());
      await tester.pumpAndSettle();

      expect(find.text('Raf Denetimi'), findsOneWidget);
      expect(find.text('Kategori / Raf'), findsWidgets);
      expect(find.text('Marka'), findsWidgets);
      expect(find.text('Facing Adedi'), findsWidgets);
      expect(find.text('Kaydet'), findsOneWidget);
    },
  );
}
