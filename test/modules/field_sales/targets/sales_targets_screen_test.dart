// Dosya Adı: sales_targets_screen_test.dart
// Açıklama: Satış hedefleri dens ekran widget smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/targets/model/sales_target_seed.dart';
import 'package:exfin_ops/modules/field_sales/targets/view/sales_targets_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('SalesTargetsScreen dens boş state', (tester) async {
    await pumpStubWithL10n(
      tester,
      const SalesTargetsScreen(initialRows: []),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.sales_targets');
    expectStubL10nSmoke(tester, 'field_sales.sales_targets.empty');
  });

  testWidgets('SalesTargetsScreen dens seed satırları', (tester) async {
    await pumpStubWithL10n(
      tester,
      SalesTargetsScreen(initialRows: SalesTargetSeed.defaultRows),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.sales_targets');
    expectStubL10nSmoke(tester, 'field_sales.sales_targets.list_hint');
    expectStubL10nSmoke(tester, 'field_sales.sales_targets.col_personnel');
    expect(find.text('Ahmet Yılmaz'), findsWidgets);
    expect(find.textContaining('180000'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
  });
}
