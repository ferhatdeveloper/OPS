// Dosya Adı: order_purchase_supplier_guard_test.dart
// Açıklama: Alış siparişinde tedarikçi cari zorunluluğu unit testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_provider.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_customer_selection_screen.dart';

void main() {
  group('CariCardRole', () {
    test('fromStorage tedarikçi varyantları', () {
      expect(CariCardRole.fromStorage('supplier'), CariCardRole.supplier);
      expect(CariCardRole.fromStorage('tedarikci'), CariCardRole.supplier);
      expect(CariCardRole.fromStorage('tedarikçi'), CariCardRole.supplier);
      expect(CariCardRole.fromStorage('vendor'), CariCardRole.supplier);
      expect(CariCardRole.fromStorage('both'), CariCardRole.both);
      expect(CariCardRole.fromStorage('customer'), CariCardRole.customer);
      expect(CariCardRole.fromStorage(null), CariCardRole.customer);
      expect(CariCardRole.fromStorage(''), CariCardRole.customer);
    });

    test('allowsPurchaseOrder yalnız supplier/both', () {
      expect(CariCardRole.supplier.allowsPurchaseOrder, isTrue);
      expect(CariCardRole.both.allowsPurchaseOrder, isTrue);
      expect(CariCardRole.customer.allowsPurchaseOrder, isFalse);
    });

    test('allowsSalesOrder supplier engelli', () {
      expect(CariCardRole.customer.allowsSalesOrder, isTrue);
      expect(CariCardRole.both.allowsSalesOrder, isTrue);
      expect(CariCardRole.supplier.allowsSalesOrder, isFalse);
    });
  });

  group('OrderNotifier purchase supplier guard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('isValidPartyForOrder alış + satış carisi → false', () {
      expect(
        OrderNotifier.isValidPartyForOrder(
          customerId: 'cust-1',
          orderType: OrderType.purchase,
          cardRole: CariCardRole.customer,
        ),
        isFalse,
      );
    });

    test('isValidPartyForOrder alış + tedarikçi → true', () {
      expect(
        OrderNotifier.isValidPartyForOrder(
          customerId: 'sup-1',
          orderType: OrderType.purchase,
          cardRole: CariCardRole.supplier,
        ),
        isTrue,
      );
    });

    test('isValidPartyForOrder alış + null rol fail-closed', () {
      expect(
        OrderNotifier.isValidPartyForOrder(
          customerId: 'sup-1',
          orderType: OrderType.purchase,
          cardRole: null,
        ),
        isFalse,
      );
    });

    test('isValidPartyForOrder satış + null rol geriye uyumlu', () {
      expect(
        OrderNotifier.isValidPartyForOrder(
          customerId: 'cust-1',
          orderType: OrderType.sales,
          cardRole: null,
        ),
        isTrue,
      );
    });

    test('filterForOrderType alışta müşteri kartlarını eler', () {
      final now = DateTime(2026, 7, 26);
      final rows = [
        CustomerModel(
          id: 'c1',
          name: 'Müşteri A',
          createdAt: now,
          updatedAt: now,
          cardRole: CariCardRole.customer,
        ),
        CustomerModel(
          id: 's1',
          name: 'Tedarikçi B',
          createdAt: now,
          updatedAt: now,
          cardRole: CariCardRole.supplier,
        ),
        CustomerModel(
          id: 'b1',
          name: 'Her İkisi',
          createdAt: now,
          updatedAt: now,
          cardRole: CariCardRole.both,
        ),
      ];
      final filtered = OrderNotifier.filterForOrderType(
        rows,
        OrderType.purchase,
      );
      expect(filtered.map((c) => c.id), ['s1', 'b1']);
    });

    test(
      'saveOrder alış + satış carisi → requires_supplier hatası',
      () async {
        final notifier = container.read(orderProvider.notifier);
        notifier.startNewOrder(
          'cust-sales',
          orderType: OrderType.purchase,
          cardRole: CariCardRole.customer,
        );

        final result = await notifier.saveOrder(null);

        expect(result, isFalse);
        final state = container.read(orderProvider);
        expect(state.error, 'field_sales.order_save_requires_supplier');
      },
    );

    test('saveOrder alış + tedarikçi ama ürün yok → ürün hatası', () async {
      final notifier = container.read(orderProvider.notifier);
      notifier.startNewOrder(
        'sup-1',
        orderType: OrderType.purchase,
        cardRole: CariCardRole.supplier,
      );

      final result = await notifier.saveOrder(null);

      expect(result, isFalse);
      final state = container.read(orderProvider);
      expect(state.error, 'field_sales.order_min_products');
    });
  });

  group('OrderCustomerSelectionScreen purchase empty keys', () {
    test('emptyMessage alış için tedarikçi anahtarları', () {
      expect(
        OrderCustomerSelectionScreen.emptyMessage(
          '',
          orderType: OrderType.purchase,
        ),
        'field_sales.no_supplier_cards',
      );
      expect(
        OrderCustomerSelectionScreen.emptyMessage(
          'xyz',
          orderType: OrderType.purchase,
        ),
        'field_sales.supplier_not_found',
      );
    });

    test('emptyMessage satış mevcut anahtarları korur', () {
      expect(
        OrderCustomerSelectionScreen.emptyMessage(''),
        'field_sales.no_customer_cards',
      );
      expect(
        OrderCustomerSelectionScreen.emptyMessage('q'),
        'field_sales.customer_not_found',
      );
    });

    test('selectHintKey alış varsayılanı', () {
      expect(
        OrderCustomerSelectionScreen.hintKeyFor(OrderType.purchase),
        'field_sales.select_supplier_first',
      );
      expect(
        OrderCustomerSelectionScreen.hintKeyFor(OrderType.sales),
        'field_sales.select_customer_first',
      );
    });
  });
}
