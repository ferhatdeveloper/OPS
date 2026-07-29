// Dosya Adı: logo_tiger_settings_store.dart
// Açıklama: Logo Tiger REST ayarları — obfuscated SharedPreferences store
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/remember_me_crypto.dart';
import 'logo_server_url_bridge.dart';
import 'logo_tiger_config.dart';
import 'logo_tiger_urls.dart';

/// {@template logo_tiger_settings_store}
/// Tiger REST bağlantı ayarları. Secret alanlar [RememberMeCrypto] ile
/// obfuscate edilir (AiSettingsStore ile aynı model). Gerçek key asla loglanmaz.
///
/// Kullanım örneği:
/// ```dart
/// final store = LogoTigerSettingsStore();
/// await store.save(cfg);
/// final loaded = await store.load();
/// ```
/// {@endtemplate}
class LogoTigerSettingsStore {
  /// [_prefsFactory]: Test inject
  final Future<SharedPreferences> Function()? _prefsFactory;

  static const String _keyMaterial = 'exfinops.logo.tiger.secrets.v1';

  static const String keyBaseUrl = 'logo_tiger_base_url';
  static const String keyApiKey = 'logo_tiger_api_key_enc';
  static const String keyUsername = 'logo_tiger_username';
  static const String keyPassword = 'logo_tiger_password_enc';
  static const String keyClientId = 'logo_tiger_client_id_enc';
  static const String keyClientSecret = 'logo_tiger_client_secret_enc';
  static const String keyFirmNr = 'logo_tiger_firm_nr';
  static const String keyPeriodNr = 'logo_tiger_period_nr';
  static const String keyLogoDb = 'logo_tiger_logo_db';
  static const String keyAccessToken = 'logo_tiger_access_token_enc';
  static const String keyTokenExpiresAt = 'logo_tiger_token_expires_at';
  static const String keyEnabled = 'logo_tiger_enabled';

  /// [keyManualOverride]: Ayarın kullanıcı tarafından elle girildiği işareti
  static const String keyManualOverride = 'logo_tiger_manual_override';

  /// [keyRegistryTenantCode]: Son registry seed'inin kiracı kodu
  static const String keyRegistryTenantCode = 'logo_tiger_registry_tenant_code';

  /// [keyRegistryUpdatedAt]: Son registry seed'inin `updated_at` değeri
  static const String keyRegistryUpdatedAt = 'logo_tiger_registry_updated_at';

  /// Dev örnek host:port — api_key koda yazılmaz.
  static const String devExampleHostPort = 'http://127.0.0.1:32001';

