// Dosya Adı: ai_provider_config.dart
// Açıklama: Sağlayıcı başına baseUrl / model / key-var mı yapılandırması
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'ai_provider.dart';
import 'ai_use_case.dart';

/// {@template ai_provider_config}
/// Tek sağlayıcı için çalışma zamanı yapılandırması.
/// API key değeri bu nesnede tutulmaz — yalnızca [hasApiKey] bayrağı.
///
/// Kullanım örneği:
/// ```dart
/// AiProviderConfig.defaults(AiProvider.openRouter);
/// ```
/// {@endtemplate}
class AiProviderConfig {
  /// [provider]: Sağlayıcı
  final AiProvider provider;

  /// [baseUrl]: API tabanı
  final String baseUrl;

  /// [model]: Varsayılan model id
  final String model;

  /// [hasApiKey]: Secure store’da key var mı (değer yok)
  final bool hasApiKey;

  /// [enabled]: Kullanıcı bu sağlayıcıyı etkinleştirdi mi
  final bool enabled;

  /// {@macro ai_provider_config}
  const AiProviderConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    this.hasApiKey = false,
    this.enabled = true,
  });

  /// Varsayılanlar (key yok)
  factory AiProviderConfig.defaults(AiProvider provider) => AiProviderConfig(
        provider: provider,
        baseUrl: provider.defaultBaseUrl,
        model: provider.defaultModel,
      );

  /// Kopya
  AiProviderConfig copyWith({
    String? baseUrl,
    String? model,
    bool? hasApiKey,
    bool? enabled,
  }) {
    return AiProviderConfig(
      provider: provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Wire (key hariç)
  Map<String, dynamic> toPublicMap() => {
        'provider': provider.storageKey,
        'baseUrl': baseUrl,
        'model': model,
        'hasApiKey': hasApiKey,
        'enabled': enabled,
      };
}

/// {@template ai_settings_snapshot}
/// Tüm sağlayıcılar + aktif seçim + use-case model override anlık görüntüsü.
/// {@endtemplate}
class AiSettingsSnapshot {
  /// [activeProvider]: Seçili sağlayıcı
  final AiProvider activeProvider;

  /// [configs]: Sağlayıcı → config
  final Map<AiProvider, AiProviderConfig> configs;

  /// [insightsOptIn]: Rapor AI insight opt-in
  final bool insightsOptIn;

  /// [ttsEnabled]: Sesli sohbette AI cevabını TTS ile oku (varsayılan açık)
  final bool ttsEnabled;

  /// [speechLanguage]: Konuşma dili tercihi — auto | tr | en | ar | ku | fa | de | ru
  final String speechLanguage;

  /// [ttsVoicePersona]: natural | warm_f | calm_m | device
  final String ttsVoicePersona;

  /// [cloudTtsEnabled]: OpenAI audio/speech bulut ses (varsayılan açık)
  final bool cloudTtsEnabled;

  /// [useCaseModels]: Use-case → model id (boş = sağlayıcı varsayılanı)
  final Map<AiUseCase, String> useCaseModels;

  /// {@macro ai_settings_snapshot}
  const AiSettingsSnapshot({
    required this.activeProvider,
    required this.configs,
    this.insightsOptIn = false,
    this.ttsEnabled = true,
    this.speechLanguage = 'auto',
    this.ttsVoicePersona = 'natural',
    this.cloudTtsEnabled = true,
    this.useCaseModels = const {},
  });

  /// Aktif config
  AiProviderConfig get activeConfig =>
      configs[activeProvider] ??
      AiProviderConfig.defaults(activeProvider);

  /// Aktif sağlayıcıda key var mı
  bool get hasActiveKey => activeConfig.hasApiKey;

  /// Use-case model override (yoksa null → provider model)
  String? modelOverrideFor(AiUseCase useCase) {
    final m = useCaseModels[useCase]?.trim();
    if (m == null || m.isEmpty) return null;
    return m;
  }

  /// Boş varsayılan
  factory AiSettingsSnapshot.empty() {
    final map = <AiProvider, AiProviderConfig>{};
    for (final p in AiProvider.values) {
      map[p] = AiProviderConfig.defaults(p);
    }
    return AiSettingsSnapshot(
      activeProvider: AiProvider.openRouter,
      configs: map,
    );
  }
}
