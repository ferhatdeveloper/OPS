// Dosya Adı: whms_payload_mapper_test.dart
// Açıklama: WHMS Faz 1 mapper / route hizası birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/whms/whms.dart';

void main() {
  group('WhmsPayloadMapper.normalizeWarehouseCode', () {
    test('kod ve seed adını MRK/ARC/IAD yapar', () {
      expect(WhmsPayloadMapper.normalizeWarehouseCode('MRK'), 'MRK');
      expect(
        WhmsPayloadMapper.normalizeWarehouseCode('Merkez Depo'),
        'MRK',
      );
      expect(WhmsPayloadMapper.normalizeWarehouseCode('Araç Depo'), 'ARC');
      expect(
        WhmsPayloadMapper.normalizeWarehouseCode('İade Deposu'),
        'IAD',
      );
    });
  });

  group('WhmsPayloadMapper.warehouseTransferToPayload', () {
    test('from/to_warehouse_code alanları zorunlu', () {
      final payload = WhmsPayloadMapper.warehouseTransferToPayload(
        WhmsWarehouseTransferDto(
          id: 'batch-1',
          fromWarehouseCode: 'Merkez Depo',
          toWarehouseCode: 'ARC',
          date: DateTime(2026, 7, 26),
          transferIds: const ['t1'],
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'P1',
              quantity: 5,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );

      expect(payload['from_warehouse_code'], 'MRK');
      expect(payload['to_warehouse_code'], 'ARC');
      expect(payload['SOURCE_WH'], 'MRK');
      expect(payload['TARGET_WH'], 'ARC');
      expect(payload['entity'], WhmsPayloadMapper.stockTransferEntityType);
      expect(payload['ONAY'], 1);
      expect(payload['lines'], hasLength(1));
    });

    test('stockTransferFromLocal ile ortak entity/type alanları', () {
      final whms = WhmsPayloadMapper.warehouseTransferToPayload(
        WhmsWarehouseTransferDto(
          id: 'b-parity',
          fromWarehouseCode: 'MRK',
          toWarehouseCode: 'IAD',
          date: DateTime(2026, 7, 26),
          transferIds: const ['t1'],
          lines: const [
            WhmsBridgeLine(
              productId: 'prd-1',
              productCode: 'SKU-1',
              quantity: 3,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );
      final logo = LogoPayloadMapper.stockTransferFromLocal(
        batchId: 'b-parity',
        transferIds: const ['t1'],
        fromWarehouse: 'MRK',
        toWarehouse: 'IAD',
        date: DateTime(2026, 7, 26),
        lines: const [
          {
            'product_code': 'SKU-1',
            'quantity': 3,
          },
        ],
      );
      expect(whms['entity'], logo['entity']);
      expect(whms['type'], logo['type']);
      expect(whms['transfer_type'], logo['transfer_type']);
      expect(whms['from_warehouse_code'], logo['from_warehouse_code']);
      expect(whms['to_warehouse_code'], logo['to_warehouse_code']);
      expect(whms['ONAY'], 1);
      expect(logo.containsKey('ONAY'), isFalse);
      expect(logo.containsKey('invoice_type'), isFalse);
    });
  });

  group('WhmsRouteMap', () {
    test('OPS stub → WHMS hedef eşlemesi', () {
      expect(
        WhmsRouteMap.futureWhmsTarget(WhmsRouteMap.opsMultiWarehouse),
        WhmsRouteMap.whmsMultiWarehouse,
      );
      expect(
        WhmsRouteMap.fsStockWhmsCandidateSeed['sub_stk_wh_query'],
        WhmsRouteMap.opsWarehouseStockQuery,
      );
      expect(WhmsRouteMap.isOpsStub(WhmsRouteMap.opsStockWarehouse), isTrue);
    });
  });
}
