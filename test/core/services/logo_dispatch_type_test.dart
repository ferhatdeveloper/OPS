// Dosya Adı: logo_dispatch_type_test.dart
// Açıklama: İrsaliye Logo dispatch TYPE — fatura flatten yok unit testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybill_entry_screen.dart';

void main() {
  group('LogoPayloadMapper.resolveDispatchType', () {
    test('waybill_wholesale → wholesale kanalı (≠ invoice 8)', () {
      expect(
        LogoPayloadMapper.resolveDispatchType('waybill_wholesale'),
        LogoPayloadMapper.dispatchChannelWholesale,
      );
      expect(
        LogoPayloadMapper.resolveDispatchType('wholesale'),
        'wholesale',
      );
      expect(
        LogoPayloadMapper.resolveDispatchType('Toptan Satış'),
        'wholesale',
      );
    });

    test('waybill_purchase → purchase kanalı (≠ iade TYPE 3)', () {
      expect(
        LogoPayloadMapper.resolveDispatchType('waybill_purchase'),
        LogoPayloadMapper.dispatchChannelPurchase,
      );
      expect(
        LogoPayloadMapper.resolveDispatchType('purchase'),
        'purchase',
      );
      expect(
        LogoPayloadMapper.resolveDispatchType('Satın Alma'),
        'purchase',
      );
    });

    test('localDispatchKey fatura invoice anahtarı üretmez', () {
      expect(
        LogoPayloadMapper.localDispatchKey('wholesale'),
        'waybill_wholesale',
      );
      expect(
        LogoPayloadMapper.localDispatchKey('purchase'),
        'waybill_purchase',
      );
      expect(
        LogoPayloadMapper.localDispatchKey('wholesale'),
        isNot(contains('invoice')),
      );
    });

    test('isDispatchStockInbound yalnızca alış', () {
      expect(
        LogoPayloadMapper.isDispatchStockInbound('waybill_purchase'),
        isTrue,
      );
      expect(
        LogoPayloadMapper.isDispatchStockInbound('waybill_wholesale'),
        isFalse,
      );
    });
  });

  group('LogoPayloadMapper.dispatchHeaderFromLocal', () {
    test('toptan header: type+dispatch_type; invoice_type yok', () {
      final h = LogoPayloadMapper.dispatchHeaderFromLocal(
        customerCode: 'C001',
        dispatchType: 'waybill_wholesale',
      );
      expect(h['customer_code'], 'C001');
      expect(h['ARP_CODE'], 'C001');
      expect(h['type'], 'wholesale');
      expect(h['dispatch_type'], 'waybill_wholesale');
      expect(h['waybill_type'], 'waybill_wholesale');
      expect(h['entity'], 'dispatch');
      expect(h.containsKey('invoice_type'), isFalse);
      expect(h['type'], isNot('8'));
      expect(h['type'], isNot(8));
    });

    test('alış header: purchase; toptan ile aynı map değil', () {
      final sale = LogoPayloadMapper.dispatchHeaderFromLocal(
        customerCode: 'C001',
        dispatchType: 'waybill_wholesale',
      );
      final buy = LogoPayloadMapper.dispatchHeaderFromLocal(
        customerCode: 'S001',
        dispatchType: 'waybill_purchase',
      );
      expect(buy['type'], 'purchase');
      expect(buy['dispatch_type'], 'waybill_purchase');
      expect(buy['type'], isNot(sale['type']));
      expect(buy.containsKey('invoice_type'), isFalse);
    });
  });

  group('WaybillType / buildDispatchQueuePayload', () {
    test('localKey ve logoDispatchType ayrımı', () {
      expect(WaybillType.wholesale.localKey, 'waybill_wholesale');
      expect(WaybillType.purchase.localKey, 'waybill_purchase');
      expect(WaybillType.wholesale.logoDispatchType, 'wholesale');
      expect(WaybillType.purchase.logoDispatchType, 'purchase');
      expect(WaybillType.purchase.isStockInbound, isTrue);
      expect(WaybillType.wholesale.isStockInbound, isFalse);
    });

    test('kuyruk payload entity=dispatch; fatura flatten yok', () {
      final payload = WaybillEntryScreen.buildDispatchQueuePayload(
        customerCode: 'ARP-9',
        waybillType: WaybillType.wholesale,
        items: [
          {'product_code': 'P1', 'quantity': 2, 'price': 10},
        ],
      );
      expect(payload['entity'], 'dispatch');
      expect(payload['type'], 'wholesale');
      expect(payload['dispatch_type'], 'waybill_wholesale');
      expect(payload.containsKey('invoice_type'), isFalse);
      expect(payload['items'], isA<List>());
      expect((payload['items'] as List).length, 1);
    });

    test('satın alma payload purchase kanalı', () {
      final payload = WaybillEntryScreen.buildDispatchQueuePayload(
        customerCode: 'TED-1',
        waybillType: WaybillType.purchase,
      );
      expect(payload['type'], 'purchase');
      expect(payload['dispatch_type'], 'waybill_purchase');
    });
  });
}
