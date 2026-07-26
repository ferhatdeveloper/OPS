// Dosya Adı: customer_model_from_map_test.dart
// Açıklama: Cari fromMap null tarih / kod alanları ve seçim boş mesajı testi
// Oluşturulma Tarihi: 2026-07-25
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-25

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_customer_selection_screen.dart';

void main() {
  group('CustomerModel.fromMap seed uyumluluğu', () {
    test('updated_at null iken parse patlamaz ve liste satırı oluşur', () {
      final customer = CustomerModel.fromMap({
        'id': 'cust_1',
        'name': 'Marketim Gıda',
        'tax_no': '1234567890',
        'created_at': '2026-07-25T10:00:00.000',
        'updated_at': null,
        'is_active': 1,
      });

      expect(customer.id, 'cust_1');
      expect(customer.name, 'Marketim Gıda');
      expect(customer.taxNo, '1234567890');
      expect(customer.displayCodeOrTax, contains('cust_1'));
      expect(customer.displayCodeOrTax, contains('VKN: 1234567890'));
    });

    test('code alanı satır özetinde önceliklidir', () {
      final customer = CustomerModel.fromMap({
        'id': 'cust_2',
        'code': '120.01.001',
        'name': 'Özlem Süpermarket',
        'tax_no': '9876543210',
        'created_at': null,
        'updated_at': null,
      });

      expect(customer.code, '120.01.001');
      expect(customer.displayCodeOrTax, startsWith('120.01.001'));
      expect(customer.displayCodeOrTax, contains('VKN:'));
    });

    test('boş map id/name boş string ile güvenli döner', () {
      final customer = CustomerModel.fromMap({});
      expect(customer.id, '');
      expect(customer.name, '');
    });
  });

  group('OrderCustomerSelectionScreen.emptyMessage', () {
    test('arama yokken boş DB mesajı', () {
      expect(
        OrderCustomerSelectionScreen.emptyMessage(''),
        'field_sales.no_customer_cards',
      );
      expect(
        OrderCustomerSelectionScreen.emptyMessage('   '),
        'field_sales.no_customer_cards',
      );
    });

    test('arama sonrası bulunamadı mesajı', () {
      expect(
        OrderCustomerSelectionScreen.emptyMessage('xyz'),
        'field_sales.customer_not_found',
      );
    });
  });
}
