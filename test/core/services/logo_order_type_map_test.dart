// Dosya Adı: logo_order_type_map_test.dart
// Açıklama: Sipariş satış/alış → Logo API type / order_channel map birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';

void main() {
  group('LogoPayloadMapper order TYPE', () {
    test('resolveOrderApiType purchase varyantları', () {
      expect(LogoPayloadMapper.resolveOrderApiType('purchase'), 'purchase');
      expect(LogoPayloadMapper.resolveOrderApiType('order_purchase'), 'purchase');
      expect(LogoPayloadMapper.resolveOrderApiType('alış'), 'purchase');
      expect(LogoPayloadMapper.resolveOrderApiType('alis'), 'purchase');
      expect(LogoPayloadMapper.resolveOrderApiType('satin_alma'), 'purchase');
    });

    test('resolveOrderApiType varsayılan sales (wholesale flatten yok)', () {
      expect(LogoPayloadMapper.resolveOrderApiType(null), 'sales');
      expect(LogoPayloadMapper.resolveOrderApiType('sales'), 'sales');
      expect(LogoPayloadMapper.resolveOrderApiType('order_sales'), 'sales');
      // Fatura dili siparişte sales kanalına düşer; TYPE 8 üretilmez
      expect(LogoPayloadMapper.resolveOrderApiType('wholesale'), 'sales');
    });

    test('orderChannelKey', () {
      expect(LogoPayloadMapper.orderChannelKey('sales'), 'order_sales');
      expect(LogoPayloadMapper.orderChannelKey('purchase'), 'order_purchase');
    });

    test('orderFromLocal satış kanalı yazar', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'o1', 'order_date': '2026-07-26'},
        items: [
          {'product_code': 'P1', 'quantity': 1, 'price': 10},
        ],
        customerCode: 'C1',
        orderType: 'sales',
      );
      expect(payload['type'], 'sales');
      expect(payload['order_type'], 'sales');
      expect(payload['order_channel'], 'order_sales');
      expect(payload['invoice_type'], isNull);
    });

    test('orderFromLocal alış kanalı yazar; satır TYPE kalem tipi', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {
          'id': 'o2',
          'order_date': '2026-07-26',
          'order_type': 'purchase',
        },
        items: [
          {'product_code': 'P2', 'quantity': 2, 'price': 5, 'TYPE': 0},
        ],
        customerCode: 'S1',
      );
      expect(payload['type'], 'purchase');
      expect(payload['order_type'], 'purchase');
      expect(payload['order_channel'], 'order_purchase');
      final lines = payload['lines'] as List;
      expect((lines.first as Map)['TYPE'], 0);
    });

    test('satır type=sales string kalem TYPE ezecek şekilde kullanılmaz', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'o3', 'order_type': 'sales'},
        items: [
          {
            'product_code': 'P3',
            'quantity': 1,
            'price': 1,
            'type': 'sales',
          },
        ],
        customerCode: 'C3',
      );
      final line = (payload['lines'] as List).first as Map;
      expect(line['TYPE'], 0);
      expect(payload['type'], 'sales');
    });
  });
}
