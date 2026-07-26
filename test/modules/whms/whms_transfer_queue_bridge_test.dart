// Dosya Adı: whms_transfer_queue_bridge_test.dart
// Açıklama: WHMS Faz 2.2 onaylı transfer kuyruk köprüsü testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/whms/whms.dart';

void main() {
  group('WhmsTransferQueueBridge', () {
    test('ONAY≠1 ise skip; enqueue çağrılmaz', () async {
      var calls = 0;
      final bridge = WhmsTransferQueueBridge(
        enqueueFn: ({
          required entityType,
          required entityId,
          required payload,
          priority = 1,
        }) async {
          calls++;
        },
      );
      final r = await bridge.enqueueIfApproved(
        WhmsWarehouseTransferDto(
          id: 'b1',
          fromWarehouseCode: 'MRK',
          toWarehouseCode: 'IAD',
          date: DateTime(2026, 7, 26),
          lines: const [
            WhmsBridgeLine(
              productId: 'p1',
              productCode: 'SKU',
              quantity: 1,
            ),
          ],
          approval: WhmsApprovalStatus.pending,
        ),
      );
      expect(r.status, WhmsTransferEnqueueStatus.skipped);
      expect(calls, 0);
    });

    test('ONAY=1 ise payload ONAY + kuyruk', () async {
      Map<String, dynamic>? seen;
      final bridge = WhmsTransferQueueBridge(
        enqueueFn: ({
          required entityType,
          required entityId,
          required payload,
          priority = 1,
        }) async {
          seen = payload;
          expect(entityType, 'stock_transfer');
          expect(entityId, 'b2');
        },
      );
      final r = await bridge.enqueueApprovedFromDens(
        batchId: 'b2',
        fromWarehouse: 'Merkez Depo',
        toWarehouse: 'IAD',
        date: DateTime(2026, 7, 26),
        transferIds: const ['t1'],
        lines: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU',
            quantity: 2,
          ),
        ],
      );
      expect(r.status, WhmsTransferEnqueueStatus.enqueued);
      expect(seen?['ONAY'], 1);
      expect(seen?['from_warehouse_code'], 'MRK');
      expect(seen?['to_warehouse_code'], 'IAD');
      expect(seen?['entity'], 'stock_transfer');
    });
  });
}
