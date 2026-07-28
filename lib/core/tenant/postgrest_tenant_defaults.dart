// Dosya Adı: postgrest_tenant_defaults.dart
// Açıklama: RetailEX SaaS PostgREST kiracı kök URL varsayılanları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template postgrest_tenant_defaults}
/// RetailEX ile uyumlu varsayılan PostgREST kökleri.
///
/// Kullanım örneği:
/// ```dart
/// print(PostgrestTenantDefaults.saasOrigin);
/// // https://api.retailex.app
/// ```
///
/// Web (localhost) CORS: API yalnızca `https://retailex.app` Origin’ine
/// izin verir. Geliştirmede `dart run tool/postgrest_cors_proxy.dart`
/// çalıştırıp SaaS kökünü `http://127.0.0.1:8799` yapın
/// (`--dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799`); kalıcı çözüm
/// Caddy’de localhost Origin eklemektir.
/// {@endtemplate}
class PostgrestTenantDefaults {
  /// SaaS kiracı PostgREST kökü (Caddy: `/{kiracı_kodu}`)
  static const String saasOrigin = 'https://api.retailex.app';

  /// Web CORS geliştirme proxy’si (`tool/postgrest_cors_proxy.dart`)
  static const String webCorsProxyOrigin = 'http://127.0.0.1:8799';

  /// Compile-time override: `--dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799`
  static const String webSaasOriginDefine = String.fromEnvironment(
    'WEB_SAAS_ORIGIN',
    defaultValue: '',
  );

  /// Merkez kayıt PostgREST yolu (tenant_registry)
  static const String merkezPath = 'merkez';

  /// Varsayılan şema (Accept-Profile / Content-Profile)
  static const String defaultSchema = 'public';

  /// Yerel geliştirme PostgREST (pg_bridge 3001; PostgREST 3002)
  static const String localPostgrestOrigin = 'http://127.0.0.1:3002';

  /// Prefs boşken etkili SaaS kökü (dart-define > varsayılan).
  static String get effectiveSaasOrigin {
    final defined = webSaasOriginDefine.trim().replaceAll(RegExp(r'/+$'), '');
    if (defined.isNotEmpty) return defined;
    return saasOrigin;
  }
}
