// Dosya Adı: ai_openai_tts_voice.dart
// Açıklama: Persona → OpenAI audio/speech voice eşlemesi + bulut TTS politika
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'ai_tts_voice.dart';

/// {@template ai_openai_tts_voice_mapper}
/// [AiTtsVoicePersona] → OpenAI TTS voice id.
///
/// Kullanım örneği:
/// ```dart
/// final v = AiOpenAiTtsVoiceMapper.voiceId(AiTtsVoicePersona.warmF);
/// // shimmer
/// ```
/// {@endtemplate}
class AiOpenAiTtsVoiceMapper {
  /// {@macro ai_openai_tts_voice_mapper}
  const AiOpenAiTtsVoiceMapper._();

  /// Varsayılan OpenAI TTS modeli (insansı, çok dilli)
  static const String defaultModel = 'gpt-4o-mini-tts';

  /// Yedek model (instructions desteklemez)
  static const String fallbackModel = 'tts-1';

  /// {@template ai_openai_tts_voice_mapper_voice_id}
  /// Persona için OpenAI voice. [device] → null (bulut yok).
  ///
  /// Dönüş değeri:
  /// - [String?]: nova / shimmer / onyx veya null
  /// {@endtemplate}
  static String? voiceId(AiTtsVoicePersona persona) {
    switch (persona) {
      case AiTtsVoicePersona.natural:
        return 'nova';
      case AiTtsVoicePersona.warmF:
        return 'shimmer';
      case AiTtsVoicePersona.calmM:
        return 'onyx';
      case AiTtsVoicePersona.device:
        return null;
    }
  }

  /// gpt-4o-mini-tts için kısa konuşma stili yönergesi
  static String? instructions(AiTtsVoicePersona persona) {
    switch (persona) {
      case AiTtsVoicePersona.natural:
        return 'Speak naturally and clearly, like a helpful field assistant.';
      case AiTtsVoicePersona.warmF:
        return 'Speak warmly and friendly, with a gentle female tone.';
      case AiTtsVoicePersona.calmM:
        return 'Speak calmly and steadily, with a composed male tone.';
      case AiTtsVoicePersona.device:
        return null;
    }
  }
}

/// {@template ai_tts_cloud_policy}
/// Bulut TTS denensin mi — saf karar (test edilebilir).
/// {@endtemplate}
class AiTtsCloudPolicy {
  /// {@macro ai_tts_cloud_policy}
  const AiTtsCloudPolicy._();

  /// {@template ai_tts_cloud_policy_should_attempt}
  /// Bulut denemesi: TTS açık + bulut açık + persona≠device + OpenAI key.
  ///
  /// Parametreler:
  /// - [ttsEnabled]: Genel TTS
  /// - [cloudTtsEnabled]: OpenAI bulut tercihi
  /// - [persona]: Konuşmacı
  /// - [hasOpenAiKey]: OpenAI API key var mı
  ///
  /// Dönüş değeri:
  /// - [bool]: true → önce bulut
  /// {@endtemplate}
  static bool shouldAttemptCloud({
    required bool ttsEnabled,
    required bool cloudTtsEnabled,
    required AiTtsVoicePersona persona,
    required bool hasOpenAiKey,
  }) {
    if (!ttsEnabled || !cloudTtsEnabled) return false;
    if (persona == AiTtsVoicePersona.device) return false;
    if (!hasOpenAiKey) return false;
    return AiOpenAiTtsVoiceMapper.voiceId(persona) != null;
  }
}
