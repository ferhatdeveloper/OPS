// Dosya Adı: logo_stock_transfer_map_test.dart
// Açıklama: Ambar transfer dens → Logo stock_transfer payload unit testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';

void main() {
  group('LogoPayloadMapper.stockTransferFromLocal', () {
    test('header: entity stock_transfer, from/to ambar, fatura TYPE yok', () {
      final payload = LogoPayloadMapper.stockTransferFromLocal(
        batchId: 'batch-1',
        transferIds: const ['t1', 't2'],
        fromWarehouse: 'Merkez Depo',
        toWarehouse: 'Araç Depo',
        date: DateTime(2026, 7, 26),
        lines: const [
          {
            'transfer_id': 't1',
            'product_code': 'P001',
            'quantity': 5,
          },
          {
            'transfer_id': 't2',
            'product_code': 'P002',
            'quantity': 2.5,
          },
        ],
        source: const {
          'workplace': 'Merkez İşyeri',
          'factory': 'Fabrika 01',
          'warehouse': 'Merkez Depo',
        },
        target: const {
          'workplace': 'Merkez İşyeri',
          'factory': 'Fabrika 01',
          'warehouse': 'Araç Depo',
        },
      );

      expect(payload['entity'], LogoPayloadMapper.stockTransferEntityType);
      expect(payload['type'], LogoPayloadMapper.stockTransferLocalType);
      expect(payload['batch_id'], 'batch-1');
      expect(payload['transfer_ids'], ['t1', 't2']);
      expect(payload['from_warehouse'], 'Merkez Depo');
      expect(payload['to_warehouse'], 'Araç Depo');
      expect(payload['SOURCE_WH'], 'Merkez Depo');
      expect(payload['TARGET_WH'], 'Araç Depo');
      expect(payload['date'], '2026-07-26');
      expect(payload.containsKey('invoice_type'), isFalse);
      expect(payload['type'], isNot(equals(8)));
      expect(payload['type'], isNot(equals('wholesale')));

      final lines = payload['lines'] as List;
      expect(lines, hasLength(2));
      expect(lines[0]['product_code'], 'P001');
      expect(lines[0]['MASTER_CODE'], 'P001');
      expect(lines[0]['quantity'], 5);
      expect(lines[1]['quantity'], 2.5);
      expect(payload['items'], hasLength(2));
      expect(payload['source']['warehouse'], 'Merkez Depo');
      expect(payload['target']['warehouse'], 'Araç Depo');
    });

    test('entity_type sabiti JobQueue ile uyumlu', () {
      expect(LogoPayloadMapper.stockTransferEntityType, 'stock_transfer');
      expect(LogoPayloadMapper.stockTransferLocalType, 'warehouse_transfer');
    });
  });
}
