// Dosya Adı: price_text_parser_test.dart
// Açıklama: Raf fiyat metin parse unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_vision_competitor/engine/price_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriceTextParser', () {
    test('virgül ondalık TR', () {
      expect(PriceTextParser.parse('12,50 TL'), 12.5);
      expect(PriceTextParser.parse('₺15,99'), 15.99);
    });

    test('nokta ondalık', () {
      expect(PriceTextParser.parse('9.90'), 9.9);
    });

    test('binlik ayracı', () {
      expect(PriceTextParser.parse('1.250,00'), 1250.0);
      expect(PriceTextParser.parse('1,250.50'), 1250.5);
    });

    test('geçersiz', () {
      expect(PriceTextParser.parse(''), isNull);
      expect(PriceTextParser.parse('abc'), isNull);
    });
  });
}
