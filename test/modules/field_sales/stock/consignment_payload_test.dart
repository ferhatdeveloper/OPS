// Dosya Adı: consignment_payload_test.dart
// Açıklama: Konsinye kuyruk payload birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/consignment_payload.dart';

void main() {
  group('ConsignmentPayload', () {
    test('build: entity/type consignment; fatura TYPE 8 yok', () {
      final map = ConsignmentPayload.build(
        id: 'csg-1',
        workplace: 'Merkez İşyeri',
        factory: 'Fabrika 01',
        warehouse: 'Merkez Depo',
        date: DateTime(2026, 7, 26),
        lines: const [
          ConsignmentLineData(
            code: 'CSG-1',
            name: 'Örnek',
            qty: '2,5',
          ),
        ],
      );

      expect(map['id'], 'csg-1');
      expect(map['entity'], ConsignmentPayload.entityType);
      expect(map['type'], ConsignmentPayload.queueType);
      expect(map['slip_type'], ConsignmentPayload.slipType);
      expect(map['type'], LogoPayloadMapper.stockSlipConsignment);
      expect(map['type'], isNot(LogoPayloadMapper.invoiceQueueWholesale));
      expect(map.containsKey('invoice_type'), isFalse);
      expect(map['workplace'], 'Merkez İşyeri');
      expect(map['factory'], 'Fabrika 01');
      expect(map['warehouse'], 'Merkez Depo');

      final lines = map['lines'] as List<dynamic>;
      expect(lines, hasLength(1));
      final line = lines.first as Map<String, dynamic>;
      expect(line['product_code'], 'CSG-1');
      expect(line['quantity'], 2.5);
    });

    test('entityType fatura wholesale ile karışmaz', () {
      expect(
        ConsignmentPayload.entityType,
        isNot(LogoPayloadMapper.invoiceQueueWholesale),
      );
      expect(
        ConsignmentPayload.queueType,
        LogoPayloadMapper.stockSlipConsignment,
      );
    });
  });
}
