// Dosya Adı: ai_settings_store.dart
// Açıklama: AI API key + model + aktif sağlayıcı + use-case override depolama
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/remember_me_crypto.dart';
import 'ai_provider.dart';
import 'ai_provider_config.dart';
import 'ai_use_case.dart';
import 'voice/ai_speech_language_detector.dart';
import 'voice/ai_tts_voice.dart';

/// {@template ai_settings_store}
/// AI ayarları: API key’ler [RememberMeCrypto] ile obfuscate edilerek
/// SharedPreferences’ta saklanır (OS keychain migration sonraki faz).
/// Key değeri asla loglanmaz; snapshot’ta yalnızca hasApiKey.
///
/// Kullanım örneği:
/// ```dart
/// final store = AiSettingsStore();
/// await store.saveApiKey(AiProvider.openAi, 'sk-...');
/// ```
/// {@endtemplate}
class AiSettingsStore {
  /// [_prefs]: Test inject
  final Future<SharedPreferences> Function()? _prefsFactory;

  /// Obfuscation tohumu (cihaz bağımsız app salt)
  static const String _keyMaterial = 'exfinops.ai.secrets.v1';

  static const String _prefActive = 'ai_active_provider';
  static const String _prefInsights = 'ai_insights_opt_in';
  static const String _prefTts = 'ai_tts_enabled';
  static const String _prefSpeechLang = 'ai_speech_language';
  static const String _prefTtsVoice = 'ai_tts_voice_persona';
  static const String _prefCloudTts = 'ai_cloud_tts_enabled';