  /// {@macro logo_tiger_settings_store}
  LogoTigerSettingsStore({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory;

  Future<SharedPreferences> _prefs() async {
    final factory = _prefsFactory;
    if (factory != null) return factory();
    return SharedPreferences.getInstance();
  }

  String _enc(String plain) =>
      RememberMeCrypto.encrypt(plain, keyMaterial: _keyMaterial);

  String _dec(String cipher) =>
      RememberMeCrypto.decrypt(cipher, keyMaterial: _keyMaterial);

  /// Tiger REST modu açık mı?
  Future<bool> isEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(keyEnabled) ?? false;
  }

  /// Tiger push hazır mı? (toggle + geçerli config)
  Future<bool> isPushReady() async {
    if (!await isEnabled()) return false;
    final cfg = await load();
    return cfg.canPush;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(keyEnabled, value);
  }

  /// {@template logo_tiger_settings_store_load_raw}
  /// Yalnızca Tiger prefs (sunucu fallback yok).
  /// {@endtemplate}
  Future<LogoTigerConfig> loadRaw() async {
    final prefs = await _prefs();
    final base = prefs.getString(keyBaseUrl)?.trim() ?? '';
    return LogoTigerConfig(
      baseUrl: base.isNotEmpty ? base : '',
      apiKey: _dec(prefs.getString(keyApiKey) ?? ''),
      username: prefs.getString(keyUsername) ?? '',
      password: _dec(prefs.getString(keyPassword) ?? ''),
      clientId: _dec(prefs.getString(keyClientId) ?? ''),
      clientSecret: _dec(prefs.getString(keyClientSecret) ?? ''),
      firmNr: prefs.getInt(keyFirmNr) ?? 1,
      periodNr: prefs.getInt(keyPeriodNr) ?? 1,
      logoDb: prefs.getString(keyLogoDb),
    );
  }

  /// {@template logo_tiger_settings_store_load}
  /// Tam yapılandırma; baseUrl boşsa sunucu / Logo REST ayarından doldurulur.
  /// {@endtemplate}
  Future<LogoTigerConfig> load() async {
    final raw = await loadRaw();
    return LogoServerUrlBridge.mergeIntoConfig(raw);
  }

  /// {@template logo_tiger_settings_store_save}
  /// Yapılandırmayı kaydeder (secret obfuscate).
  ///
  /// Parametreler:
  /// - [config]: Kaydedilecek Tiger yapılandırması
  /// - [markManualOverride]: Kayıt kullanıcı kaynaklı mı. Varsayılan `true`;
  ///   tenant registry seed'i bu değeri `false` gönderir.
  /// {@endtemplate}
  Future<void> save(
    LogoTigerConfig config, {
    bool markManualOverride = true,
  }) async {
    final prefs = await _prefs();
    final parsed = LogoTigerUrls.parseUserInput(config.baseUrl);
    final key =
        config.apiKey.trim().isNotEmpty ? config.apiKey.trim() : parsed.apiKey;
    await prefs.setString(keyBaseUrl, parsed.baseUrl);
    await prefs.setString(keyApiKey, _enc(key));
    await prefs.setString(keyUsername, config.username.trim());
    await prefs.setString(keyPassword, _enc(config.password));
    await prefs.setString(keyClientId, _enc(config.clientId.trim()));
    await prefs.setString(keyClientSecret, _enc(config.clientSecret));
    await prefs.setInt(keyFirmNr, config.firmNr);
    await prefs.setInt(keyPeriodNr, config.periodNr);
    if (config.logoDb != null && config.logoDb!.trim().isNotEmpty) {
      await prefs.setString(keyLogoDb, config.logoDb!.trim());
    } else {
      await prefs.remove(keyLogoDb);
    }
    await prefs.setBool(keyManualOverride, markManualOverride);
  }

  /// {@template logo_tiger_settings_store_has_manual_override}
  /// Kullanıcı Logo ayarını elle kaydetmiş mi?
  ///
  /// Dönüş değeri:
  /// - [bool]: Elle kayıt varsa `true`; registry seed bu değeri set etmez
  /// {@endtemplate}
  Future<bool> hasManualOverride() async {
    final prefs = await _prefs();
    return prefs.getBool(keyManualOverride) ?? false;
  }

  /// {@template logo_tiger_settings_store_mark_registry_seed}
  /// Registry kaynaklı seed'i işaretler (manuel override'ı temizler).
  ///
  /// Parametreler:
  /// - [tenantCode]: Seed'in ait olduğu kiracı kodu
  /// - [updatedAt]: Merkez satırının `updated_at` değeri (yoksa temizlenir)
  /// {@endtemplate}
  Future<void> markRegistrySeed({
    required String tenantCode,
    DateTime? updatedAt,
  }) async {
    final prefs = await _prefs();
    await prefs.setBool(keyManualOverride, false);
    await prefs.setString(
      keyRegistryTenantCode,
      tenantCode.trim().toLowerCase(),
    );
    if (updatedAt == null) {
      await prefs.remove(keyRegistryUpdatedAt);
    } else {
      await prefs.setString(
        keyRegistryUpdatedAt,
        updatedAt.toUtc().toIso8601String(),
      );
    }
  }

  /// {@template logo_tiger_settings_store_last_registry_seed}
  /// Son registry seed'inin kiracı kodu ve `updated_at` değeri.
  ///
  /// Dönüş değeri:
  /// - Kayıt yoksa her iki alan da `null`
  /// {@endtemplate}
  Future<({String? tenantCode, DateTime? updatedAt})> lastRegistrySeed() async {
    final prefs = await _prefs();
    final code = prefs.getString(keyRegistryTenantCode)?.trim();
    final rawUpdated = prefs.getString(keyRegistryUpdatedAt)?.trim();
    return (
      tenantCode: (code == null || code.isEmpty) ? null : code,
      updatedAt: (rawUpdated == null || rawUpdated.isEmpty)
          ? null
          : DateTime.tryParse(rawUpdated)?.toUtc(),
    );
  }

  Future<void> saveAccessToken(String? token, {DateTime? expiresAt}) async {
    final prefs = await _prefs();
    if (token == null || token.isEmpty) {
      await prefs.remove(keyAccessToken);
      await prefs.remove(keyTokenExpiresAt);
      return;
    }
    await prefs.setString(keyAccessToken, _enc(token));
    if (expiresAt != null) {
      await prefs.setInt(
        keyTokenExpiresAt,
        expiresAt.millisecondsSinceEpoch,
      );
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs();
    final cipher = prefs.getString(keyAccessToken) ?? '';
    final token = _dec(cipher);
    if (token.isEmpty) return null;
    final expMs = prefs.getInt(keyTokenExpiresAt);
    if (expMs != null && DateTime.now().millisecondsSinceEpoch >= expMs) {
      await clearAccessToken();
      return null;
    }
    return token;
  }

  Future<void> clearAccessToken() async {
    final prefs = await _prefs();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyTokenExpiresAt);
  }

  /// Snapshot — secret değeri yok.
  Future<Map<String, dynamic>> loadSafeSnapshot() async {
    final cfg = await load();
    final enabled = await isEnabled();
    return {
      ...cfg.toSafeMap(),
      'enabled': enabled,
    };
  }
}
