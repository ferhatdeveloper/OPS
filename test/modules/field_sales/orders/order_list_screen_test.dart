// Dosya Adı: order_list_screen_test.dart
// Açıklama: K06 — Sipariş listesi dens (transferred) widget smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_scope.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_dens_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// Boş transferred listesi.
class _EmptyTransferredStore extends OrderDensStore {
  const _EmptyTransferredStore();

  @override
  Future<List<OrderDensRow>> query(OrderDensScope scope) async {
    expect(scope, OrderDensScope.transferred);
    return const [];
  }
}

/// Tek senkron satış satırı.
class _SyncedSalesStore extends OrderDensStore {
  const _SyncedSalesStore();

  @override
  Future<List<OrderDensRow>> query(OrderDensScope scope) async {
    expect(scope, OrderDensScope.transferred);
    return [
      OrderDensRow(
        id: 'ord-synced',
        orderType: OrderType.sales,
        orderDate: DateTime.now(),
        status: 'Approved',
        totalAmount: 1250.5,
        isSynced: true,
        customerId: 'c1',
        customerCode: 'C001',
        customerName: 'Alpha Market',
      ),
    ];
  }
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('OrderListScreen dens sekmeleri + boş transferred',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const OrderListScreen(store: _EmptyTransferredStore()),
    );
    await pumpUntilLoaded(tester);

    expectStubL10nSmoke(tester, 'field_sales.stubs.order_list');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.text('Transfer edilen sipariş bulunamadı.'), findsOneWidget);
    expect(find.text('0 Adet'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('OrderListScreen transferred satırı dens gösterir',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const OrderListScreen(store: _SyncedSalesStore()),
    );
    await pumpUntilLoaded(tester);

    expect(find.textContaining('Alpha Market'), findsOneWidget);
    expect(find.textContaining('Onaylı'), findsOneWidget);
    expect(find.textContaining('Aktarıldı'), findsOneWidget);
    expect(find.text('1 Adet'), findsOneWidget);

    await tester.tap(find.text('2-ALIŞ'));
    await tester.pumpAndSettle();
    expect(find.text('Transfer edilen sipariş bulunamadı.'), findsOneWidget);
    expect(find.text('0 Adet'), findsOneWidget);
  });
}
