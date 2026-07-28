// Dosya Adı: whms_fifo_rule_engine_test.dart
// Açıklama: FIFO/FEFO motor smoke (detay: engine/ alt paketi)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/whms/engine/whms_fifo_rule_engine.dart';

void main() {
  group('WhmsFifoRuleEngine smoke', () {
    const rule = WhmsFifoRule(
      productCode: 'SKU1',
      fifoDays: 0,
      fefoEnforce: true,
      warnDays: 14,
    );

    test('FEFO picks earliest expiry first', () {
      final plan = WhmsFifoRuleEngine.pickFefoBatches(
        qty: 5,
        today: DateTime(2026, 7, 28),
        rule: rule,
        availableBatches: [
          WhmsFifoBatch(
            lot: 'L2',
            expiry: DateTime(2026, 12, 1),
            qty: 10,
          ),
          WhmsFifoBatch(
            lot: 'L1',
            expiry: DateTime(2026, 8, 1),
            qty: 4,
          ),
        ],
      );
      expect(plan.slices.first.batch.lot, 'L1');
      expect(plan.slices.first.quantity, 4);
      expect(plan.fulfilledQty, 5);
      expect(plan.shortfallQty, 0);
    });

    test('expired batch blocks outbound when fefoEnforce', () {
      final r = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU1',
        proposedExpiry: DateTime(2026, 7, 1),
        today: DateTime(2026, 7, 28),
        rule: rule,
      );
      expect(r.decision, WhmsFifoOutboundDecision.block);
      expect(r.messageKey, WhmsFifoMessageKeys.blockExpired);
    });
  });
}
