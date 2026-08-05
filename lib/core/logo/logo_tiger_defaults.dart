// Dosya Adı: logo_tiger_defaults.dart
// Açıklama: Özel test Logo Tiger REST varsayılan kimlik / host (halka açık değil)
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'logo_tiger_config.dart';
import 'logo_tiger_urls.dart';

/// {@template logo_tiger_defaults}
/// Tek kullanıcılı özel test varsayılanları (RetailEX ile aynı canlı sunucu).
///
/// Halka açık / mağaza dağıtımında [applyPrivateTestDefaults] kapatılmalı.
///
/// Kullanım örneği:
/// ```dart
/// final cfg = LogoTigerDefaults.fillEmpty(const LogoTigerConfig(baseUrl: ''));
/// ```
/// {@endtemplate}
class LogoTigerDefaults {
  LogoTigerDefaults._();

  /// [applyPrivateTestDefaults]: Boş alanlara test kimliğini yaz
  static const bool applyPrivateTestDefaults = true;

  /// [apiKey]: Help / query api_key
  static const String apiKey = 'logotigerrestservice';

  /// [clientId]: OAuth client_id
  static const String clientId = 'ARZEN';

  /// [clientSecret]: OAuth client_secret
  static const String clientSecret =
      'r1k1C+lyPK6BKFkrLdA3IFXawk2fiuFdCqbrMc5zQd8=';

  /// [username]: Logo ERP kullanıcısı
  static const String username = 'LOGO';

  /// [password]: Logo ERP şifresi
  static const String password = '2661';

  /// [firmNr]: Firma no
  static const int firmNr = 1;

  /// [periodNr]: Dönem no
  static const int periodNr = 1;

  /// Normalize `/api/v1` taban (varsayılan host + port).
  static String get baseUrl =>
      LogoTigerUrls.composeBaseUrl(LogoTigerUrls.defaultHost);

  /// Tam dolu test yapılandırması.
  static LogoTigerConfig get config => LogoTigerConfig(
        baseUrl: baseUrl,
        apiKey: apiKey,
        clientId: clientId,
        clientSecret: clientSecret,
        username: username,
        password: password,
        firmNr: firmNr,
        periodNr: periodNr,
      );

  /// {@template logo_tiger_defaults_fill_empty}
  /// Boş alanları özel test varsayılanlarıyla doldurur.
  ///
  /// Parametreler:
  /// - [cfg]: Mevcut (prefs) yapılandırma
  ///
  /// Dönüş değeri:
  /// - [LogoTigerConfig]: Boşluklar doldurulmuş kopya
  /// {@endtemplate}
  static LogoTigerConfig fillEmpty(LogoTigerConfig cfg) {
    if (!applyPrivateTestDefaults) return cfg;
    final d = config;
    return cfg.copyWith(
      baseUrl: cfg.baseUrl.trim().isEmpty ? d.baseUrl : cfg.baseUrl,
      apiKey: cfg.apiKey.trim().isEmpty ? d.apiKey : cfg.apiKey,
      clientId: cfg.clientId.trim().isEmpty ? d.clientId : cfg.clientId,
      clientSecret:
          cfg.clientSecret.isEmpty ? d.clientSecret : cfg.clientSecret,
      username: cfg.username.trim().isEmpty ? d.username : cfg.username,
      password: cfg.password.isEmpty ? d.password : cfg.password,
      firmNr: cfg.firmNr <= 0 ? d.firmNr : cfg.firmNr,
      periodNr: cfg.periodNr <= 0 ? d.periodNr : cfg.periodNr,
    );
  }
}
