// Dosya Adı: order_tracking_screen_test.dart
// Açıklama: Sipariş takip dens ekranı smoke (boş store)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_scope.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_dens_queue_body.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_tracking_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_dens_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// Boş liste dönen dens store.
class _EmptyOrderDensStore extends OrderDensStore {
  const _EmptyOrderDensStore();

  @override
  Future<List<OrderDensRow>> query(OrderDensScope scope) async {
    return const [];
  }
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('OrderTrackingScreen dens filtre + boş liste', (tester) async {
    await pumpStubWithL10n(
      tester,
      Scaffold(
        body: OrderDensQueueBody(
          scope: OrderDensScope.tracking,
          emptyMessageKey: 'field_sales.order_tracking_empty',
          store: const _EmptyOrderDensStore(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.queue_tab_sales');
    expectStubL10nSmoke(tester, 'field_sales.period_this_month');
    expectStubL10nSmoke(tester, 'field_sales.order_tracking_empty');
  });

  testWidgets('OrderTrackingScreen AppBar başlık', (tester) async {
    await pumpStubWithL10n(
      tester,
      const OrderTrackingScreen(),
    );
    await tester.pump();
    // İlk frame loading; kısa bekle (DB yoksa catch → boş)
    await tester.pump(const Duration(milliseconds: 100));

    expectStubL10nSmoke(tester, 'field_sales.stubs.order_tracking');
  });
}
