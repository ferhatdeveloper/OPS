// Dosya Adı: delivery_queue_tabs_test.dart
// Açıklama: P0-13 teslimat kuyruk 1-SATIŞ / 2-ALIŞ dens smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_hold_screen.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_untransferred_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('DeliveryListScreen 1-SATIŞ / 2-ALIŞ sekmeleri', (tester) async {
    await pumpStubWithL10n(tester, const DeliveryListScreen());
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.text('0 Adet'), findsOneWidget);

    await tester.tap(find.text('2-ALIŞ'));
    await tester.pumpAndSettle();
    expect(find.text('2-ALIŞ'), findsOneWidget);
  });

  testWidgets('DeliveryHoldScreen dens kuyruk', (tester) async {
    await pumpStubWithL10n(tester, const DeliveryHoldScreen());
    expectStubL10nSmoke(tester, 'field_sales.stubs.delivery_hold');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('Başlangıç'), findsOneWidget);
    expect(find.text('Bitiş'), findsOneWidget);
  });

  testWidgets('DeliveryUntransferredScreen dens kuyruk', (tester) async {
    await pumpStubWithL10n(tester, const DeliveryUntransferredScreen());
    expectStubL10nSmoke(tester, 'field_sales.stubs.delivery_untransferred');
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
