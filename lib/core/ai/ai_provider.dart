// Dosya Adı: ai_provider.dart
// Açıklama: Çoklu AI sağlayıcı enum (OpenAI / Gemini / Claude / OpenRouter)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_provider}
/// Desteklenen harici LLM sağlayıcıları.
///
/// Kullanım örneği:
/// ```dart
/// final p = AiProvider.openRouter;
/// print(p.storageKey); // openrouter
/// ```
/// {@endtemplate}
enum AiProvider {
  /// OpenAI Chat Completions (api.openai.com)
  openAi,

  /// Google Gemini generateContent
  gemini,

  /// Anthropic Claude Messages API
  anthropic,

  /// OpenRouter — tek anahtarla çok model yedek yolu
  openRouter,
}

/// {@template ai_provider_x}
/// [AiProvider] yardımcı uzantılar.
/// {@endtemplate}
extension AiProviderX on AiProvider {
  /// Kalıcı depolama / prefs anahtar parçası
  String get storageKey {
    switch (this) {
      case AiProvider.openAi:
        return 'openai';
      case AiProvider.gemini:
        return 'gemini';
      case AiProvider.anthropic:
        return 'anthropic';
      case AiProvider.openRouter:
        return 'openrouter';
    }
  }

  /// l10n anahtarı: `ai.provider_<storageKey>`
  String get labelKey => 'ai.provider_$storageKey';

  /// Varsayılan chat modeli
  String get defaultModel {
    switch (this) {
      case AiProvider.openAi:
        return 'gpt-4o-mini';
      case AiProvider.gemini:
        return 'gemini-2.0-flash';
      case AiProvider.anthropic:
        return 'claude-3-5-haiku-latest';
      case AiProvider.openRouter:
        return 'openai/gpt-4o-mini';
    }
  }

  /// API taban URL (trailing slash yok)
  String get defaultBaseUrl {
    switch (this) {
      case AiProvider.openAi:
        return 'https://api.openai.com/v1';
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AiProvider.anthropic:
        return 'https://api.anthropic.com';
      case AiProvider.openRouter:
        return 'https://openrouter.ai/api/v1';
    }
  }

  /// Image generation destekleniyor mu (Claude yok)
  bool get supportsImageGeneration {
    switch (this) {
      case AiProvider.openAi:
      case AiProvider.gemini:
      case AiProvider.openRouter:
        return true;
      case AiProvider.anthropic:
        return false;
    }
  }

  /// Varsayılan image modeli
  String get defaultImageModel {
    switch (this) {
      case AiProvider.openAi:
        return 'dall-e-3';
      case AiProvider.gemini:
        return 'imagen-3.0-generate-002';
      case AiProvider.openRouter:
        return 'openai/dall-e-3';
      case AiProvider.anthropic:
        return '';
    }
  }

  /// [storageKey] → enum; bilinmeyen → null
  static AiProvider? tryParse(String? raw) {
    final k = (raw ?? '').trim().toLowerCase();
    if (k.isEmpty) return null;
    for (final p in AiProvider.values) {
      if (p.storageKey == k) return p;
    }
    return null;
  }
}
