// Dosya Adı: whms_order_model_test.dart
// Açıklama: WhmsOrderDto / tip / satır / lokasyon kuralı birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_line_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_status.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_type.dart';

void main() {
  group('WhmsOrderType', () {
    test('wireName round-trip P0 seti', () {
      for (final t in WhmsOrderType.values) {
        expect(WhmsOrderType.fromWire(t.wireName), t);
        expect(WhmsOrderType.isKnown(t.wireName), isTrue);
        expect(t.storageCode, t.wireName);
      }
      expect(WhmsOrderType.fromWire('count'), WhmsOrderType.sayim);
      expect(WhmsOrderType.isKnown('unknown_x'), isFalse);
      expect(WhmsOrderType.malKabul.requiresLocation, isTrue);
      expect(WhmsOrderType.putaway.requiresLocation, isTrue);
      expect(WhmsOrderType.pick.requiresLocation, isFalse);
    });
  });

  group('WhmsOrderStatus', () {
    test('completed alias → done; next zinciri', () {
      expect(
        WhmsOrderStatus.fromWire('done'),
        WhmsOrderStatus.done,
      );
      expect(
        WhmsOrderStatus.fromWire('completed'),
        WhmsOrderStatus.done,
      );
      expect(WhmsOrderStatus.draft.next, WhmsOrderStatus.assigned);
      expect(WhmsOrderStatus.assigned.next, WhmsOrderStatus.inProgress);
      expect(WhmsOrderStatus.inProgress.next, WhmsOrderStatus.done);
      expect(WhmsOrderStatus.done.next, isNull);
      expect(WhmsOrderStatus.done.isTerminal, isTrue);
    });
  });

  group('WhmsOrderLineDto', () {
    test('toMap / fromMap + mal_kabul lokasyon kuralı', () {
      const line = WhmsOrderLineDto(
        id: 'ol1',
        orderId: 'o1',
        lineNo: 1,
        productId: 'p1',
        productCode: 'SKU-1',
        quantity: 4,
        locationCode: 'A-01-02',
        unitName: 'AD',
      );
      final map = line.toMap();
      expect(map['order_id'], 'o1');
      expect(map['location_code'], 'A-01-02');
      expect(map['product_id'], 'p1');

      final round = WhmsOrderLineDto.fromMap(map);
      expect(round.productCode, 'SKU-1');
      expect(round.quantity, 4);
      expect(round.hasRequiredLocation(WhmsOrderType.malKabul), isTrue);

      const noLoc = WhmsOrderLineDto(
        id: 'ol2',
        orderId: 'o1',
        lineNo: 2,
        productId: 'p2',
        quantity: 1,
      );
      expect(noLoc.hasRequiredLocation(WhmsOrderType.malKabul), isFalse);
      expect(noLoc.hasRequiredLocation(WhmsOrderType.transfer), isTrue);
    });
  });

  group('WhmsOrderDto', () {
    test('toMap / fromMap ONAY + tip korur', () {
      const dto = WhmsOrderDto(
        id: 'wo1',
        orderType: WhmsOrderType.malKabul,
        status: WhmsOrderStatus.draft,
        warehouseCode: 'MRK',
        orderDate: '2026-07-28',
        createdAt: '2026-07-28T00:00:00.000',
        updatedAt: '2026-07-28T00:00:00.000',
        approval: WhmsApprovalStatus.approved,
        lines: [
          WhmsOrderLineDto(
            id: 'ol1',
            orderId: 'wo1',
            lineNo: 1,
            productId: 'p1',
            productCode: 'SKU-1',
            quantity: 2,
            locationCode: 'A-01-01',
          ),
        ],
      );
      final map = dto.toMap();
      expect(map['order_type'], 'mal_kabul');
      expect(map['status'], 'draft');
      expect(map['ONAY'], 1);

      final round = WhmsOrderDto.fromMap(map, lines: dto.lines);
      expect(round.orderType, WhmsOrderType.malKabul);
      expect(round.approval, WhmsApprovalStatus.approved);
      expect(round.linesSatisfyLocation, isTrue);
      expect(round.requiresLocation, isTrue);
    });

    test('mal_kabul boş satır → linesSatisfyLocation true (header taslak)', () {
      const dto = WhmsOrderDto(
        id: 'wo_empty',
        orderType: WhmsOrderType.malKabul,
        status: WhmsOrderStatus.draft,
        orderDate: '2026-07-28',
        createdAt: '2026-07-28T00:00:00.000',
        updatedAt: '2026-07-28T00:00:00.000',
      );
      expect(dto.linesSatisfyLocation, isTrue);
    });

    test('mal_kabul lokasyonsuz satır → linesSatisfyLocation false', () {
      const dto = WhmsOrderDto(
        id: 'wo2',
        orderType: WhmsOrderType.malKabul,
        status: WhmsOrderStatus.draft,
        orderDate: '2026-07-28',
        createdAt: '2026-07-28T00:00:00.000',
        updatedAt: '2026-07-28T00:00:00.000',
        lines: [
          WhmsOrderLineDto(
            id: 'ol1',
            orderId: 'wo2',
            lineNo: 1,
            productId: 'p1',
            quantity: 1,
          ),
        ],
      );
      expect(dto.linesSatisfyLocation, isFalse);
    });

    test('load emri toVehicleId map’te durur', () {
      const load = WhmsOrderDto(
        id: 'lo1',
        orderType: WhmsOrderType.load,
        status: WhmsOrderStatus.assigned,
        warehouseCode: 'MRK',
        toVehicleId: 'veh-1',
        orderDate: '2026-07-28',
        createdAt: '2026-07-28T00:00:00.000',
        updatedAt: '2026-07-28T00:00:00.000',
        approval: WhmsApprovalStatus.approved,
      );
      expect(load.toMap()['to_vehicle_id'], 'veh-1');
      expect(load.requiresLocation, isFalse);
    });
  });
}
