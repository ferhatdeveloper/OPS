// Dosya Adı: logo_invoice_type_map_test.dart
// Açıklama: Fatura wholesale/return/purchase → Logo TYPE 8/3/1 map birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';

void main() {
  group('LogoPayloadMapper invoice TYPE 8/3', () {
    test('toptan → wholesale + Logo TYPE 8', () {
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType(
          'field_sales.wholesale_invoice_8',
        ),
        LogoPayloadMapper.invoiceQueueWholesale,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType('Toptan Satış Faturası (8)'),
        LogoPayloadMapper.invoiceQueueWholesale,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceLogoType(
          'field_sales.wholesale_invoice_8',
        ),
        LogoPayloadMapper.invoiceLogoTypeWholesale,
      );
      expect(LogoPayloadMapper.resolveInvoiceLogoType('wholesale'), 8);
    });

    test('iade → return + Logo TYPE 3 (wholesale flatten yok)', () {
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType(
          'field_sales.sales_return_invoice_3',
        ),
        LogoPayloadMapper.invoiceQueueReturn,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType('Satış İade Faturası (3)'),
        LogoPayloadMapper.invoiceQueueReturn,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceLogoType(
          'field_sales.sales_return_invoice_3',
        ),
        LogoPayloadMapper.invoiceLogoTypeReturn,
      );
      expect(LogoPayloadMapper.resolveInvoiceLogoType('return'), 3);
      expect(LogoPayloadMapper.resolveInvoiceLogoType('return'), isNot(8));
    });

    test('satın alma → purchase (≠ TYPE 3)', () {
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType(
          'field_sales.purchase_invoice',
        ),
        LogoPayloadMapper.invoiceQueuePurchase,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType('Satın Alma (Alış Faturası)'),
        LogoPayloadMapper.invoiceQueuePurchase,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceLogoType('purchase'),
        LogoPayloadMapper.invoiceLogoTypePurchase,
      );
      expect(LogoPayloadMapper.resolveInvoiceLogoType('purchase'), isNot(3));
    });

    test('van/retail → retail; logo TYPE null (8 flatten yok)', () {
      expect(
        LogoPayloadMapper.resolveInvoiceQueueType('field_sales.van_sales'),
        LogoPayloadMapper.invoiceQueueRetail,
      );
      expect(
        LogoPayloadMapper.resolveInvoiceLogoType('field_sales.van_sales'),
        isNull,
      );
    });

    test('invoiceFromLocal header type + logo_type yazar', () {
      final payload = LogoPayloadMapper.invoiceFromLocal(
        invoice: {'id': 'inv1', 'invoice_date': '2026-07-26'},
        items: [
          {'product_code': 'P1', 'quantity': 1, 'price': 10},
        ],
        customerCode: 'C1',
        type: 'field_sales.sales_return_invoice_3',
      );
      expect(payload['type'], 'return');
      expect(payload['invoice_type'], 'return');
      expect(payload['logo_type'], 3);
      expect(payload['TRCODE'], 3);
      final line = (payload['lines'] as List).first as Map;
      // Satır TYPE kalem tipi; fiş 3 değil
      expect(line['TYPE'], 0);
    });

    test('invoiceFromLocal toptan logo_type 8', () {
      final payload = LogoPayloadMapper.invoiceFromLocal(
        invoice: {'id': 'inv8'},
        items: [
          {'product_code': 'P8', 'quantity': 2, 'price': 5},
        ],
        customerCode: 'C8',
        type: 'Toptan Satış Faturası (8)',
      );
      expect(payload['type'], 'wholesale');
      expect(payload['logo_type'], 8);
      expect(payload['TRCODE'], 8);
    });
  });
}
