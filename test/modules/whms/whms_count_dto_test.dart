// Dosya Adı: whms_count_dto_test.dart
// Açıklama: Merkez sayım DTO / emir / fark satırı birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/count/model/whms_count_order.dart';
import 'package:exfin_ops/modules/whms/count/model/whms_count_result_line.dart';

void main() {
  group('WhmsCountResultDto', () {
    test('toMap ONAY + satır + opsiyonel order/location', () {
      final dto = WhmsCountResultDto(
        id: 'cnt-1',
        orderId: 'ord-9',
        warehouseCode: 'MRK',
        locationCode: 'A-01-01',
        date: DateTime(2026, 7, 28),
        approval: WhmsApprovalStatus.approved,
        isSynced: false,
        lines: const [
          WhmsBridgeLine(
            productId: 'p1',
            productCode: 'SKU-1',
            quantity: 9,
            unitName: 'AD',
          ),
        ],
      );

      final map = dto.toMap();
      expect(map['id'], 'cnt-1');
      expect(map['order_id'], 'ord-9');
      expect(map['warehouse_code'], 'MRK');
      expect(map['location_code'], 'A-01-01');
      expect(map['ONAY'], 1);
      expect(map['is_synced'], 0);
      expect(map['lines'], hasLength(1));
      expect((map['lines'] as List).first['product_code'], 'SKU-1');
    });

    test('pending varsayılan ONAY=0', () {
      final dto = WhmsCountResultDto(
        id: 'cnt-2',
        warehouseCode: 'ARC',
        date: DateTime(2026, 7, 28),
        lines: const [],
      );
      expect(dto.toMap()['ONAY'], 0);
      expect(dto.toMap().containsKey('order_id'), isFalse);
    });
  });

  group('WhmsCountResultLine', () {
    test('variance = counted − system; toBridgeLine fiili miktar', () {
      const line = WhmsCountResultLine(
        productId: 'p1',
        productCode: 'SKU-1',
        systemQty: 10,
        countedQty: 9,
        locationCode: 'A-01-02',
      );
      expect(line.variance, -1);
      expect(line.toBridgeLine().quantity, 9);
      expect(line.toMap()['variance'], -1);
      expect(line.toMap()['location_code'], 'A-01-02');
    });
  });

  group('WhmsCountOrder', () {
    test('toMap status + filter_json + ONAY', () {
      final now = DateTime(2026, 7, 28);
      final order = WhmsCountOrder(
        id: 'ord-1',
        warehouseCode: 'MRK',
        locationCode: 'A-01-01',
        orderDate: now,
        status: WhmsCountOrderStatus.assigned,
        productCodes: const ['SKU-1', 'SKU-2'],
        approval: WhmsApprovalStatus.approved,
        createdAt: now,
        updatedAt: now,
      );
      final map = order.toMap();
      expect(map['status'], 'assigned');
      expect(map['filter_json'], isNotNull);
      expect(map['ONAY'], 1);
      expect(map['location_code'], 'A-01-01');
      expect(map['order_date'], '2026-07-28');

      final done = order.copyWith(
        status: WhmsCountOrderStatus.completed,
        updatedAt: now.add(const Duration(hours: 1)),
      );
      expect(done.status, WhmsCountOrderStatus.completed);
      expect(done.warehouseCode, 'MRK');
    });
  });
}
