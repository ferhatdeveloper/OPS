// Dosya Adı: batch_expiry_dens_test.dart
// Açıklama: Parti / SKT dens liste smoke (lot + SKT satırları)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/stock/model/batch_expiry_seed.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/batch_expiry_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('BatchExpiryScreen dens lot/SKT alanları', (tester) async {
    await pumpStubWithL10n(
      tester,
      BatchExpiryScreen(records: BatchExpirySeed.defaultRows),
    );
    await tester.pump();
    expectStubL10nSmoke(tester, 'field_sales.stubs.batch_expiry');
    expect(find.byType(TextField), findsOneWidget);

    final first = BatchExpirySeed.defaultRows.first;
    expect(find.textContaining(first.productCode), findsWidgets);
    expect(find.textContaining(first.lotNo), findsWidgets);
    expect(find.textContaining('Parti'), findsWidgets);
    expect(find.textContaining('SKT'), findsWidgets);
  });
}
