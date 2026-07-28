// Dosya Adı: ai_provider_client.dart
// Açıklama: AI sağlayıcı istemci arayüzü
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'ai_completion.dart';
import 'ai_image.dart';
import 'ai_provider.dart';
import 'ai_provider_config.dart';

/// {@template ai_provider_client}
/// Tek sağlayıcı için chat tamamlanma istemcisi.
/// {@endtemplate}
abstract class AiProviderClient {
  /// Bu istemcinin sağlayıcısı
  AiProvider get provider;

  /// {@template ai_provider_client_complete}
  /// Chat tamamlanma isteği.
  ///
  /// Parametreler:
  /// - [config]: baseUrl / model
  /// - [apiKey]: Düz API key (caller sağlar; loglanmaz)
  /// - [request]: Mesajlar
  ///
  /// Dönüş değeri:
  /// - [AiCompletionResult]: ok / error
  /// {@endtemplate}
  Future<AiCompletionResult> complete({
    required AiProviderConfig config,
    required String apiKey,
    required AiCompletionRequest request,
  });

  /// {@template ai_provider_client_generate_image}
  /// Görsel üretimi — varsayılan: desteklenmez (Claude vb.).
  ///
  /// Parametreler:
  /// - [config]: baseUrl
  /// - [apiKey]: API key (loglanmaz)
  /// - [request]: Prompt + boyut
  ///
  /// Dönüş değeri:
  /// - [AiImageResult]
  /// {@endtemplate}
  Future<AiImageResult> generateImage({
    required AiProviderConfig config,
    required String apiKey,
    required AiImageRequest request,
  }) async {
    return AiImageResult.unsupported(provider: provider);
  }
}
