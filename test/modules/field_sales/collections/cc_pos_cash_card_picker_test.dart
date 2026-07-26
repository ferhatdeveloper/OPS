// Dosya Adı: cc_pos_cash_card_picker_test.dart
// Açıklama: KK POS/Kasa → CashCardMaster dens seçici widget testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_master.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collection_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/credit_card_collection_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/payment_entry_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// {@template _pos_field_finder}
/// POS / Kasa Kodu dens TextField bulucu.
/// {@endtemplate}
Finder _posFieldFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        (w.decoration?.labelText == 'POS / Kasa Kodu' ||
            w.decoration?.hintText == 'POS / Kasa Kodu'),
  );
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'KK tahsilat POS readOnly; seçim CashCardMaster safe_code yazar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CreditCardCollectionScreen(customerId: 'C-CC-POS'),
        ),
      );

      final posField = _posFieldFinder();
      expect(posField, findsOneWidget);
      expect(tester.widget<TextField>(posField).readOnly, isTrue);

      await tester.ensureVisible(posField);
      await tester.tap(posField);
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsOneWidget);
      expect(find.text('MERKEZ EURO KASA'), findsOneWidget);

      await tester.tap(find.text('MERKEZ EURO KASA'));
      await tester.pump();
      await tester.tap(find.text('Seç'));
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsNothing);
      final field = tester.widget<TextField>(_posFieldFinder());
      expect(field.controller?.text, CashCardMaster.codes[2]);
      expect(field.readOnly, isTrue);
    },
  );

  testWidgets(
    'CollectionEntry CreditCard POS → CashCardMaster seçici',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(
            customerId: 'C-CC-POS-ENTRY',
            initialPaymentType: 'credit_card',
          ),
        ),
      );

      final posField = _posFieldFinder();
      expect(posField, findsOneWidget);
      expect(tester.widget<TextField>(posField).readOnly, isTrue);

      await tester.ensureVisible(posField);
      await tester.tap(posField);
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsOneWidget);
      await tester.tap(find.text('ŞUBE TL KASA'));
      await tester.pump();
      await tester.tap(find.text('Seç'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(_posFieldFinder());
      expect(field.controller?.text, CashCardMaster.codes[3]);
    },
  );

  testWidgets(
    'KK Ödeme POS → CashCardMaster seçici',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: PaymentEntryScreen(
            customerId: 'C-CC-POS-PAY',
            initialPaymentType: 'CreditCardOut',
          ),
        ),
      );

      final posField = _posFieldFinder();
      expect(posField, findsOneWidget);
      expect(tester.widget<TextField>(posField).readOnly, isTrue);

      await tester.ensureVisible(posField);
      await tester.tap(posField);
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsOneWidget);
      await tester.tap(find.text('MERKEZ USD KASA'));
      await tester.pump();
      await tester.tap(find.text('Seç'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(_posFieldFinder());
      expect(field.controller?.text, CashCardMaster.codes[1]);
    },
  );
}
