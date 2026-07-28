// Dosya Adı: product_fuzzy_matcher_test.dart
// Açıklama: Katalog fuzzy match unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_vision_competitor/engine/product_fuzzy_matcher.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const catalog = [
    ProductCatalogRow(
      id: '1',
      code: 'KOLA330',
      name: 'Kola 330ml',
      barcode: '8690001',
      price: 25,
    ),
    ProductCatalogRow(
      id: '2',
      code: 'SU500',
      name: 'Su 500ml',
      barcode: '8690002',
      price: 5,
    ),
  ];

  const matcher = ProductFuzzyMatcher();

  test('barkod tam eşleşme', () {
    final m = matcher.bestMatch(
      'x',
      barcode: '8690001',
      catalog: catalog,
    );
    expect(m!.product.id, '1');
    expect(m.score, 1);
  });

  test('isim fuzzy', () {
    final m = matcher.bestMatch('Kola 330', catalog: catalog);
    expect(m, isNotNull);
    expect(m!.product.code, 'KOLA330');
    expect(m.score, greaterThan(0.5));
  });

  test('eşleşme yok', () {
    final m = matcher.bestMatch('xyzabc123', catalog: catalog);
    expect(m, isNull);
  });
}
