// Dosya Adı: product_catalog_row.dart
// Açıklama: Ürün katalogu dens satırı — products SQLite eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template product_catalog_row}
/// Plasiyer ürün katalog dens satırı (kod · ad · barkod · birim · fiyat · stok).
///
/// Kullanım örneği:
/// ```dart
/// final row = ProductCatalogRow.fromMap(map);
/// print(row.code); // STK-001
/// ```
/// {@endtemplate}
class ProductCatalogRow {
  /// [id]: products.id
  final String id;

  /// [code]: Stok/hizmet kart kodu
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [barcode]: Barkod (opsiyonel)
  final String barcode;

  /// [unit]: Ana birim
  final String unit;

  /// [price]: Birim fiyat
  final double price;

  /// [vatRate]: KDV oranı
  final int vatRate;

  /// [stockQuantity]: Mevcut stok
  final double stockQuantity;

  /// [category]: Grup / kategori
  final String category;

  /// [imageUrl]: Opsiyonel ürün görseli URL
  final String imageUrl;

  /// {@template product_catalog_row_is_service_card}
  /// Hizmet kartı mı (kategori veya kod öneki).
  ///
  /// Dönüş değeri:
  /// - [bool]: Hizmet kartı ise true
  /// {@endtemplate}
  bool get isServiceCard {
    if (category.trim().toUpperCase() == 'HIZMET') return true;
    return code.trim().toUpperCase().startsWith('HIZ-');
  }

  /// {@macro product_catalog_row}
  const ProductCatalogRow({
    required this.id,
    required this.code,
    required this.name,
    this.barcode = '',
    this.unit = 'ADET',
    this.price = 0,
    this.vatRate = 20,
    this.stockQuantity = 0,
    this.category = '',
    this.imageUrl = '',
  });

  /// {@template product_catalog_row_from_map}
  /// Tek products satırını dens katalog satırına çevirir.
  ///
  /// Parametreler:
  /// - [map]: SQLite products satırı
  ///
  /// Dönüş değeri:
  /// - [ProductCatalogRow]: Dens satır
  /// {@endtemplate}
  factory ProductCatalogRow.fromMap(Map<String, dynamic> map) {
    return ProductCatalogRow(
      id: (map['id'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      barcode: (map['barcode'] ?? '').toString(),
      unit: (map['unit'] ?? map['main_unit'] ?? 'ADET').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      vatRate: (map['vat_rate'] as num?)?.toInt() ?? 20,
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0,
      category: (map['category'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? map['photo_url'] ?? '').toString(),
    );
  }

  /// {@template product_catalog_row_to_map}
  /// SQLite insert/replace için map üretir.
  ///
  /// Dönüş değeri:
  /// - [Map]: products kolonları
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'code': code,
      'name': name,
      'barcode': barcode.isEmpty ? null : barcode,
      'unit': unit,
      'main_unit': unit,
      'price': price,
      'vat_rate': vatRate,
      'stock_quantity': stockQuantity,
      'category': category.isEmpty ? null : category,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// {@template product_catalog_row_matches}
  /// Kod / ad / barkod içinde arama metni var mı.
  ///
  /// Parametreler:
  /// - [query]: Arama metni
  ///
  /// Dönüş değeri:
  /// - [bool]: Eşleşme
  /// {@endtemplate}
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        code.toLowerCase().contains(q) ||
        barcode.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }

  /// {@template product_catalog_row_price_text}
  /// Fiyatı TR ondalık metin olarak döner (`1.250,50`).
  ///
  /// Dönüş değeri:
  /// - [String]: Biçimli fiyat
  /// {@endtemplate}
  String get priceText {
    final fixed = price.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }

  /// {@template product_catalog_row_stock_text}
  /// Stok miktarını dens metin olarak döner.
  ///
  /// Dönüş değeri:
  /// - [String]: Stok metni
  /// {@endtemplate}
  String get stockText {
    if (stockQuantity == stockQuantity.roundToDouble()) {
      return stockQuantity.toInt().toString();
    }
    return stockQuantity.toStringAsFixed(2);
  }

  /// {@template product_catalog_row_from_maps}
  /// products map listesini ada göre sıralı dens satırlara çevirir.
  ///
  /// Parametreler:
  /// - [maps]: SQLite products satırları
  ///
  /// Dönüş değeri:
  /// - [List]: Dens katalog satırları
  /// {@endtemplate}
  static List<ProductCatalogRow> fromMaps(List<Map<String, dynamic>> maps) {
    final rows = maps.map(ProductCatalogRow.fromMap).toList();
    rows.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return a.code.toLowerCase().compareTo(b.code.toLowerCase());
    });
    return List<ProductCatalogRow>.unmodifiable(rows);
  }
}
