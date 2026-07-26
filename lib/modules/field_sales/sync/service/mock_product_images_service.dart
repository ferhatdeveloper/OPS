// Dosya Adı: mock_product_images_service.dart
// Açıklama: Ürün resimleri mock manifest servisi (gerçek API yokken)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../model/product_image_record.dart';
import 'product_images_service.dart';

/// {@template mock_product_images_service}
/// Gerçek ürün resmi API'si yokken kullanılan deterministik mock.
///
/// Kullanım örneği:
/// ```dart
/// final r = await MockProductImagesService().fetchImages();
/// ```
/// {@endtemplate}
class MockProductImagesService implements ProductImagesService {
  /// {@macro mock_product_images_service}
  MockProductImagesService({List<ProductImageRecord>? seed})
      : _seed = seed ?? defaultSeed;

  /// [defaultSeed]: Varsayılan örnek resim satırları
  static const List<ProductImageRecord> defaultSeed = [
    ProductImageRecord(
      productCode: 'DEMO-001',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=DEMO-001',
    ),
    ProductImageRecord(
      productCode: 'DEMO-002',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=DEMO-002',
    ),
    ProductImageRecord(
      productCode: 'DEMO-003',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=DEMO-003',
    ),
  ];

  final List<ProductImageRecord> _seed;

  @override
  Future<ProductImagesFetchResult> fetchImages() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return ProductImagesFetchResult.ok(
      images: List<ProductImageRecord>.unmodifiable(_seed),
      usedMock: true,
      messageKey: 'field_sales.product_images_mock_done',
    );
  }
}
