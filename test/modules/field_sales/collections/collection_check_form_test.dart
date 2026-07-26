// Dosya Adı: collection_check_form_test.dart
// Açıklama: Tahsilat girişinde Çek seçilince MBT dens alanlarının görünümü
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collection_entry_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'Çek seçilince vade / asıl borçlu / banka / çek no / şube dens görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(customerId: 'C-CHECK-1'),
        ),
      );

      expect(find.text('Çek Detayları'), findsNothing);

      await tester.tap(find.text('Çek'));
      await tester.pumpAndSettle();

      expect(find.text('Çek Detayları'), findsOneWidget);
      expect(find.text('Evrak No'), findsWidgets);
      expect(find.text('Vade Tarihi'), findsOneWidget);
      expect(find.text('Ciro'), findsOneWidget);
      expect(find.text('Asıl Borçlu'), findsOneWidget);
      expect(find.text('Banka Adı'), findsOneWidget);
      expect(find.text('Şube Adı'), findsOneWidget);
      expect(find.text('İşyeri'), findsOneWidget);
      expect(find.text('Çek Numarası'), findsOneWidget);
      expect(find.text('Hesap No'), findsOneWidget);
    },
  );
}
