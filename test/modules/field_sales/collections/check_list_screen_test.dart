// Dosya Adı: check_list_screen_test.dart
// Açıklama: Çek Listesi dens — check tipi satır + toplam/adet
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_row.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_status.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/check_list_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('seed dens: çek no + toplam/adet (tahsile verilen)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(tester, const CheckListScreen());

    expect(find.text('Çek Listesi'), findsOneWidget);
    expect(find.text('Tahsile Verilen Çekler'), findsWidgets);

    // Varsayılan ilk sekme: Teminata Verilen
    final collateral = CheckListSeed.defaultRows
        .where((r) => r.status == CheckListStatus.collateral)
        .toList();
    expect(collateral, isNotEmpty);
    expect(find.text(collateral.first.checkNumber), findsOneWidget);

    final total = CheckListRow.totalAmount(collateral);
    expect(
      find.textContaining(CheckListRow.formatAmount(total)),
      findsWidgets,
    );
    expect(
      find.textContaining('${collateral.length}'),
      findsWidgets,
    );
  });

  testWidgets('yalnız check tipi satırlar listelenir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final rows = [
      CheckListRow(
        id: 'only-check',
        customerId: 'C9',
        amount: 99,
        paymentType: 'check',
        collectionDate: DateTime(2026, 7, 26),
        checkNumber: 'ONLY-CHECK-99',
        status: CheckListStatus.collateral,
        bankName: 'Demo Bank',
      ),
    ];

    await pumpStubWithL10n(
      tester,
      CheckListScreen(rows: rows),
    );

    expect(find.text('ONLY-CHECK-99'), findsOneWidget);
    expect(find.textContaining('Demo Bank'), findsOneWidget);
  });
}
