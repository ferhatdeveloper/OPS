// Dosya Adı: collection_cc_note_dens_form_test.dart
// Açıklama: KK + senet dens form parity widget testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/init/navigation/routes.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collection_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/credit_card_collection_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/promissory_note_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'CreditCard seçilince cc_details / evrak / POS dens alanları görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CollectionEntryScreen(
            customerId: 'C-CC-1',
            initialPaymentType: 'credit_card',
          ),
        ),
      );

      expect(find.text('Kredi Kartı Detayları'), findsOneWidget);
      expect(find.text('Evrak No'), findsOneWidget);
      expect(find.text('POS / Kasa Kodu'), findsOneWidget);
      expect(find.text('Senet Detayları'), findsNothing);
    },
  );

  testWidgets(
    'KK tahsilat dens formu cari ile tutar + detay alanları gösterir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: CreditCardCollectionScreen(customerId: 'C-CC-2'),
        ),
      );

      expect(find.text('Kredi Kartı Tahsilat'), findsOneWidget);
      expect(find.text('Tahsil Edilecek Tutar'), findsOneWidget);
      expect(find.text('Kredi Kartı Detayları'), findsOneWidget);
      expect(find.text('Evrak No'), findsOneWidget);
      expect(find.text('POS / Kasa Kodu'), findsOneWidget);
      expect(find.text('Tahsilatı Onayla'), findsOneWidget);
    },
  );

  testWidgets(
    'Senet dens formu no / banka / vade alanlarını gösterir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const ProviderScope(
          child: PromissoryNoteScreen(customerId: 'C-NOTE-2'),
        ),
      );

      expect(find.text('Senet'), findsOneWidget);
      expect(find.text('Senet Detayları'), findsOneWidget);
      expect(find.text('Senet Numarası'), findsOneWidget);
      expect(find.text('Banka Adı'), findsOneWidget);
      expect(find.text('Vade Tarihi'), findsOneWidget);
      expect(find.text('Şube Adı'), findsNothing);
    },
  );

  test('cc-collection ve promissory customerFirstRoutes içinde', () {
    expect(
      AppRoutes.customerFirstRoutes.contains(AppRoutes.fieldSalesCcCollection),
      isTrue,
    );
    expect(
      AppRoutes.customerFirstRoutes.contains(AppRoutes.fieldSalesPromissory),
      isTrue,
    );
  });
}