  /// {@macro ai_settings_store}
  AiSettingsStore({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory;

  Future<SharedPreferences> _prefs() async {
    final factory = _prefsFactory;
    if (factory != null) return factory();
    return SharedPreferences.getInstance();
  }

  String _keyPref(AiProvider p) => 'ai_api_key_${p.storageKey}';
  String _modelPref(AiProvider p) => 'ai_model_${p.storageKey}';
  String _basePref(AiProvider p) => 'ai_base_url_${p.storageKey}';
  String _enabledPref(AiProvider p) => 'ai_enabled_${p.storageKey}';
  String _useCaseModelPref(AiUseCase u) =>
      'ai_usecase_model_${u.storageKey}';

  /// {@template ai_settings_store_load}
  /// Tüm ayar anlık görüntüsü (key değerleri yok, yalnızca hasApiKey).
  /// {@endtemplate}
  Future<AiSettingsSnapshot> loadSnapshot() async {
    final prefs = await _prefs();
    final active = AiProviderX.tryParse(prefs.getString(_prefActive)) ??
        AiProvider.openRouter;
    final map = <AiProvider, AiProviderConfig>{};
    for (final p in AiProvider.values) {
      final cipher = prefs.getString(_keyPref(p)) ?? '';
      final hasKey = cipher.trim().isNotEmpty;
      final model = prefs.getString(_modelPref(p))?.trim();
      final base = prefs.getString(_basePref(p))?.trim();
      final enabled = prefs.getBool(_enabledPref(p)) ?? true;
      map[p] = AiProviderConfig(
        provider: p,
        baseUrl: (base != null && base.isNotEmpty) ? base : p.defaultBaseUrl,
        model: (model != null && model.isNotEmpty) ? model : p.defaultModel,
        hasApiKey: hasKey,
        enabled: enabled,
      );
    }
    final useCaseModels = <AiUseCase, String>{};
    for (final u in AiUseCase.values) {
      final m = prefs.getString(_useCaseModelPref(u))?.trim();
      if (m != null && m.isNotEmpty) {
        useCaseModels[u] = m;
      }
    }
    return AiSettingsSnapshot(
      activeProvider: active,
      configs: map,
      insightsOptIn: prefs.getBool(_prefInsights) ?? false,
      // Varsayılan: TTS açık (pref yoksa true)
      ttsEnabled: prefs.getBool(_prefTts) ?? true,
      speechLanguage: AiSpeechLanguageDetector.normalizePreference(
        prefs.getString(_prefSpeechLang),
      ),
      ttsVoicePersona:
          AiTtsVoicePersonaX.parse(prefs.getString(_prefTtsVoice)).storageKey,
      // Varsayılan: OpenAI bulut TTS açık (key yoksa cihaz fallback)
      cloudTtsEnabled: prefs.getBool(_prefCloudTts) ?? true,
      useCaseModels: useCaseModels,
    );
  }

  /// Aktif sağlayıcıyı kaydet
  Future<void> setActiveProvider(AiProvider provider) async {
    final prefs = await _prefs();
    await prefs.setString(_prefActive, provider.storageKey);
  }

  /// Rapor insight opt-in
  Future<void> setInsightsOptIn(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_prefInsights, value);
  }

  /// {@template ai_settings_store_set_tts_enabled}
  /// Sesli sohbet TTS (AI cevabını oku). Varsayılan açık.
  /// {@endtemplate}
  Future<void> setTtsEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_prefTts, value);
  }

  /// {@template ai_settings_store_set_speech_language}
  /// Konuşma dili (TTS+STT). `auto` veya tr/en/ar/ku/fa/de/ru.
  /// {@endtemplate}
  Future<void> setSpeechLanguage(String value) async {
    final prefs = await _prefs();
    final normalized = AiSpeechLanguageDetector.normalizePreference(value);
    await prefs.setString(_prefSpeechLang, normalized);
  }

  /// {@template ai_settings_store_set_tts_voice}
  /// TTS konuşmacı stili (natural / warm_f / calm_m / device).
  /// {@endtemplate}
  Future<void> setTtsVoicePersona(String value) async {
    final prefs = await _prefs();
    final persona = AiTtsVoicePersonaX.parse(value);
    await prefs.setString(_prefTtsVoice, persona.storageKey);
  }

  /// {@template ai_settings_store_set_cloud_tts}
  /// OpenAI bulut TTS (audio/speech). Kapalıysa yalnızca cihaz.
  /// {@endtemplate}
  Future<void> setCloudTtsEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_prefCloudTts, value);
  }

  /// Model kaydet
  Future<void> saveModel(AiProvider provider, String model) async {
    final prefs = await _prefs();
    final m = model.trim();
    if (m.isEmpty) {
      await prefs.remove(_modelPref(provider));
    } else {
      await prefs.setString(_modelPref(provider), m);
    }
  }

  /// {@template ai_settings_store_save_usecase_model}
  /// Use-case bazlı model override. Boş → sil (sağlayıcı varsayılanı).
  /// {@endtemplate}
  Future<void> saveUseCaseModel(AiUseCase useCase, String model) async {
    final prefs = await _prefs();
    final m = model.trim();
    if (m.isEmpty) {
      await prefs.remove(_useCaseModelPref(useCase));
    } else {
      await prefs.setString(_useCaseModelPref(useCase), m);
    }
  }

  /// Base URL kaydet (boş → varsayılan)
  Future<void> saveBaseUrl(AiProvider provider, String baseUrl) async {
    final prefs = await _prefs();
    final b = baseUrl.trim();
    if (b.isEmpty || b == provider.defaultBaseUrl) {
      await prefs.remove(_basePref(provider));
    } else {
      await prefs.setString(_basePref(provider), b);
    }
  }

  /// Sağlayıcı etkinlik
  Future<void> setEnabled(AiProvider provider, bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_enabledPref(provider), enabled);
  }

  /// {@template ai_settings_store_save_api_key}
  /// API key’i obfuscate ederek kaydet. Boş → sil.
  ///
  /// Parametreler:
  /// - [provider]: Sağlayıcı
  /// - [plainKey]: Düz key (bellekte kısa ömürlü)
  /// {@endtemplate}
  Future<void> saveApiKey(AiProvider provider, String plainKey) async {
    final prefs = await _prefs();
    final plain = plainKey.trim();
    if (plain.isEmpty) {
      await prefs.remove(_keyPref(provider));
      return;
    }
    final cipher = RememberMeCrypto.encrypt(
      plain,
      keyMaterial: _keyMaterial,
    );
    final ok = await prefs.setString(_keyPref(provider), cipher);
    if (!ok) {
      throw StateError('ai_api_key_persist_failed');
    }
    // Key değeri asla loglanmaz (audit).
  }

  /// {@template ai_settings_store_read_api_key}
  /// Düz API key (yalnızca gateway/client için).
  ///
  /// Dönüş değeri:
  /// - [String?]: Key yoksa null
  /// {@endtemplate}
  Future<String?> readApiKey(AiProvider provider) async {
    final prefs = await _prefs();
    final cipher = prefs.getString(_keyPref(provider)) ?? '';
    if (cipher.trim().isEmpty) return null;
    final plain = RememberMeCrypto.decrypt(
      cipher,
      keyMaterial: _keyMaterial,
    );
    if (plain.trim().isEmpty) return null;
    return plain;
  }

  /// Key sil
  Future<void> clearApiKey(AiProvider provider) async {
    await saveApiKey(provider, '');
  }
}
