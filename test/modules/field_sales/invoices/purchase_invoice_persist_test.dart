// Dosya Adı: purchase_invoice_persist_test.dart
// Açıklama: Satın alma faturası SQLite+queue tip koruma birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_model.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_persist.dart';

void main() {
  group('InvoicePersist.buildInvoiceSqliteRow — tip koru', () {
    test('purchase local key SQLite invoice_type olarak kalır', () {
      final invoice = InvoiceModel(
        id: 'inv-buy-1',
        customerId: 'sup-1',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 120,
        status: 'Completed',
        invoiceType: 'field_sales.purchase_invoice',
        isEInvoice: true,
        isSynced: 0,
      );

      final row = InvoicePersist.buildInvoiceSqliteRow(
        invoice,
        nowIso: '2026-07-26T12:00:00.000',
      );

      expect(row['invoice_type'], 'field_sales.purchase_invoice');
      expect(row['invoice_type'], isNot('return'));
      expect(row['invoice_type'], isNot('wholesale'));
      expect(row['approval_status'], 1);
      expect(row['is_synced'], 0);
      expect(row['customer_id'], 'sup-1');
    });
  });

  group('InvoicePersist.buildInvoiceQueuePayload — tip koru', () {
    test('satın alma → type=purchase, TRCODE=1; iade/toptan flatten yok', () {
      final invoice = InvoiceModel(
        id: 'inv-buy-2',
        customerId: 'sup-2',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 250.5,
        status: 'Completed',
        notes: 'alış',
        invoiceType: 'field_sales.purchase_invoice',
        isSynced: 0,
      );

      final payload = InvoicePersist.buildInvoiceQueuePayload(
        invoice: invoice,
        customerCode: 'TED-001',
        lines: [
          {
            'product_code': 'P-BUY',
            'quantity': 2,
            'price': 100,
            'vat_amount': 40,
          },
        ],
      );

      expect(payload['type'], LogoPayloadMapper.invoiceQueuePurchase);
      expect(payload['type'], isNot(LogoPayloadMapper.invoiceQueueReturn));
      expect(payload['type'], isNot(LogoPayloadMapper.invoiceQueueWholesale));
      // Yerel tip korunur — kuyruk anahtarına flatten yok
      expect(payload['invoice_type'], 'field_sales.purchase_invoice');
      expect(payload['logo_type'], LogoPayloadMapper.invoiceLogoTypePurchase);
      expect(payload['TRCODE'], 1);
      expect(payload['TRCODE'], isNot(3));
      expect(payload['TRCODE'], isNot(8));
      expect(payload['customer_code'], 'TED-001');
      expect(payload['arp_code'], 'TED-001');
      expect(payload['lines'], isA<List>());
      expect((payload['lines'] as List).length, 1);
    });

    test('TR literal Satın Alma da purchase + TYPE 1', () {
      final invoice = InvoiceModel(
        id: 'inv-buy-3',
        customerId: 'sup-3',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 10,
        invoiceType: 'Satın Alma (Alış Faturası)',
      );

      final payload = InvoicePersist.buildInvoiceQueuePayload(
        invoice: invoice,
        customerCode: 'ARP-BUY',
        lines: const [],
      );

      expect(payload['type'], 'purchase');
      expect(payload['invoice_type'], 'Satın Alma (Alış Faturası)');
      expect(payload['logo_type'], 1);
      expect(payload['TRCODE'], 1);
    });

    test('iade faturası purchase ile karışmaz', () {
      final invoice = InvoiceModel(
        id: 'inv-ret',
        customerId: 'c1',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 10,
        invoiceType: 'field_sales.sales_return_invoice_3',
      );

      final payload = InvoicePersist.buildInvoiceQueuePayload(
        invoice: invoice,
        customerCode: 'C1',
        lines: const [],
      );

      expect(payload['type'], 'return');
      expect(payload['TRCODE'], 3);
      expect(payload['type'], isNot('purchase'));
    });
  });

  group('LogoPayloadMapper.invoiceFromLocal purchase', () {
    test('purchase header TYPE 1; return/wholesale flatten yok', () {
      final payload = LogoPayloadMapper.invoiceFromLocal(
        invoice: {
          'id': 'inv-p',
          'invoice_date': '2026-07-26',
          'invoice_type': 'field_sales.purchase_invoice',
        },
        items: [
          {'product_code': 'PX', 'quantity': 1, 'price': 50},
        ],
        customerCode: 'TED-9',
        type: 'field_sales.purchase_invoice',
      );
      expect(payload['type'], 'purchase');
      expect(payload['logo_type'], 1);
      expect(payload['TRCODE'], 1);
      expect(payload['TRCODE'], isNot(3));
      expect(payload['type'], isNot('wholesale'));
    });
  });
}
