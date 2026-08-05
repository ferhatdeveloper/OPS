// Dosya Adı: ai_provider_defaults.dart
// Açıklama: Özel test OpenRouter API key varsayılanı (dart-define / secret)
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'ai_provider.dart';
import 'ai_settings_store.dart';

/// {@template ai_provider_defaults}
/// Tek kullanıcılı özel test AI varsayılanları.
///
/// Key değeri kaynak koda yazılmaz. Derlemede:
/// `--dart-define=OPENROUTER_API_KEY=...` veya CI secret.
/// Halka açık dağıtımda [applyPrivateTestDefaults] kapatılmalı.
///
/// Kullanım örneği:
/// ```dart
/// await AiProviderDefaults.ensurePersisted(AiSettingsStore());
/// ```
/// {@endtemplate}
class AiProviderDefaults {
  AiProviderDefaults._();

  /// [applyPrivateTestDefaults]: dart-define key varsa yaz
  static const bool applyPrivateTestDefaults = true;

  /// [openRouterApiKey]: `--dart-define=OPENROUTER_API_KEY=...`
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  /// [activeProvider]: Varsayılan aktif sağlayıcı
  static const AiProvider activeProvider = AiProvider.openRouter;

  /// {@template ai_provider_defaults_ensure}
  /// OpenRouter key + aktif sağlayıcıyı kaydeder (özel test).
  ///
  /// Dönüş değeri:
  /// - [bool]: Yazıldıysa true
  /// {@endtemplate}
  static Future<bool> ensurePersisted(AiSettingsStore store) async {
    if (!applyPrivateTestDefaults) return false;
    final key = openRouterApiKey.trim();
    if (key.isEmpty) return false;
    await store.saveApiKey(AiProvider.openRouter, key);
    await store.setActiveProvider(activeProvider);
    await store.setEnabled(AiProvider.openRouter, true);
    return true;
  }
}
