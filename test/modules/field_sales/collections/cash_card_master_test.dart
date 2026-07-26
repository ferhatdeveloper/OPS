// Dosya Adı: cash_card_master_test.dart
// Açıklama: Kasa kart master kod / filtre birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_master.dart';

void main() {
  group('CashCardMaster', () {
    test('MBT sıra ve varsayılan kod', () {
      expect(CashCardMaster.codes, [
        '100 01 01',
        '100 01 02',
        '100 01 03',
        '200 01 01',
      ]);
      expect(CashCardMaster.defaultCode, '100 01 01');
      expect(CashCardMaster.contains('100 01 01'), isTrue);
      expect(CashCardMaster.contains('NOPE'), isFalse);
      expect(CashCardMaster.contains(null), isFalse);
    });

    test('byCode eşleşmesi', () {
      final opt = CashCardMaster.byCode('100 01 01');
      expect(opt, isNotNull);
      expect(opt!.l10nKey, 'field_sales.cash_card_merkez_tl');
      expect(CashCardMaster.byCode(' 200 01 01 '), isNotNull);
    });
  });
}
