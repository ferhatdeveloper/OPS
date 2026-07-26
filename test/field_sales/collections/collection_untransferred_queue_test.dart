// Dosya Adı: collection_untransferred_queue_test.dart
// Açıklama: Transfer edilmeyen tahsilat dens → kuyruk smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/collections/model/collection_untransferred_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collections_untransferred_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets(
    'CollectionsUntransferredScreen dens kuyruk sekmeleri + seed',
    (tester) async {
      await pumpStubWithL10n(
        tester,
        const CollectionsUntransferredScreen(),
      );
      expectStubL10nSmoke(
        tester,
        'field_sales.stubs.collections_untransferred',
      );
      expect(find.text('1-SATIŞ'), findsOneWidget);
      expect(find.text('2-ALIŞ'), findsOneWidget);
      expect(find.text('Bu Ay'), findsOneWidget);
      expect(find.text('Başlangıç'), findsOneWidget);
      expect(find.text('Bitiş'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      final sales = CollectionUntransferredSeed.salesRows;
      expect(sales, isNotEmpty);
      expect(find.text(sales.first.documentNo), findsOneWidget);
    },
  );
}
