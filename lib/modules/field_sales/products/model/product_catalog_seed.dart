// Dosya Adı: product_catalog_seed.dart
// Açıklama: MBT Ürün Katalog dens listesi için products seed satırları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'product_catalog_row.dart';

/// {@template product_catalog_seed}
/// MBT STOK / ürün seçim dens stub seed (SQLite `products` boşken).
///
/// Kullanım örneği:
/// ```dart
/// final rows = ProductCatalogSeed.defaultRows;
/// ```
/// {@endtemplate}
class ProductCatalogSeed {
  ProductCatalogSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/product-catalog';

  /// [submenuTitle]: Menü seed alt başlık (MBT: Ürün Listesi / Stok Kart)
  static const String submenuTitle = 'Ürün Listesi';

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'products';

  /// Yer tutucu dens satırlar (stok + hizmet kartı örnekleri).
  static const List<ProductCatalogRow> defaultRows = [
    ProductCatalogRow(
      id: 'prod_seed_stk_001',
      code: 'STK-001',
      name: 'Demo Stok Kartı A',
      barcode: '8690000000001',
      unit: 'ADET',
      price: 125.5,
      vatRate: 20,
      stockQuantity: 48,
      category: 'GENEL',
    ),
    ProductCatalogRow(
      id: 'prod_seed_stk_002',
      code: 'STK-002',
      name: 'Demo Stok Kartı B',
      barcode: '8690000000002',
      unit: 'KOLI',
      price: 890,
      vatRate: 20,
      stockQuantity: 12,
      category: 'GENEL',
    ),
    ProductCatalogRow(
      id: 'prod_seed_stk_003',
      code: 'STK-003',
      name: 'Demo İçecek 1L',
      barcode: '8690000000003',
      unit: 'ADET',
      price: 45.75,
      vatRate: 10,
      stockQuantity: 120,
      category: 'ICECEK',
    ),
    ProductCatalogRow(
      id: 'prod_seed_hiz_001',
      code: 'HIZ-001',
      name: 'Demo Hizmet Kartı',
      barcode: '',
      unit: 'ADET',
      price: 250,
      vatRate: 20,
      stockQuantity: 0,
      category: 'HIZMET',
    ),
  ];
}
