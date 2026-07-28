// Dosya Adı: bank_card_list_screen_test.dart
// Açıklama: Banka Kart Listesi dens smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/bank_card_list_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('master dens: kod + TL/USD/IQD', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(tester, const BankCardListScreen());

    expect(find.text('Banka Kart Listesi'), findsOneWidget);
    expect(find.text('102 01 01'), findsOneWidget);
    expect(find.textContaining('TL'), findsWidgets);
  });
}
