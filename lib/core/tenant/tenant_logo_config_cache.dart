// Dosya Adı: tenant_logo_config_cache.dart
// Açıklama: Kiracıya bağlı Logo REST başlangıç yapılandırması cache modeli
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'tenant_registry_row.dart';

/// {@template tenant_logo_config_cache}
/// Merkez registry'den gelen Logo başlangıç değerlerinin offline kopyası.
///
/// Cache tenant'a bağlıdır: farklı bir kiracının kaydı aktif kiracıya
/// uygulanmaz. Model hiçbir secret alan (api key, parola, client secret,
/// access token) taşımaz.
///
/// Kullanım örneği:
/// ```dart
/// final cache = TenantLogoConfigCache.fromRegistry(
///   row,
///   fetchedAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class TenantLogoConfigCache {
  /// [tenantCode]: Normalize edilmiş kiracı kodu
  final String tenantCode;

  /// [logoRestApiUrl]: Registry'den gelen Logo REST adresi
  final String? logoRestApiUrl;

  /// [logoFirmNr]: Bootstrap firma numarası
  final int? logoFirmNr;

  /// [logoPeriodNr]: Bootstrap dönem numarası
  final int? logoPeriodNr;

  /// [logoDb]: Logo veritabanı adı
  final String? logoDb;

  /// [registryUpdatedAt]: Merkez satırının `updated_at` değeri (UTC)
  final DateTime? registryUpdatedAt;

  /// [fetchedAt]: Cihazın son başarılı fetch zamanı (UTC)
  final DateTime fetchedAt;

  /// {@macro tenant_logo_config_cache}
  TenantLogoConfigCache({
    required String tenantCode,
    required DateTime fetchedAt,
    this.logoRestApiUrl,
    this.logoFirmNr,
    this.logoPeriodNr,
    this.logoDb,
    DateTime? registryUpdatedAt,
  })  : tenantCode = tenantCode.trim().toLowerCase(),
        fetchedAt = fetchedAt.toUtc(),
        registryUpdatedAt = registryUpdatedAt?.toUtc();

  /// {@template tenant_logo_config_cache_from_registry}
  /// Merkez satırından cache üretir.
  ///
  /// Parametreler:
  /// - [row]: Aktif merkez registry satırı
  /// - [fetchedAt]: Fetch zamanı
  ///
  /// Dönüş değeri:
  /// - [TenantLogoConfigCache]: Kalıcılaştırılabilir Logo cache kaydı
  /// {@endtemplate}
  factory TenantLogoConfigCache.fromRegistry(
    TenantRegistryRow row, {
    required DateTime fetchedAt,
  }) {
    return TenantLogoConfigCache(
      tenantCode: row.code,
      logoRestApiUrl: row.logoRestApiUrl,
      logoFirmNr: row.logoFirmNr,
      logoPeriodNr: row.logoPeriodNr,
      logoDb: row.logoDb,
      registryUpdatedAt: row.updatedAt,
      fetchedAt: fetchedAt,
    );
  }

  /// {@template tenant_logo_config_cache_from_json}
  /// Prefs JSON kaydını modele çevirir.
  ///
  /// Fırlatılan hatalar:
  /// - [FormatException]: `fetched_at` eksik veya geçersizse
  /// {@endtemplate}
  factory TenantLogoConfigCache.fromJson(Map<String, dynamic> json) {
    final fetchedAt = _date(json['fetched_at']);
    if (fetchedAt == null) {
      throw const FormatException('tenant Logo cache fetched_at geçersiz');
    }
    return TenantLogoConfigCache(
      tenantCode: '${json['tenant_code'] ?? ''}',
      logoRestApiUrl: _text(json['logo_rest_api_url']),
      logoFirmNr: _positiveInt(json['logo_firm_nr']),
      logoPeriodNr: _positiveInt(json['logo_period_nr']),
      logoDb: _text(json['logo_db']),
      registryUpdatedAt: _date(json['updated_at']),
      fetchedAt: fetchedAt,
    );
  }

  /// Uygulanabilir bir Logo URL'i var mı?
  bool get hasLogoConfig => (logoRestApiUrl ?? '').trim().isNotEmpty;

  /// {@template tenant_logo_config_cache_is_fresh}
  /// Cache verilen TTL içinde mi?
  ///
  /// Parametreler:
  /// - [now]: Referans zaman
  /// - [ttl]: Yenileme süresi
  ///
  /// Dönüş değeri:
  /// - [bool]: Taze ise `true`; ileri tarihli saat kayması tazelik saymaz
  /// {@endtemplate}
  bool isFresh({required DateTime now, required Duration ttl}) {
    final elapsed = now.toUtc().difference(fetchedAt);
    if (elapsed.isNegative) return false;
    return elapsed < ttl;
  }

  /// Prefs JSON gösterimi (secret alan içermez).
  Map<String, dynamic> toJson() => {
        'tenant_code': tenantCode,
        'logo_rest_api_url': logoRestApiUrl,
        'logo_firm_nr': logoFirmNr,
        'logo_period_nr': logoPeriodNr,
        'logo_db': logoDb,
        'updated_at': registryUpdatedAt?.toIso8601String(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  @override
  String toString() {
    return 'TenantLogoConfigCache(tenantCode: $tenantCode, '
        'logoFirmNr: $logoFirmNr, logoPeriodNr: $logoPeriodNr, '
        'logoDb: $logoDb, registryUpdatedAt: $registryUpdatedAt, '
        'fetchedAt: $fetchedAt)';
  }

  /// [_text]: Boş / null değerleri `null`'a indirger.
  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// [_positiveInt]: Yalnızca pozitif tam sayıları kabul eder.
  static int? _positiveInt(Object? value) {
    if (value == null) return null;
    final parsed = value is int ? value : int.tryParse(value.toString().trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  /// [_date]: ISO 8601 metnini UTC `DateTime`'a çevirir.
  static DateTime? _date(Object? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString().trim());
    return parsed?.toUtc();
  }
}
