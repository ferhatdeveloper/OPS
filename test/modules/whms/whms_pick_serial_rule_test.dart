// Dosya Adı: whms_pick_serial_rule_test.dart
// Açıklama: Pick rota sırası + seri zorunluluk birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_line_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_status.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_type.dart';
import 'package:exfin_ops/modules/whms/pick/engine/whms_pick_serial_rule.dart';

WhmsOrderLineDto _line({
  required String id,
  required int lineNo,
  int? routeSeq,
  String? serialNo,
  String productId = 'p1',
  String? productCode,
  double quantity = 1,
  double quantityDone = 0,
}) {
  return WhmsOrderLineDto(
    id: id,
    orderId: 'o1',
    lineNo: lineNo,
    productId: productId,
    productCode: productCode ?? productId,
    quantity: quantity,
    quantityDone: quantityDone,
    routeSeq: routeSeq,
    serialNo: serialNo,
  );
}

WhmsOrderDto _order({
  bool requireSerial = false,
  List<WhmsOrderLineDto> lines = const [],
}) {
  return WhmsOrderDto(
    id: 'o1',
    orderType: WhmsOrderType.pick,
    status: WhmsOrderStatus.inProgress,
    orderDate: '2026-07-28',
    createdAt: '2026-07-28T00:00:00.000',
    updatedAt: '2026-07-28T00:00:00.000',
    requireSerial: requireSerial,
    lines: lines,
  );
}

void main() {
  group('WhmsPickSerialRule.sortByRouteSeq', () {
    test('route_seq ASC; null en sonda; line_no tie-break', () {
      final sorted = WhmsPickSerialRule.sortByRouteSeq([
        _line(id: 'c', lineNo: 3, routeSeq: null),
        _line(id: 'b', lineNo: 2, routeSeq: 20),
        _line(id: 'a2', lineNo: 2, routeSeq: 10),
        _line(id: 'a1', lineNo: 1, routeSeq: 10),
      ]);
      expect(sorted.map((l) => l.id).toList(), ['a1', 'a2', 'b', 'c']);
    });
  });

  group('WhmsPickSerialRule serial gate', () {
    test('emir flag → serial_no boşsa tamamlanamaz', () {
      final order = _order(
        requireSerial: true,
        lines: [_line(id: 'l1', lineNo: 1, routeSeq: 1)],
      );
      expect(WhmsPickSerialRule.canCompleteOrder(order), isFalse);
      final filled = order.copyWith(
        lines: [
          _line(id: 'l1', lineNo: 1, routeSeq: 1, serialNo: 'SN-1'),
        ],
      );
      expect(WhmsPickSerialRule.canCompleteOrder(filled), isTrue);
    });

    test('ürün kuralı → yalnız o satırda seri zorunlu', () {
      final order = _order(
        lines: [
          _line(id: 'l1', lineNo: 1, productId: 'seri-urun', routeSeq: 1),
          _line(id: 'l2', lineNo: 2, productId: 'normal', routeSeq: 2),
        ],
      );
      expect(
        WhmsPickSerialRule.canCompleteOrder(
          order,
          productIdsRequiringSerial: {'seri-urun'},
        ),
        isFalse,
      );
      final filled = order.copyWith(
        lines: [
          _line(
            id: 'l1',
            lineNo: 1,
            productId: 'seri-urun',
            routeSeq: 1,
            serialNo: 'X',
          ),
          _line(id: 'l2', lineNo: 2, productId: 'normal', routeSeq: 2),
        ],
      );
      expect(
        WhmsPickSerialRule.canCompleteOrder(
          filled,
          productIdsRequiringSerial: {'seri-urun'},
        ),
        isTrue,
      );
    });

    test('flag yok + ürün kuralı yok → seri olmadan tamamlanır', () {
      final order = _order(
        lines: [_line(id: 'l1', lineNo: 1, routeSeq: 1)],
      );
      expect(WhmsPickSerialRule.canCompleteOrder(order), isTrue);
    });
  });

  group('WhmsPickSerialRule.matchLineByProductCode', () {
    test('rota sırasındaki ilk eksik satırı tercih eder', () {
      final lines = WhmsPickSerialRule.sortByRouteSeq([
        _line(
          id: 'done',
          lineNo: 1,
          routeSeq: 1,
          productCode: 'SKU',
          quantity: 1,
          quantityDone: 1,
        ),
        _line(
          id: 'open',
          lineNo: 2,
          routeSeq: 2,
          productCode: 'SKU',
          quantity: 1,
          quantityDone: 0,
        ),
      ]);
      final hit = WhmsPickSerialRule.matchLineByProductCode(lines, 'SKU');
      expect(hit?.id, 'open');
    });
  });
}
