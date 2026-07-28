// Dosya Adı: cash_card_detail_screen_test.dart
// Açıklama: Kasa hareket detay dens smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/cash_card_detail_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('detay dens: Dizayn Dosya + kolon başlıkları', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      const CashCardDetailScreen(cashCode: '100 01 01'),
    );

    expect(find.text('Kasa Hareketleri'), findsOneWidget);
    expect(find.textContaining('100 01 01'), findsOneWidget);
    expect(find.text('Dizayn Dosya'), findsOneWidget);
    expect(find.text('Tarih'), findsOneWidget);
    expect(find.text('İşlem'), findsOneWidget);
    expect(find.text('Evrak No'), findsOneWidget);
  });
}
