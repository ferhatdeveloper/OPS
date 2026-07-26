// Dosya Adı: product_catalog_row_test.dart
// Açıklama: Ürün katalog dens satırının products SQLite map eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_row.dart';

void main() {
  group('ProductCatalogRow.fromMap', () {
    test('products kolonlarını dens satıra eşler', () {
      final row = ProductCatalogRow.fromMap({
        'id': 'p1',
        'code': 'STK-001',
        'name': 'Demo Ürün',
        'barcode': '8690000000001',
        'unit': 'ADET',
        'price': 125.5,
        'vat_rate': 20,
        'stock_quantity': 48,
        'category': 'GENEL',
      });

      expect(row.id, 'p1');
      expect(row.code, 'STK-001');
      expect(row.name, 'Demo Ürün');
      expect(row.barcode, '8690000000001');
      expect(row.unit, 'ADET');
      expect(row.price, 125.5);
      expect(row.vatRate, 20);
      expect(row.stockQuantity, 48);
      expect(row.category, 'GENEL');
      expect(row.priceText, '125,50');
      expect(row.stockText, '48');
    });

    test('unit yoksa main_unit; yoksa ADET', () {
      final fromMain = ProductCatalogRow.fromMap({
        'id': 'p2',
        'code': 'X',
        'name': 'Y',
        'main_unit': 'KOLI',
      });
      expect(fromMain.unit, 'KOLI');

      final fallback = ProductCatalogRow.fromMap({
        'id': 'p3',
        'code': 'X',
        'name': 'Y',
      });
      expect(fallback.unit, 'ADET');
    });
  });

  group('ProductCatalogRow.matches', () {
    const row = ProductCatalogRow(
      id: 'p1',
      code: 'STK-001',
      name: 'Demo İçecek',
      barcode: '8690000000003',
      category: 'ICECEK',
    );

    test('kod / ad / barkod / kategori eşleşir', () {
      expect(row.matches('stk'), isTrue);
      expect(row.matches('içecek'), isTrue);
      expect(row.matches('8690000000003'), isTrue);
      expect(row.matches('ice'), isTrue);
      expect(row.matches('yok'), isFalse);
      expect(row.matches(''), isTrue);
    });
  });

  group('ProductCatalogRow.fromMaps', () {
    test('ada göre artan sıralar', () {
      final rows = ProductCatalogRow.fromMaps([
        {'id': '2', 'code': 'B', 'name': 'Beta'},
        {'id': '1', 'code': 'A', 'name': 'Alpha'},
        {'id': '3', 'code': 'C', 'name': 'alpha'},
      ]);
      expect(rows.map((r) => r.id).toList(), ['1', '3', '2']);
    });
  });
}
