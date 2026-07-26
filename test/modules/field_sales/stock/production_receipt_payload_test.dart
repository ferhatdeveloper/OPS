// Dosya Adı: production_receipt_payload_test.dart
// Açıklama: Üretimden giriş kuyruk payload birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/production_receipt_payload.dart';

void main() {
  group('ProductionReceiptPayload', () {
    test('build: entity/type production_receipt; fatura TYPE 8 yok', () {
      final map = ProductionReceiptPayload.build(
        id: 'prd-1',
        workplace: 'Merkez İşyeri',
        factory: 'Fabrika 01',
        warehouse: 'Merkez Depo',
        date: DateTime(2026, 7, 26),
        lines: const [
          ProductionReceiptLineData(
            code: 'PRD-1',
            name: 'Örnek',
            qty: '2,5',
          ),
        ],
      );

      expect(map['id'], 'prd-1');
      expect(map['entity'], ProductionReceiptPayload.entityType);
      expect(map['type'], ProductionReceiptPayload.queueType);
      expect(map['slip_type'], ProductionReceiptPayload.slipType);
      expect(map['type'], LogoPayloadMapper.stockSlipProductionReceipt);
      expect(map['type'], isNot(LogoPayloadMapper.invoiceQueueWholesale));
      expect(map.containsKey('invoice_type'), isFalse);
      expect(map['workplace'], 'Merkez İşyeri');
      expect(map['factory'], 'Fabrika 01');
      expect(map['warehouse'], 'Merkez Depo');

      final lines = map['lines'] as List<dynamic>;
      expect(lines, hasLength(1));
      final line = lines.first as Map<String, dynamic>;
      expect(line['product_code'], 'PRD-1');
      expect(line['quantity'], 2.5);
    });

    test('entityType fatura wholesale ile karışmaz', () {
      expect(
        ProductionReceiptPayload.entityType,
        isNot(LogoPayloadMapper.invoiceQueueWholesale),
      );
      expect(
        ProductionReceiptPayload.queueType,
        LogoPayloadMapper.stockSlipProductionReceipt,
      );
    });
  });
}
