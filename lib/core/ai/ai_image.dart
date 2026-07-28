// Dosya Adı: ai_image.dart
// Açıklama: AI görsel üretimi isteği / sonucu (offline-safe)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:typed_data';

import 'ai_provider.dart';

/// {@template ai_image_status}
/// Görsel üretimi sonucu durumu.
/// {@endtemplate}
enum AiImageStatus {
  /// Başarılı bytes
  ok,

  /// API key yok (no-op)
  noKey,

  /// Sağlayıcı image desteklemiyor
  unsupported,

  /// Ağ / HTTP / parse hatası
  error,
}

/// {@template ai_image_request}
/// Sağlayıcıdan bağımsız görsel üretimi isteği.
/// {@endtemplate}
class AiImageRequest {
  /// [prompt]: Metin prompt
  final String prompt;

  /// [width]: Hedef genişlik (px)
  final int width;

  /// [height]: Hedef yükseklik (px)
  final int height;

  /// [model]: Boş → sağlayıcı varsayılan image modeli
  final String? model;

  /// [productImageUrl]: Opsiyonel ürün görseli URL (referans)
  final String? productImageUrl;

  /// [productImageBytes]: Opsiyonel ürün görseli bytes
  final Uint8List? productImageBytes;

  /// {@macro ai_image_request}
  const AiImageRequest({
    required this.prompt,
    required this.width,
    required this.height,
    this.model,
    this.productImageUrl,
    this.productImageBytes,
  });

  /// API size string (`1024x1024`)
  String get sizeLabel => '${width}x$height';
}

/// {@template ai_image_result}
/// Görsel üretimi sonucu.
/// {@endtemplate}
class AiImageResult {
  /// [status]: Durum
  final AiImageStatus status;

  /// [bytes]: PNG/JPEG bytes (ok ise)
  final Uint8List? bytes;

  /// [mimeType]: MIME (varsayılan image/png)
  final String? mimeType;

  /// [provider]: Kullanılan sağlayıcı
  final AiProvider? provider;

  /// [model]: Kullanılan model
  final String? model;

  /// [errorMessage]: Ham hata
  final String? errorMessage;

  /// [l10nKey]: UI mesaj anahtarı
  final String? l10nKey;

  /// {@macro ai_image_result}
  const AiImageResult({
    required this.status,
    this.bytes,
    this.mimeType,
    this.provider,
    this.model,
    this.errorMessage,
    this.l10nKey,
  });

  /// Key yok
  factory AiImageResult.noKey({AiProvider? provider}) => AiImageResult(
        status: AiImageStatus.noKey,
        provider: provider,
        l10nKey: 'ai.no_api_key',
      );

  /// Desteklenmiyor
  factory AiImageResult.unsupported({AiProvider? provider}) => AiImageResult(
        status: AiImageStatus.unsupported,
        provider: provider,
        l10nKey: 'ai.image_unsupported',
      );

  /// Başarı
  factory AiImageResult.ok({
    required Uint8List bytes,
    required AiProvider provider,
    required String model,
    String mimeType = 'image/png',
  }) =>
      AiImageResult(
        status: AiImageStatus.ok,
        bytes: bytes,
        mimeType: mimeType,
        provider: provider,
        model: model,
      );

  /// Hata
  factory AiImageResult.error({
    String? message,
    AiProvider? provider,
    String l10nKey = 'ai.request_failed',
  }) =>
      AiImageResult(
        status: AiImageStatus.error,
        errorMessage: message,
        provider: provider,
        l10nKey: l10nKey,
      );

  /// Başarılı mı
  bool get isOk =>
      status == AiImageStatus.ok && bytes != null && bytes!.isNotEmpty;
}
