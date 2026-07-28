// Dosya Adı: ai_completion.dart
// Açıklama: Ortak AI tamamlanma isteği / sonucu / hata kodları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'ai_chat_message.dart';
import 'ai_provider.dart';

/// {@template ai_completion_status}
/// Gateway tamamlanma sonucu durumu.
/// {@endtemplate}
enum AiCompletionStatus {
  /// Başarılı metin
  ok,

  /// Aktif sağlayıcıda API key yok (sessiz no-op)
  noKey,

  /// Ağ / HTTP / parse hatası
  error,

  /// İstek iptal / timeout
  cancelled,
}

/// {@template ai_completion_request}
/// Sağlayıcıdan bağımsız chat tamamlanma isteği.
/// {@endtemplate}
class AiCompletionRequest {
  /// [messages]: Konuşma geçmişi
  final List<AiChatMessage> messages;

  /// [model]: Boş → ayarlardaki varsayılan
  final String? model;

  /// [temperature]: Opsiyonel
  final double? temperature;

  /// [maxTokens]: Opsiyonel üst sınır
  final int? maxTokens;

  /// {@macro ai_completion_request}
  const AiCompletionRequest({
    required this.messages,
    this.model,
    this.temperature,
    this.maxTokens,
  });
}

/// {@template ai_completion_result}
/// Gateway tamamlanma sonucu (offline-safe).
/// {@endtemplate}
class AiCompletionResult {
  /// [status]: Durum
  final AiCompletionStatus status;

  /// [text]: Asistan metni (ok ise)
  final String? text;

  /// [provider]: Kullanılan sağlayıcı
  final AiProvider? provider;

  /// [model]: Kullanılan model
  final String? model;

  /// [errorMessage]: Ham hata (log; UI’da l10n tercih)
  final String? errorMessage;

  /// [l10nKey]: UI mesaj anahtarı (noKey / error)
  final String? l10nKey;

  /// {@macro ai_completion_result}
  const AiCompletionResult({
    required this.status,
    this.text,
    this.provider,
    this.model,
    this.errorMessage,
    this.l10nKey,
  });

  /// Key yok no-op
  factory AiCompletionResult.noKey({AiProvider? provider}) =>
      AiCompletionResult(
        status: AiCompletionStatus.noKey,
        provider: provider,
        l10nKey: 'ai.no_api_key',
      );

  /// Başarı
  factory AiCompletionResult.ok({
    required String text,
    required AiProvider provider,
    required String model,
  }) =>
      AiCompletionResult(
        status: AiCompletionStatus.ok,
        text: text,
        provider: provider,
        model: model,
      );

  /// Hata
  factory AiCompletionResult.error({
    String? message,
    AiProvider? provider,
    String l10nKey = 'ai.request_failed',
  }) =>
      AiCompletionResult(
        status: AiCompletionStatus.error,
        errorMessage: message,
        provider: provider,
        l10nKey: l10nKey,
      );

  /// Başarılı mı
  bool get isOk => status == AiCompletionStatus.ok && (text ?? '').isNotEmpty;
}
