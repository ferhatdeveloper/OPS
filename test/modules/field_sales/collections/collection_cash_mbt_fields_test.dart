// Dosya Adı: collection_cash_mbt_fields_test.dart
// Açıklama: Nakit seçilince MBT dens alan etiketlerinin görünümü
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
    'Nakit (Cash) varsayılanında kasa/tutar/plasiyer/açıklama dens görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(customerId: 'C-CASH-1'),
        ),
      );

      expect(find.text('Nakit Tahsilat'), findsOneWidget);
      expect(find.text('İşlem Dövizi'), findsOneWidget);
      expect(find.text('Evrak No'), findsOneWidget);
      expect(find.text('Kasa Kodu'), findsOneWidget);
      expect(find.text('Açıklama'), findsOneWidget);
      expect(find.text('Tutar'), findsOneWidget);
      expect(find.text('Plasiyer Kodu'), findsOneWidget);
      expect(find.text('Özel Kod 1'), findsOneWidget);
      // Nakit'te genel notlar kartı yok
      expect(find.text('Notlar (Opsiyonel)'), findsNothing);
    },
  );

  testWidgets(
    'Plasiyer alanı initialSalespersonCode ile ön-doldurulur',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(
            customerId: 'C-CASH-PLS',
            initialSalespersonCode: 'PLS01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLS01'), findsOneWidget);
    },
  );

  testWidgets(
    'KK seçilince nakit dens alanları gizlenir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(customerId: 'C-CASH-2'),
        ),
      );

      await tester.tap(find.text('Kredi Kartı'));
      await tester.pumpAndSettle();

      expect(find.text('Nakit Tahsilat'), findsNothing);
      expect(find.text('Notlar (Opsiyonel)'), findsOneWidget);
    },
  );
}
