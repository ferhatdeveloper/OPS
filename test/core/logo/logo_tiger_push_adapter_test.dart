// Dosya Adı: logo_tiger_push_adapter_test.dart
// Açıklama: Tiger push adapter mapping birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/logo/logo_tiger_push_adapter.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogoTigerPushAdapter.orderFromMapped', () {
    test('sales → salesOrders + TRANSACTIONS.items', () {
      final mapped = LogoPayloadMapper.orderFromLocal(
        order: {
          'id': 'o1',
          'order_date': '2026-07-28',
          'notes': 'test',
          'type': 'sales',
        },
        items: [
          {
            'product_code': 'SKU1',
            'quantity': 2,
            'price': 10.5,
            'discount_percent': 5,
          },
        ],
        customerCode: 'C120',
      );

      final t = LogoTigerPushAdapter.orderFromMapped(mapped);
      expect(t.resource, 'salesOrders');
      expect(t.restRecord['ARP_CODE'], 'C120');
      expect(t.restRecord['TYPE'], 1);
      expect(t.restRecord['DATE'], '2026-07-28');
      final tx = t.restRecord['TRANSACTIONS'] as Map;
      final items = tx['items'] as List;
      expect(items.length, 1);
      expect(items.first['MASTER_CODE'], 'SKU1');
      expect(items.first['QUANTITY'], 2);
      expect(items.first['PRICE'], 10.5);
      expect(items.first['DISCOUNT_RATE'], 5);
    });

    test('purchase → purchaseOrders TYPE 2', () {
      final mapped = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'p1', 'type': 'purchase', 'order_date': '2026-01-01'},
        items: [
          {'product_code': 'RM1', 'quantity': 1, 'price': 3},
        ],
        customerCode: 'S1',
      );
      final t = LogoTigerPushAdapter.orderFromMapped(mapped);
      expect(t.resource, 'purchaseOrders');
      expect(t.restRecord['TYPE'], 2);
      expect(t.restRecord['ARP_CODE'], 'S1');
    });
  });

  group('LogoTigerPushAdapter.invoiceFromMapped', () {
    test('wholesale → salesInvoices TYPE 8', () {
      final mapped = LogoPayloadMapper.invoiceFromLocal(
        invoice: {
          'id': 'inv1',
          'invoice_date': '2026-07-28T10:00:00',
          'notes': 'fatura',
        },
        items: [
          {'product_code': 'P1', 'quantity': 1, 'price': 100, 'vat_rate': 20},
        ],
        customerCode: 'C001',
        type: 'wholesale',
      );
      final t = LogoTigerPushAdapter.invoiceFromMapped(mapped);
      expect(t.resource, 'salesInvoices');
      expect(t.restRecord['TYPE'], 8);
      expect(t.restRecord['ARP_CODE'], 'C001');
      expect(t.restRecord['DATE'], '2026-07-28');
      final items =
          (t.restRecord['TRANSACTIONS'] as Map)['items'] as List;
      expect(items.first['MASTER_CODE'], 'P1');
      expect(items.first['VAT_RATE'], 20);
    });

    test('return → TYPE 3; purchase → purchaseInvoices', () {
      final ret = LogoTigerPushAdapter.invoiceFromMapped(
        LogoPayloadMapper.invoiceFromLocal(
          invoice: {'id': 'r1', 'invoice_date': '2026-07-01'},
          items: [
            {'product_code': 'X', 'quantity': 1, 'price': 1},
          ],
          customerCode: 'C2',
          type: 'return',
        ),
      );
      expect(ret.resource, 'salesInvoices');
      expect(ret.restRecord['TYPE'], 3);

      final buy = LogoTigerPushAdapter.invoiceFromMapped(
        LogoPayloadMapper.invoiceFromLocal(
          invoice: {'id': 'b1', 'invoice_date': '2026-07-01'},
          items: [
            {'product_code': 'Y', 'quantity': 1, 'price': 1},
          ],
          customerCode: 'S2',
          type: 'purchase',
        ),
      );
      expect(buy.resource, 'purchaseInvoices');
      expect(buy.restRecord['TYPE'], 1);
    });
  });

  group('LogoTigerPushAdapter.isSupported', () {
    test('order/invoice/dispatch destekli; collection değil', () {
      expect(LogoTigerPushAdapter.isSupported('order'), isTrue);
      expect(LogoTigerPushAdapter.isSupported('invoice'), isTrue);
      expect(LogoTigerPushAdapter.isSupported('waybill'), isTrue);
      expect(LogoTigerPushAdapter.isSupported('collection'), isFalse);
      expect(LogoTigerPushAdapter.isSupported('stock_transfer'), isFalse);
    });
  });
}
