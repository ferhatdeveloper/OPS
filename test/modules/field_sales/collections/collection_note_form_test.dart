// Dosya Adı: collection_note_form_test.dart
// Açıklama: Tahsilat girişinde Senet (Note) seçilince note_* alanlarının görünümü
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
    'Senet (Note) seçilince note_details / note_number / note_bank_name görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(customerId: 'C-NOTE-1'),
        ),
      );

      expect(find.text('Senet Detayları'), findsNothing);

      await tester.tap(find.text('Senet'));
      await tester.pumpAndSettle();

      expect(find.text('Senet Detayları'), findsOneWidget);
      expect(find.text('Senet Numarası'), findsOneWidget);
      expect(find.text('Banka Adı'), findsOneWidget);
      expect(find.text('Vade Tarihi'), findsOneWidget);
      // Çek formu şubesi senette yok
      expect(find.text('Şube Adı'), findsNothing);
    },
  );
}
