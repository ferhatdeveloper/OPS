// Dosya Adı: finance_movement_type_test.dart
// Açıklama: Finans 7 tip API map / EN literal birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/finance_movement_type.dart';

void main() {
  group('FinanceMovementType P0-10', () {
    test('sheetTypes 7 tip', () {
      expect(FinanceMovementType.sheetTypes.length, 7);
    });

    test('EN literal → API cash/credit_card/check/note', () {
      expect(
        FinanceMovementType.fromStorage('Cash').apiCode,
        'cash',
      );
      expect(
        FinanceMovementType.fromStorage('CreditCard').apiCode,
        'credit_card',
      );
      expect(
        FinanceMovementType.fromStorage('Check').apiCode,
        'check',
      );
      expect(
        FinanceMovementType.fromStorage('Note').apiCode,
        'note',
      );
    });

    test('ödeme + virman API kodları', () {
      expect(
        FinanceMovementType.fromStorage('CashOut').apiCode,
        'CashOut',
      );
      expect(
        FinanceMovementType.fromStorage('CreditCardOut').apiCode,
        'CreditCardOut',
      );
      expect(
        FinanceMovementType.fromStorage('virman').apiCode,
        'virman',
      );
    });

    test('virman cari gerektirmez; diğerleri gerekir', () {
      expect(FinanceMovementType.virman.requiresCustomer, isFalse);
      expect(FinanceMovementType.cashCollection.requiresCustomer, isTrue);
      expect(FinanceMovementType.cashOut.requiresCustomer, isTrue);
    });

    test('normalizeApiCode legacy Cash → cash', () {
      expect(FinanceMovementType.normalizeApiCode('Cash'), 'cash');
      expect(FinanceMovementType.normalizeApiCode('cash'), 'cash');
    });

    test('kind ayrımı tahsilat/ödeme/virman', () {
      expect(
        FinanceMovementType.checkCollection.kind,
        FinanceMovementKind.collection,
      );
      expect(
        FinanceMovementType.creditCardOut.kind,
        FinanceMovementKind.payment,
      );
      expect(
        FinanceMovementType.virman.kind,
        FinanceMovementKind.virman,
      );
    });
  });
}
