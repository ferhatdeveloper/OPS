// Dosya Adı: virman_cash_card_picker_test.dart
// Açıklama: Virman kaynak/hedef → CashCardMaster dens seçici widget testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_master.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/virman_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'Virman kaynak/hedef readOnly; seçim safe_code yazar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(child: VirmanScreen()),
      );

      expect(find.text('Virman'), findsOneWidget);
      expect(find.text('Kaynak Kasa/Hesap'), findsOneWidget);
      expect(find.text('Hedef Kasa/Hesap'), findsOneWidget);

      final fromFieldFinder = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Kaynak Kasa/Hesap',
      );
      expect(fromFieldFinder, findsOneWidget);
      expect(tester.widget<TextField>(fromFieldFinder).readOnly, isTrue);

      await tester.ensureVisible(fromFieldFinder);
      await tester.tap(fromFieldFinder);
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsOneWidget);
      expect(find.text('MERKEZ EURO KASA'), findsOneWidget);

      await tester.tap(find.text('MERKEZ EURO KASA'));
      await tester.pump();
      await tester.tap(find.text('Seç'));
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsNothing);

      final fromField = tester.widget<TextField>(fromFieldFinder);
      expect(fromField.controller?.text, CashCardMaster.codes[2]);

      final toFieldFinder = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Hedef Kasa/Hesap',
      );
      expect(toFieldFinder, findsOneWidget);
      expect(tester.widget<TextField>(toFieldFinder).readOnly, isTrue);

      await tester.ensureVisible(toFieldFinder);
      await tester.tap(toFieldFinder);
      await tester.pumpAndSettle();

      expect(find.text('Kasa Kart Listesi'), findsOneWidget);
      await tester.tap(find.text('ŞUBE TL KASA'));
      await tester.pump();
      await tester.tap(find.text('Seç'));
      await tester.pumpAndSettle();

      final toField = tester.widget<TextField>(toFieldFinder);
      expect(toField.controller?.text, CashCardMaster.codes[3]);
    },
  );
}
