// Dosya Adı: shelf_price_line_test.dart
// Açıklama: Vision satırı confidence / şüpheli bayrak unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_vision_competitor/model/shelf_price_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confidence eşiği altı → isUncertain', () {
    const line = ShelfPriceLine(name: 'X', confidence: 0.4);
    expect(line.isUncertain, isTrue);
  });

  test('manuel override → şüpheli değil', () {
    const line = ShelfPriceLine(
      name: 'X',
      confidence: 0.2,
      manualOverride: true,
    );
    expect(line.isUncertain, isFalse);
  });

  test('JSON sku alanı okunur', () {
    final line = ShelfPriceLine.fromJson({
      'name': 'Süt',
      'sku': 'SKU-1',
      'price': 12.5,
      'confidence': 0.9,
    });
    expect(line.sku, 'SKU-1');
    expect(line.isUncertain, isFalse);
  });
}
