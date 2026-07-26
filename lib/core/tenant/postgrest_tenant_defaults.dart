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
/// {@endtemplate}
class PostgrestTenantDefaults {
  /// SaaS kiracı PostgREST kökü (Caddy: `/{kiracı_kodu}`)
  static const String saasOrigin = 'https://api.retailex.app';

  /// Merkez kayıt PostgREST yolu (tenant_registry)
  static const String merkezPath = 'merkez';

  /// Varsayılan şema (Accept-Profile / Content-Profile)
  static const String defaultSchema = 'public';

  /// Yerel geliştirme PostgREST (pg_bridge 3001; PostgREST 3002)
  static const String localPostgrestOrigin = 'http://127.0.0.1:3002';
}
