// Dosya Adı: whms_count_queue_bridge_test.dart
// Açıklama: Merkez sayım offline kuyruk köprüsü birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/whms/count/count.dart';
import 'package:exfin_ops/modules/whms/whms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhmsCountQueueBridge', () {
    test('ONAY≠1 ise skip; enqueue çağrılmaz', () async {
      var calls = 0;
      final bridge = WhmsCountQueueBridge(
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
        WhmsCountResultDto(
          id: 'c1',
          warehouseCode: 'MRK',
          date: DateTime(2026, 7, 28),
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
      expect(r.status, WhmsCountEnqueueStatus.skipped);
      expect(calls, 0);
    });

    test('ONAY=1 ise stock_count payload + kuyruk', () async {
      Map<String, dynamic>? seen;
      String? seenType;
      final bridge = WhmsCountQueueBridge(
        enqueueFn: ({
          required entityType,
          required entityId,
          required payload,
          priority = 1,
        }) async {
          seen = payload;
          seenType = entityType;
          expect(entityId, 'c2');
        },
      );
      final r = await bridge.enqueueIfApproved(
        WhmsCountResultDto(
          id: 'c2',
          orderId: 'ord-1',
          warehouseCode: 'Merkez Depo',
          locationCode: 'A-01',
          date: DateTime(2026, 7, 28),
          lines: const [
            WhmsBridgeLine(
              productId: 'p1',
              productCode: 'SKU',
              quantity: 3,
            ),
          ],
          approval: WhmsApprovalStatus.approved,
        ),
      );
      expect(r.status, WhmsCountEnqueueStatus.enqueued);
      expect(seenType, 'stock_count');
      expect(seen?['ONAY'], 1);
      expect(seen?['warehouse_code'], 'MRK');
      expect(seen?['order_id'], 'ord-1');
      expect(seen?['location_code'], 'A-01');
      expect(seen?['entity'], 'stock_count');
    });
  });

  group('WhmsCountResultLine', () {
    test('variance = counted − system', () {
      const line = WhmsCountResultLine(
        productId: 'p1',
        productCode: 'SKU',
        systemQty: 10,
        countedQty: 8,
      );
      expect(line.variance, -2);
      expect(line.toBridgeLine().quantity, 8);
    });
  });
}
