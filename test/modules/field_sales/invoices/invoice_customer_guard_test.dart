// Dosya Adı: invoice_customer_guard_test.dart
// Açıklama: Fatura kaydında boş cari (customerId) engelinin unit testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_provider.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoice_customer_selection_screen.dart';

void main() {
  group('InvoiceNotifier customerId guard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('isValidCustomerId boş veya whitespace için false döner', () {
      expect(InvoiceNotifier.isValidCustomerId(null), isFalse);
      expect(InvoiceNotifier.isValidCustomerId(''), isFalse);
      expect(InvoiceNotifier.isValidCustomerId('   '), isFalse);
      expect(InvoiceNotifier.isValidCustomerId('cust-1'), isTrue);
    });

    test('saveInvoice boş customerId ile false döner ve hata mesajı set eder',
        () async {
      final notifier = container.read(invoiceProvider.notifier);
      notifier.startNewInvoice('');

      final result = await notifier.saveInvoice(null);

      expect(result, isFalse);
      final state = container.read(invoiceProvider);
      expect(state.error, 'field_sales.invoice_save_requires_customer');
    });

    test('saveInvoice geçerli customerId ama ürün yoksa ürün hatası verir',
        () async {
      final notifier = container.read(invoiceProvider.notifier);
      notifier.startNewInvoice('customer-abc');

      final result = await notifier.saveInvoice(null);

      expect(result, isFalse);
      final state = container.read(invoiceProvider);
      expect(state.error, 'field_sales.invoice_min_products');
    });
  });

  group('InvoiceNotifier.resolveQueueType', () {
    test('toptan / iade / satın alma / van tiplerini ayırır', () {
      expect(
        InvoiceNotifier.resolveQueueType('field_sales.wholesale_invoice_8'),
        'wholesale',
      );
      expect(
        InvoiceNotifier.resolveQueueType('Toptan Satış Faturası (8)'),
        'wholesale',
      );
      expect(
        InvoiceNotifier.resolveQueueType('field_sales.sales_return_invoice_3'),
        'return',
      );
      expect(
        InvoiceNotifier.resolveQueueType('Satış İade Faturası (3)'),
        'return',
      );
      expect(
        InvoiceNotifier.resolveQueueType('field_sales.purchase_invoice'),
        'purchase',
      );
      expect(InvoiceNotifier.resolveQueueType('purchase'), 'purchase');
      expect(
        InvoiceNotifier.resolveQueueType('field_sales.van_sales'),
        'retail',
      );
      expect(InvoiceNotifier.isStockInbound('purchase'), isTrue);
      expect(InvoiceNotifier.isStockInbound('field_sales.wholesale_invoice_8'),
          isFalse);
    });

    test('Logo TYPE 8/3/1 map', () {
      expect(
        InvoiceNotifier.resolveLogoType('field_sales.wholesale_invoice_8'),
        8,
      );
      expect(
        InvoiceNotifier.resolveLogoType('field_sales.sales_return_invoice_3'),
        3,
      );
      expect(
        InvoiceNotifier.resolveLogoType('field_sales.purchase_invoice'),
        1,
      );
      expect(InvoiceNotifier.resolveLogoType('field_sales.van_sales'), isNull);
    });
  });

  group('InvoiceCustomerSelectionScreen.emptyMessage', () {
    test('sipariş seçimi ile aynı anahtarları kullanır', () {
      expect(
        InvoiceCustomerSelectionScreen.emptyMessage(''),
        'field_sales.no_customer_cards',
      );
      expect(
        InvoiceCustomerSelectionScreen.emptyMessage('xyz'),
        'field_sales.customer_not_found',
      );
    });
  });
}
