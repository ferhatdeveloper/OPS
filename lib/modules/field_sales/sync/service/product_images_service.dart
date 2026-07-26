// Dosya Adı: product_images_service.dart
// Açıklama: Ürün resimleri aktarım arayüzü + sonuç + factory
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/services/logo_api_service.dart';
import '../model/product_image_record.dart';
import 'mock_product_images_service.dart';
import 'rest_product_images_service.dart';

/// {@template product_images_fetch_result}
/// Ürün resmi manifest çekim sonucu.
///
/// Kullanım örneği:
/// ```dart
/// final r = await service.fetchImages();
/// if (r.success) { /* r.images */ }
/// ```
/// {@endtemplate}
class ProductImagesFetchResult {
  /// {@macro product_images_fetch_result}
  const ProductImagesFetchResult({
    required this.success,
    required this.images,
    this.usedMock = false,
    this.error,
    this.messageKey,
  });

  /// Başarılı sonuç üretici
  factory ProductImagesFetchResult.ok({
    required List<ProductImageRecord> images,
    required String messageKey,
    bool usedMock = false,
  }) =>
      ProductImagesFetchResult(
        success: true,
        images: images,
        usedMock: usedMock,
        messageKey: messageKey,
      );

  /// Hata sonucu üretici
  factory ProductImagesFetchResult.fail({
    required String error,
    String messageKey = 'field_sales.product_images_download_failed',
  }) =>
      ProductImagesFetchResult(
        success: false,
        images: const [],
        error: error,
        messageKey: messageKey,
      );

  /// [success]: Çekim başarılı mı
  final bool success;

  /// [images]: Manifest satırları
  final List<ProductImageRecord> images;

  /// [usedMock]: Gerçek API yokken mock kullanıldı mı
  final bool usedMock;

  /// [error]: Hata metni (varsa)
  final String? error;

  /// [messageKey]: UI için l10n anahtarı
  final String? messageKey;
}

/// {@template product_images_service}
/// Ürün resimleri manifest istemcisi (REST veya mock).
///
/// Kullanım örneği:
/// ```dart
/// final service = ProductImagesServiceFactory.create();
/// final result = await service.fetchImages();
/// ```
/// {@endtemplate}
abstract class ProductImagesService {
  /// {@template product_images_service_fetch_images}
  /// Ürün resmi metadata listesini getirir (dosya indirmez).
  ///
  /// Dönüş değeri:
  /// - [ProductImagesFetchResult]: Manifest + mock/REST bilgisi
  /// {@endtemplate}
  Future<ProductImagesFetchResult> fetchImages();
}

/// {@template product_images_service_factory}
/// Varsayılan REST (+404 mock fallback) veya zorla mock üretir.
/// {@endtemplate}
class ProductImagesServiceFactory {
  ProductImagesServiceFactory._();

  /// {@template product_images_service_factory_create}
  /// Servis örneği üretir.
  ///
  /// Parametreler:
  /// - [forceMock]: true ise yalnızca mock
  /// - [logo]: REST istemcisi (test enjeksiyonu)
  ///
  /// Dönüş değeri:
  /// - [ProductImagesService]: Mock veya REST stub
  /// {@endtemplate}
  static ProductImagesService create({
    bool forceMock = false,
    LogoApiService? logo,
  }) {
    if (forceMock) return MockProductImagesService();
    final api = logo ?? LogoApiService();
    return RestProductImagesService(
      fetchRemote: () => api.getProductImages(),
    );
  }
}
