// Dosya Adı: product_images_service_test.dart
// Açıklama: Ürün resimleri servisi (interface / mock / REST stub) birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/core/services/logo_api_service.dart';
import 'package:exfin_ops/modules/field_sales/sync/model/product_image_record.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/mock_product_images_service.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/product_images_service.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/rest_product_images_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockProductImagesService', () {
    test('manifest döner ve usedMock true olur', () async {
      final service = MockProductImagesService();
      final result = await service.fetchImages();

      expect(result.success, isTrue);
      expect(result.usedMock, isTrue);
      expect(result.images, isNotEmpty);
      expect(result.messageKey, 'field_sales.product_images_mock_done');
      for (final img in result.images) {
        expect(img.productCode, isNotEmpty);
        expect(img.imageUrl, startsWith('http'));
      }
    });

    test('özel seed listesi kullanılır', () async {
      final seed = [
        const ProductImageRecord(
          productCode: 'SKU-1',
          imageUrl: 'https://example.com/1.png',
        ),
      ];
      final result = await MockProductImagesService(seed: seed).fetchImages();

      expect(result.images.single.productCode, 'SKU-1');
      expect(result.images.single.imageUrl, 'https://example.com/1.png');
    });
  });

  group('RestProductImagesService', () {
    test('REST başarılıysa mock kullanılmaz', () async {
      final service = RestProductImagesService(
        fetchRemote: () async => LogoApiResult.ok([
          {
            'CODE': 'P100',
            'IMAGE_URL': 'https://cdn.example/p100.jpg',
          },
        ]),
      );

      final result = await service.fetchImages();

      expect(result.success, isTrue);
      expect(result.usedMock, isFalse);
      expect(result.images, hasLength(1));
      expect(result.images.first.productCode, 'P100');
      expect(result.images.first.imageUrl, 'https://cdn.example/p100.jpg');
      expect(result.messageKey, 'field_sales.product_images_sync_done');
    });

    test('API 404 ise mock fallback', () async {
      final service = RestProductImagesService(
        fetchRemote: () async => LogoApiResult.fail(
          'Not Found',
          statusCode: 404,
        ),
        mockFallback: MockProductImagesService(
          seed: const [
            ProductImageRecord(
              productCode: 'MOCK-1',
              imageUrl: 'https://example.com/mock.png',
            ),
          ],
        ),
      );

      final result = await service.fetchImages();

      expect(result.success, isTrue);
      expect(result.usedMock, isTrue);
      expect(result.images.single.productCode, 'MOCK-1');
      expect(result.messageKey, 'field_sales.product_images_mock_done');
    });

    test('API 501 ise mock fallback', () async {
      final service = RestProductImagesService(
        fetchRemote: () async => LogoApiResult.fail(
          'Not Implemented',
          statusCode: 501,
        ),
      );

      final result = await service.fetchImages();

      expect(result.success, isTrue);
      expect(result.usedMock, isTrue);
    });

    test('auth/ağ hatasında mock yok — hata döner', () async {
      final service = RestProductImagesService(
        fetchRemote: () async => LogoApiResult.fail(
          'Unauthorized',
          statusCode: 401,
        ),
      );

      final result = await service.fetchImages();

      expect(result.success, isFalse);
      expect(result.usedMock, isFalse);
      expect(result.error, contains('Unauthorized'));
      expect(result.messageKey, 'field_sales.product_images_download_failed');
    });

    test('snake_case ve alternatif alan adlarını map eder', () async {
      final service = RestProductImagesService(
        fetchRemote: () async => LogoApiResult.ok({
          'items': [
            {
              'product_code': 'A1',
              'image_url': 'https://cdn/a1.webp',
            },
            {
              'code': 'B2',
              'url': 'https://cdn/b2.webp',
            },
          ],
        }),
      );

      final result = await service.fetchImages();

      expect(result.success, isTrue);
      expect(result.images, hasLength(2));
      expect(result.images[0].productCode, 'A1');
      expect(result.images[1].productCode, 'B2');
    });

    test('boş kod veya url satırları atlanır', () async {
      final service = RestProductImagesService(
        fetchRemote: () async => LogoApiResult.ok([
          {'CODE': '', 'IMAGE_URL': 'https://x'},
          {'CODE': 'OK', 'IMAGE_URL': ''},
          {'CODE': 'GOOD', 'IMAGE_URL': 'https://ok'},
        ]),
      );

      final result = await service.fetchImages();

      expect(result.images, hasLength(1));
      expect(result.images.first.productCode, 'GOOD');
    });
  });

  group('ProductImagesServiceFactory', () {
    test('forceMock true ise MockProductImagesService üretir', () {
      final service = ProductImagesServiceFactory.create(forceMock: true);
      expect(service, isA<MockProductImagesService>());
    });

    test('varsayılan RestProductImagesService üretir', () {
      final service = ProductImagesServiceFactory.create();
      expect(service, isA<RestProductImagesService>());
    });
  });
}
