// Dosya Adı: cash_card_picker_dens_test.dart
// Açıklama: Nakit Kasa Kodu → CashCardList dens seçici widget testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_master.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/cash_card_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collection_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/cash_card_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// Dens smoke: master seed satırları (DB yok).
class _DensSeedStore extends CashCardStore {
  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<CashCardRecord>> listActive() async {
    return CashCardSeed.defaultMaps
        .map(CashCardRecord.fromMap)
        .toList(growable: false);
  }
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'CashCardList dens master satırları ve Seç gösterir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        CashCardListScreen(
          selectionMode: true,
          store: _DensSeedStore(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Kasa Kart Listesi'), findsOneWidget);
      expect(find.text('100 01 01'), findsOneWidget);
      expect(find.text('MERKEZ TL KASA'), findsOneWidget);
      expect(find.text('MERKEZ USD KASA'), findsOneWidget);
      expect(find.text('ŞUBE TL KASA'), findsOneWidget);
      expect(find.text('Seç'), findsOneWidget);
    },
  );

  testWidgets(
    'Nakit Kasa Kodu readOnly; seçim safe_code yazar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(customerId: 'C-CASH-PICK'),
        ),
      );

      expect(find.text('Kasa Kodu'), findsOneWidget);

      // Kasa Kodu dens alanına tap → liste
      final cashFieldFinder = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Kasa Kodu',
      );
      expect(cashFieldFinder, findsOneWidget);
      await tester.ensureVisible(cashFieldFinder);

      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('ink_sparkle')) {
          return;
        }
        previousOnError?.call(details);
      };
      try {
        await tester.tap(cashFieldFinder);
        await tester.pumpAndSettle();

        expect(find.text('Kasa Kart Listesi'), findsOneWidget);
        expect(find.text('MERKEZ EURO KASA'), findsOneWidget);

        // EURO satırını seç
        await tester.tap(find.text('MERKEZ EURO KASA'));
        await tester.pump();
        await tester.tap(find.text('Seç'));
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previousOnError;
      }

      expect(find.text('Kasa Kart Listesi'), findsNothing);

      final cashFields = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Kasa Kodu',
      );
      expect(cashFields, findsOneWidget);
      final field = tester.widget<TextField>(cashFields);
      expect(field.controller?.text, CashCardMaster.codes[2]);
      expect(field.readOnly, isTrue);
    },
  );
}
