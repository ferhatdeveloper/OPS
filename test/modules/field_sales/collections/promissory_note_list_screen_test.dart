// Dosya Adı: promissory_note_list_screen_test.dart
// Açıklama: Senet Listesi dens smoke — toplam/adet
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/promissory_list_row.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/promissory_list_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/promissory_list_status.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/promissory_note_list_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('seed dens: senet no + toplam', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(tester, const PromissoryNoteListScreen());

    expect(find.text('Senet Listesi'), findsOneWidget);
    final collateral = PromissoryListSeed.defaultRows
        .where((r) => r.status == PromissoryListStatus.collateral)
        .toList();
    expect(collateral, isNotEmpty);
    expect(find.text(collateral.first.noteNumber), findsOneWidget);
    expect(
      find.textContaining(
        PromissoryListRow.formatAmount(
          PromissoryListRow.totalAmount(collateral),
        ),
      ),
      findsWidgets,
    );
  });
}
