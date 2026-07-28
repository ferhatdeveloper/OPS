// Dosya Adı: whms_order_queue_bridge_test.dart
// Açıklama: Emir ONAY=1 tüm tipler → JobQueue birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/mapper/whms_payload_mapper.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_line_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_status.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_type.dart';
import 'package:exfin_ops/modules/whms/queue/whms_order_queue_bridge.dart';

void main() {
  group('WhmsPayloadMapper.entityTypeForOrder', () {
    test('tip → entity eşlemesi', () {
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.transfer),
        WhmsPayloadMapper.stockTransferEntityType,
      );
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.sayim),
        WhmsPayloadMapper.countResultEntityType,
      );
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.load),
        WhmsPayloadMapper.loadOrderEntityType,
      );
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.malKabul),
        'whms_order_mal_kabul',
      );
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.putaway),
        'whms_order_putaway',
      );
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.pick),
        'whms_order_pick',
      );
      expect(
        WhmsPayloadMapper.entityTypeForOrder(WhmsOrderType.sevk),
        'whms_order_sevk',
      );
    });
  });

  group('WhmsOrderQueueBridge', () {
    WhmsOrderDto order({
      required String id,
      required WhmsOrderType type,
      WhmsApprovalStatus approval = WhmsApprovalStatus.approved,
      String? toWh,
      String? toVehicle,
    }) {
      return WhmsOrderDto(
        id: id,
        orderType: type,
        status: WhmsOrderStatus.done,
        warehouseCode: 'MRK',
        fromWarehouseCode: 'MRK',
        toWarehouseCode: toWh,
        toVehicleId: toVehicle,
        orderDate: '2026-07-28',
        createdAt: '2026-07-28T00:00:00.000',
        updatedAt: '2026-07-28T00:00:00.000',
        approval: approval,
        lines: [
          WhmsOrderLineDto(
            id: '${id}_ln1',
            orderId: id,
            lineNo: 1,
            productId: 'p1',
            productCode: 'SKU1',
            quantity: 2,
            locationCode: type == WhmsOrderType.malKabul ? 'A-01' : null,
            approval: approval,
          ),
        ],
      );
    }

    test('ONAY≠1 tüm tiplerde skip', () async {
      for (final type in WhmsOrderType.values) {
        var calls = 0;
        final bridge = WhmsOrderQueueBridge(
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
          order(
            id: 'skip_${type.wireName}',
            type: type,
            approval: WhmsApprovalStatus.pending,
            toWh: type == WhmsOrderType.transfer ? 'IAD' : null,
            toVehicle: type == WhmsOrderType.load ? 'veh-1' : null,
          ),
        );
        expect(r.status, WhmsOrderEnqueueStatus.skipped, reason: type.wireName);
        expect(calls, 0, reason: type.wireName);
      }
    });

    test('ONAY=1 tüm tipler enqueue + entity', () async {
      final seen = <String, String>{};
      final bridge = WhmsOrderQueueBridge(
        enqueueFn: ({
          required entityType,
          required entityId,
          required payload,
          priority = 1,
        }) async {
          seen[entityId] = entityType;
          expect(payload['ONAY'], 1);
          expect(payload['entity'], entityType);
        },
      );

      for (final type in WhmsOrderType.values) {
        final id = 'ok_${type.wireName}';
        final r = await bridge.enqueueIfApproved(
          order(
            id: id,
            type: type,
            toWh: type == WhmsOrderType.transfer ? 'IAD' : null,
            toVehicle: type == WhmsOrderType.load ? 'veh-1' : null,
          ),
        );
        expect(r.status, WhmsOrderEnqueueStatus.enqueued, reason: type.wireName);
        expect(
          seen[id],
          WhmsPayloadMapper.entityTypeForOrder(type),
          reason: type.wireName,
        );
      }
      expect(seen, hasLength(WhmsOrderType.values.length));
    });

    test('enqueue fails → failed outcome', () async {
      final bridge = WhmsOrderQueueBridge(
        enqueueFn: ({
          required entityType,
          required entityId,
          required payload,
          priority = 1,
        }) async {
          throw StateError('queue down');
        },
      );
      final r = await bridge.enqueueIfApproved(
        order(id: 'fail1', type: WhmsOrderType.pick),
      );
      expect(r.status, WhmsOrderEnqueueStatus.failed);
      expect(r.error, contains('queue down'));
    });
  });
}
