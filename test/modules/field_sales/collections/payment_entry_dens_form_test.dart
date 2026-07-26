// Dosya Adı: payment_entry_dens_form_test.dart
// Açıklama: Nakit/KK ödeme dens alan + tip seçici widget testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/payment_entry_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'Nakit Ödeme varsayılanında dens kasa/döviz/plasiyer alanları görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: PaymentEntryScreen(customerId: 'C-PAY-1'),
        ),
      );

      expect(find.text('Nakit / KK Ödeme'), findsOneWidget);
      expect(find.text('Ödenecek Tutar'), findsOneWidget);
      expect(find.text('Nakit Ödeme'), findsWidgets);
      expect(find.text('İşlem Dövizi'), findsOneWidget);
      expect(find.text('Evrak No'), findsOneWidget);
      expect(find.text('Kasa Kodu'), findsOneWidget);
      expect(find.text('Açıklama'), findsOneWidget);
      expect(find.text('Tutar'), findsOneWidget);
      expect(find.text('Plasiyer Kodu'), findsOneWidget);
      expect(find.text('Özel Kod 1'), findsOneWidget);
      expect(find.text('Kredi Kartı Detayları'), findsNothing);
      expect(find.text('Notlar (Opsiyonel)'), findsNothing);
    },
  );

  testWidgets(
    'KK Ödeme seçilince POS dens alanları görünür, nakit dens gizlenir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: PaymentEntryScreen(
            customerId: 'C-PAY-2',
            initialPaymentType: 'CreditCardOut',
          ),
        ),
      );

      expect(find.text('Kredi Kartı Detayları'), findsOneWidget);
      expect(find.text('Evrak No'), findsOneWidget);
      expect(find.text('POS / Kasa Kodu'), findsOneWidget);
      expect(find.text('Notlar (Opsiyonel)'), findsOneWidget);
      expect(find.text('İşlem Dövizi'), findsNothing);
      expect(find.text('Plasiyer Kodu'), findsNothing);
    },
  );

  testWidgets(
    'Tip değiştirince dens alan seti güncellenir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: PaymentEntryScreen(customerId: 'C-PAY-3'),
        ),
      );

      expect(find.text('İşlem Dövizi'), findsOneWidget);

      await tester.tap(find.text('KK Ödeme'));
      await tester.pumpAndSettle();

      expect(find.text('İşlem Dövizi'), findsNothing);
      expect(find.text('POS / Kasa Kodu'), findsOneWidget);
    },
  );
}
