// Dosya Adı: order_type_test.dart
// Açıklama: Sipariş Satış/Alış tip ve iskonto unit testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_provider.dart';

void main() {
  group('OrderType', () {
    test('fromStorage purchase varyantları', () {
      expect(OrderType.fromStorage('purchase'), OrderType.purchase);
      expect(OrderType.fromStorage('alis'), OrderType.purchase);
      expect(OrderType.fromStorage('alış'), OrderType.purchase);
      expect(OrderType.fromStorage('sales'), OrderType.sales);
      expect(OrderType.fromStorage(null), OrderType.sales);
    });

    test('storageValue', () {
      expect(OrderType.sales.storageValue, 'sales');
      expect(OrderType.purchase.storageValue, 'purchase');
    });
  });

  group('OrderNotifier.resolveQueueType', () {
    test('alış → purchase', () {
      expect(
        OrderNotifier.resolveQueueType(OrderType.purchase),
        'purchase',
      );
      expect(OrderNotifier.resolveQueueType('purchase'), 'purchase');
      expect(OrderNotifier.resolveQueueType('alis'), 'purchase');
      expect(OrderNotifier.resolveQueueType('alış'), 'purchase');
      expect(OrderNotifier.resolveQueueType('buy'), 'purchase');
    });

    test('satış → sales', () {
      expect(OrderNotifier.resolveQueueType(OrderType.sales), 'sales');
      expect(OrderNotifier.resolveQueueType('sales'), 'sales');
      expect(OrderNotifier.resolveQueueType(null), 'sales');
      expect(OrderNotifier.resolveQueueType(''), 'sales');
    });
  });

  group('LogoPayloadMapper order sync queue type', () {
    test('purchase → type/order_type/order_channel doğru', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {
          'id': 'ord-p1',
          'order_date': '2026-07-26',
          'order_type': 'purchase',
        },
        items: const [
          {'product_code': 'P1', 'quantity': 1, 'price': 10},
        ],
        customerCode: 'C001',
        orderType: 'purchase',
      );
      expect(payload['type'], 'purchase');
      expect(payload['order_type'], 'purchase');
      expect(payload['order_channel'], 'order_purchase');
      // Satır TYPE kalem tipi; satış/alış kanalı değil
      expect((payload['lines'] as List).first['TYPE'], 0);
    });

    test('sales → type sales, channel order_sales', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'ord-s1', 'order_date': '2026-07-26'},
        items: const [],
        customerCode: 'C002',
        orderType: 'sales',
      );
      expect(payload['type'], 'sales');
      expect(payload['order_type'], 'sales');
      expect(payload['order_channel'], 'order_sales');
    });

    test('resolveOrderApiType purchase varyantları', () {
      expect(LogoPayloadMapper.resolveOrderApiType('purchase'), 'purchase');
      expect(
        LogoPayloadMapper.resolveOrderApiType('order_purchase'),
        'purchase',
      );
      expect(LogoPayloadMapper.resolveOrderApiType('alış'), 'purchase');
      expect(LogoPayloadMapper.resolveOrderApiType('sales'), 'sales');
      expect(LogoPayloadMapper.resolveOrderApiType(null), 'sales');
    });
  });

  group('OrderNotifier orderType', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('startNewOrder alış tipini taslağa yazar', () {
      final notifier = container.read(orderProvider.notifier);
      notifier.startNewOrder('cust-1', orderType: OrderType.purchase);
      final draft = container.read(orderProvider).draftOrder;
      expect(draft, isNotNull);
      expect(draft!.orderType, OrderType.purchase);
      expect(draft.customerId, 'cust-1');
    });

    test('startNewOrder varsayılan satış', () {
      final notifier = container.read(orderProvider.notifier);
      notifier.startNewOrder('cust-2');
      expect(
        container.read(orderProvider).draftOrder!.orderType,
        OrderType.sales,
      );
    });
  });
}
