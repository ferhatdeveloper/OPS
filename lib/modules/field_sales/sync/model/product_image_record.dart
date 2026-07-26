// Dosya Adı: product_image_record.dart
// Açıklama: Ürün resmi aktarım satırı (kod + URL)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template product_image_record}
/// Sunucu/mock ürün resmi metadata satırı.
///
/// Kullanım örneği:
/// ```dart
/// const ProductImageRecord(
///   productCode: 'SKU-1',
///   imageUrl: 'https://cdn.example/sku-1.jpg',
/// );
/// ```
/// {@endtemplate}
class ProductImageRecord {
  /// {@macro product_image_record}
  const ProductImageRecord({
    required this.productCode,
    required this.imageUrl,
    this.checksum,
    this.updatedAt,
  });

  /// [productCode]: Yerel `products.code` ile eşleşen ürün kodu
  final String productCode;

  /// [imageUrl]: İndirilebilir / gösterilebilir resim URL'si
  final String imageUrl;

  /// [checksum]: İsteğe bağlı içerik özeti (değişiklik kontrolü)
  final String? checksum;

  /// [updatedAt]: Kaynak tarafındaki son güncelleme
  final DateTime? updatedAt;

  /// {@template product_image_record_from_map}
  /// REST/mock JSON satırından kayıt üretir; eksik alanlarda null.
  ///
  /// Parametreler:
  /// - [map]: CODE / IMAGE_URL veya snake_case alternatifleri
  ///
  /// Dönüş değeri:
  /// - [ProductImageRecord]: Geçerli satır; kod/url boşsa null
  /// {@endtemplate}
  static ProductImageRecord? fromMap(Map<String, dynamic> map) {
    final code = (map['CODE'] ??
            map['code'] ??
            map['product_code'] ??
            map['PRODUCT_CODE'] ??
            map['item_code'] ??
            '')
        .toString()
        .trim();
    final url = (map['IMAGE_URL'] ??
            map['image_url'] ??
            map['url'] ??
            map['URL'] ??
            map['photo_url'] ??
            '')
        .toString()
        .trim();
    if (code.isEmpty || url.isEmpty) return null;

    DateTime? updatedAt;
    final rawUpdated = map['updated_at'] ?? map['UPDATED_AT'];
    if (rawUpdated is String && rawUpdated.isNotEmpty) {
      updatedAt = DateTime.tryParse(rawUpdated);
    }

    return ProductImageRecord(
      productCode: code,
      imageUrl: url,
      checksum: (map['checksum'] ?? map['CHECKSUM'])?.toString(),
      updatedAt: updatedAt,
    );
  }
}
