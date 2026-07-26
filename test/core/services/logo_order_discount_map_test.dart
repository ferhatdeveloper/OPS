// Dosya Adı: logo_order_discount_map_test.dart
// Açıklama: order_items.discount_percent → Logo DISCOUNT_RATE map birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';

void main() {
  group('LogoPayloadMapper order_items.discount_percent', () {
    test('discount_percent → DISCOUNT_RATE ve discount_percent', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'o-disc-1', 'order_date': '2026-07-26'},
        items: [
          {
            'product_code': 'P1',
            'quantity': 2,
            'price': 100,
            'discount_percent': 10,
          },
        ],
        customerCode: 'C1',
        orderType: 'sales',
      );
      final line = (payload['lines'] as List).first as Map;
      expect(line['discount_percent'], 10);
      expect(line['DISCOUNT_RATE'], 10);
      expect(line['price'], 100);
      expect(line['quantity'], 2);
    });

    test('eksik discount_percent → 0', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'o-disc-2'},
        items: [
          {'product_code': 'P2', 'quantity': 1, 'unit_price': 50},
        ],
        customerCode: 'C2',
      );
      final line = (payload['lines'] as List).first as Map;
      expect(line['discount_percent'], 0);
      expect(line['DISCOUNT_RATE'], 0);
    });

    test('DISCOUNT_RATE alias kabul edilir', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'o-disc-3'},
        items: [
          {
            'product_code': 'P3',
            'quantity': 1,
            'price': 20,
            'DISCOUNT_RATE': 15.5,
          },
        ],
        customerCode: 'C3',
      );
      final line = (payload['lines'] as List).first as Map;
      expect(line['discount_percent'], 15.5);
      expect(line['DISCOUNT_RATE'], 15.5);
    });

    test('items listesi lines ile aynı iskontoyu taşır', () {
      final payload = LogoPayloadMapper.orderFromLocal(
        order: {'id': 'o-disc-4'},
        items: [
          {
            'product_code': 'P4',
            'quantity': 3,
            'price': 40,
            'discount_percent': 5,
          },
        ],
        customerCode: 'C4',
      );
      final items = payload['items'] as List;
      expect((items.first as Map)['DISCOUNT_RATE'], 5);
    });
  });
}
