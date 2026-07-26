// Dosya Adı: orders_pending_dens_test.dart
// Açıklama: Bekleyen siparişler dens kuyruk + ONAY alan smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/orders/model/order_pending_seed.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/orders_pending_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('OrdersPendingScreen dens ONAY / SATIŞ-ALIŞ', (tester) async {
    await pumpStubWithL10n(
      tester,
      OrdersPendingScreen(records: OrderPendingSeed.defaultRows),
    );
    expectStubL10nSmoke(tester, 'field_sales.stubs.orders_pending');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.text('Başlangıç'), findsOneWidget);
    expect(find.text('Bitiş'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    final sales = OrderPendingSeed.salesRows;
    expect(sales, isNotEmpty);
    expect(find.text('ONAY'), findsWidgets);
    expect(find.text('Beklemede'), findsWidgets);
    expect(find.textContaining(sales.first.id), findsOneWidget);
  });
}
