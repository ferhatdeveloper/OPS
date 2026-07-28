// Dosya Adı: whms_fifo_rule_engine_test.dart
// Açıklama: WhmsFifoRuleEngine çıkış kapısı / FEFO pick birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/whms/engine/whms_fifo_rule_engine.dart';

void main() {
  final today = DateTime(2026, 7, 28);

  const ruleEnforce = WhmsFifoRule(
    productCode: 'SKU1',
    fifoDays: 0,
    fefoEnforce: true,
    warnDays: 30,
  );

  group('WhmsFifoRuleEngine.sortFefo', () {
    test('SKT yakından uzağa; nulls last; eşitlikte lot', () {
      final sorted = WhmsFifoRuleEngine.sortFefo([
        WhmsFifoBatch(lot: 'L3', expiry: DateTime(2026, 12, 1), qty: 1),
        WhmsFifoBatch(lot: 'L1', expiry: DateTime(2026, 9, 1), qty: 1),
        WhmsFifoBatch(lot: 'L2', expiry: DateTime(2026, 9, 1), qty: 1),
        WhmsFifoBatch(lot: 'LN', expiry: null, qty: 1),
      ]);
      expect(sorted.map((e) => e.lot).toList(), ['L1', 'L2', 'L3', 'LN']);
    });
  });

  group('WhmsFifoRuleEngine.checkOutbound', () {
    test('geçmiş SKT + fefoEnforce → block', () {
      final r = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU1',
        proposedExpiry: DateTime(2026, 6, 1),
        today: today,
        rule: ruleEnforce,
      );
      expect(r.decision, WhmsFifoOutboundDecision.block);
      expect(r.messageKey, WhmsFifoMessageKeys.blockExpired);
      expect(r.isBlocked, isTrue);
    });

    test('warnDays içinde → warn', () {
      final r = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU1',
        proposedExpiry: DateTime(2026, 8, 10),
        today: today,
        rule: ruleEnforce,
      );
      expect(r.decision, WhmsFifoOutboundDecision.warn);
      expect(r.messageKey, WhmsFifoMessageKeys.warnNearExpiry);
    });

    test('fifoDays altı kalan ömür → block', () {
      final r = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU1',
        proposedExpiry: DateTime(2026, 8, 10),
        today: today,
        rule: const WhmsFifoRule(
          productCode: 'SKU1',
          fifoDays: 60,
          fefoEnforce: true,
          warnDays: 0,
        ),
      );
      expect(r.decision, WhmsFifoOutboundDecision.block);
      expect(r.messageKey, WhmsFifoMessageKeys.blockFifoDays);
    });

    test('daha erken SKT lot varken geç seçim → block FEFO', () {
      final r = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU1',
        proposedExpiry: DateTime(2026, 12, 1),
        today: today,
        rule: ruleEnforce,
        availableBatches: [
          WhmsFifoBatch(lot: 'EARLY', expiry: DateTime(2026, 8, 15), qty: 5),
          WhmsFifoBatch(lot: 'LATE', expiry: DateTime(2026, 12, 1), qty: 5),
        ],
      );
      expect(r.decision, WhmsFifoOutboundDecision.block);
      expect(r.messageKey, WhmsFifoMessageKeys.blockFefoPreferred);
    });

    test('uygun SKT → allow', () {
      final r = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU1',
        proposedExpiry: DateTime(2026, 12, 1),
        today: today,
        rule: const WhmsFifoRule(
          productCode: 'SKU1',
          fifoDays: 0,
          fefoEnforce: true,
          warnDays: 14,
        ),
        availableBatches: [
          WhmsFifoBatch(lot: 'OK', expiry: DateTime(2026, 12, 1), qty: 5),
        ],
      );
      expect(r.decision, WhmsFifoOutboundDecision.allow);
      expect(r.messageKey, WhmsFifoMessageKeys.allow);
    });
  });

  group('WhmsFifoRuleEngine.pickFefoBatches', () {
    test('önce erken SKT lotundan alır', () {
      final plan = WhmsFifoRuleEngine.pickFefoBatches(
        qty: 7,
        today: today,
        rule: ruleEnforce,
        availableBatches: [
          WhmsFifoBatch(lot: 'LATE', expiry: DateTime(2026, 12, 1), qty: 8),
          WhmsFifoBatch(lot: 'EARLY', expiry: DateTime(2026, 8, 15), qty: 5),
        ],
      );
      expect(plan.isComplete, isTrue);
      expect(plan.fulfilledQty, 7);
      expect(plan.slices[0].batch.lot, 'EARLY');
      expect(plan.slices[0].quantity, 5);
      expect(plan.slices[1].batch.lot, 'LATE');
      expect(plan.slices[1].quantity, 2);
    });

    test('yetersiz stok → insufficient', () {
      final plan = WhmsFifoRuleEngine.pickFefoBatches(
        qty: 10,
        today: today,
        rule: ruleEnforce,
        availableBatches: [
          WhmsFifoBatch(lot: 'A', expiry: DateTime(2026, 11, 1), qty: 2),
        ],
      );
      expect(plan.isComplete, isFalse);
      expect(plan.shortfallQty, 8);
      expect(plan.messageKey, WhmsFifoMessageKeys.insufficient);
    });

    test('süresi geçmiş lot atlanır (fefoEnforce)', () {
      final plan = WhmsFifoRuleEngine.pickFefoBatches(
        qty: 5,
        today: today,
        rule: ruleEnforce,
        availableBatches: [
          WhmsFifoBatch(lot: 'EXP', expiry: DateTime(2026, 6, 1), qty: 20),
          WhmsFifoBatch(lot: 'OK', expiry: DateTime(2026, 10, 1), qty: 3),
        ],
      );
      expect(plan.fulfilledQty, 3);
      expect(plan.shortfallQty, 2);
      expect(plan.slices.single.batch.lot, 'OK');
    });
  });

  group('WhmsFifoRule.fromMap', () {
    test('snake_case kolonları parse eder', () {
      final rule = WhmsFifoRule.fromMap(const {
        'product_code': 'SKU9',
        'fifo_days': 15,
        'fefo_enforce': 1,
        'warn_days': 7,
      });
      expect(rule.productCode, 'SKU9');
      expect(rule.fifoDays, 15);
      expect(rule.fefoEnforce, isTrue);
      expect(rule.warnDays, 7);
      expect(rule.toMap()['fefo_enforce'], 1);
    });
  });
}
