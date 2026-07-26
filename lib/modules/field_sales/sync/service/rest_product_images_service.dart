// Dosya Adı: rest_product_images_service.dart
// Açıklama: Ürün resimleri REST stub — 404/501'de mock fallback
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/services/logo_api_service.dart';
import '../model/product_image_record.dart';
import 'mock_product_images_service.dart';
import 'product_images_service.dart';

/// Uzak ürün resmi manifest çekici
typedef ProductImagesRemoteFetcher = Future<LogoApiResult> Function();

/// {@template rest_product_images_service}
/// `GET /api/v1/logo/erp/items/images` stub istemcisi.
/// Endpoint yoksa (404/405/501) [mockFallback] kullanılır.
///
/// Kullanım örneği:
/// ```dart
/// final s = RestProductImagesService(fetchRemote: logo.getProductImages);
/// ```
/// {@endtemplate}
class RestProductImagesService implements ProductImagesService {
  /// {@macro rest_product_images_service}
  RestProductImagesService({
    required ProductImagesRemoteFetcher fetchRemote,
    ProductImagesService? mockFallback,
  })  : _fetchRemote = fetchRemote,
        _mockFallback = mockFallback ?? MockProductImagesService();

  final ProductImagesRemoteFetcher _fetchRemote;
  final ProductImagesService _mockFallback;

  /// Endpoint henüz yok / desteklenmiyor sayılan HTTP kodları
  static const Set<int> _missingApiCodes = {404, 405, 501};

  @override
  Future<ProductImagesFetchResult> fetchImages() async {
    final remote = await _fetchRemote();
    if (remote.success) {
      final images = _mapRows(remote.asMapList());
      return ProductImagesFetchResult.ok(
        images: images,
        usedMock: false,
        messageKey: images.isEmpty
            ? 'field_sales.product_images_none'
            : 'field_sales.product_images_sync_done',
      );
    }

    final code = remote.statusCode;
    if (code != null && _missingApiCodes.contains(code)) {
      return _mockFallback.fetchImages();
    }

    return ProductImagesFetchResult.fail(
      error: remote.error ?? 'product_images_remote_failed',
      messageKey: 'field_sales.product_images_download_failed',
    );
  }

  List<ProductImageRecord> _mapRows(List<Map<String, dynamic>> rows) {
    final out = <ProductImageRecord>[];
    for (final row in rows) {
      final record = ProductImageRecord.fromMap(row);
      if (record != null) out.add(record);
    }
    return out;
  }
}
