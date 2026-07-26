// Dosya Adı: order_customer_guard_test.dart
// Açıklama: Sipariş kaydında boş cari (customerId) engelinin unit testi
// Oluşturulma Tarihi: 2026-07-25
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-25

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_provider.dart';

void main() {
  group('OrderNotifier customerId guard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('isValidCustomerId boş veya whitespace için false döner', () {
      expect(OrderNotifier.isValidCustomerId(null), isFalse);
      expect(OrderNotifier.isValidCustomerId(''), isFalse);
      expect(OrderNotifier.isValidCustomerId('   '), isFalse);
      expect(OrderNotifier.isValidCustomerId('cust-1'), isTrue);
    });

    test('saveOrder boş customerId ile false döner ve hata mesajı set eder',
        () async {
      final notifier = container.read(orderProvider.notifier);
      notifier.startNewOrder('');

      final result = await notifier.saveOrder(null);

      expect(result, isFalse);
      final state = container.read(orderProvider);
      expect(state.error, 'field_sales.order_save_requires_customer');
    });

    test('saveOrder geçerli customerId ama ürün yoksa ürün hatası verir',
        () async {
      final notifier = container.read(orderProvider.notifier);
      notifier.startNewOrder('customer-abc');

      final result = await notifier.saveOrder(null);

      expect(result, isFalse);
      final state = container.read(orderProvider);
      expect(state.error, 'field_sales.order_min_products');
    });
  });
}
