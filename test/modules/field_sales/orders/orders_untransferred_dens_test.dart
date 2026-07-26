// Dosya Adı: orders_untransferred_dens_test.dart
// Açıklama: K06 — Transfer edilmeyen sipariş dens + sync_queue smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/orders_untransferred_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('OrdersUntransferredScreen dens sekmeleri + boş',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const OrdersUntransferredScreen(
        preloadRows: [],
        onRetryQueue: _noopRetry,
      ),
    );

    expectStubL10nSmoke(tester, 'field_sales.stubs.orders_untransferred');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(
      find.text('Transfer edilmeyen sipariş bulunamadı.'),
      findsOneWidget,
    );
    expect(find.text('0 Adet'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);
  });

  testWidgets('sync_queue pending etiketi dens satırda', (tester) async {
    final rows = [
      OrderDensRow(
        id: 'ord-demo',
        orderType: OrderType.sales,
        orderDate: DateTime(2026, 7, 26),
        status: 'Pending',
        totalAmount: 100,
        isSynced: false,
        customerId: 'cust-1',
        customerCode: 'ARP001',
        customerName: 'ABC Market',
        queueJobId: 'job-1',
        retryCount: 0,
      ),
    ];
    await pumpStubWithL10n(
      tester,
      OrdersUntransferredScreen(
        preloadRows: rows,
        onRetryQueue: _noopRetry,
      ),
    );

    expect(find.textContaining('ARP001'), findsOneWidget);
    expect(find.textContaining('Kuyrukta'), findsOneWidget);
    expect(find.text('1 Adet'), findsOneWidget);
  });

  testWidgets('sync_queue hata etiketi dens satırda', (tester) async {
    final rows = [
      OrderDensRow(
        id: 'ord-err',
        orderType: OrderType.sales,
        orderDate: DateTime(2026, 7, 26),
        status: 'Pending',
        totalAmount: 50,
        isSynced: false,
        customerId: 'cust-1',
        customerCode: 'ARP001',
        customerName: 'ABC Market',
        queueJobId: 'job-err',
        retryCount: 1,
        lastError: 'timeout',
      ),
    ];
    await pumpStubWithL10n(
      tester,
      OrdersUntransferredScreen(
        preloadRows: rows,
        onRetryQueue: _noopRetry,
      ),
    );

    expect(find.textContaining('Hata (1): timeout'), findsOneWidget);
  });
}

Future<void> _noopRetry() async {}
