// Dosya Adı: tenant_registry_row.dart
// Açıklama: Merkez `tenant_registry` satırının tipli, secret içermeyen modeli
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

/// {@template tenant_registry_row}
/// Merkez `merkez.tenant_registry` satırı.
///
/// Yalnızca kiracı çözümlemesi ve Logo REST bootstrap'ı için gereken kolonları
/// taşır. `api_key`, parola, OAuth client secret ve access token gibi gizli
/// alanlar bu modelin kapsamı dışındadır.
///
/// Kullanım örneği:
/// ```dart
/// final row = TenantRegistryRow.fromJson(decodedRow);
/// print(row.logoFirmNr); // 401
/// ```
/// {@endtemplate}
class TenantRegistryRow {
  /// [code]: Normalize edilmemiş kiracı kodu (trim edilmiş)
  final String code;

  /// [restBaseUrl]: Kiracıya ait PostgREST taban adresi
  final String? restBaseUrl;

  /// [displayName]: Kiracı görünen adı
  final String? displayName;

  /// [isActive]: Kayıt aktif mi
  final bool isActive;

  /// [logoRestApiUrl]: Logo REST başlangıç adresi
  final String? logoRestApiUrl;

  /// [logoFirmNr]: Logo firma numarası bootstrap değeri
  final int? logoFirmNr;

  /// [logoPeriodNr]: Logo dönem numarası bootstrap değeri
  final int? logoPeriodNr;

  /// [logoDb]: Logo veritabanı adı
  final String? logoDb;

  /// [updatedAt]: Merkez satırının son güncelleme zamanı (UTC)
  final DateTime? updatedAt;

  /// {@macro tenant_registry_row}
  const TenantRegistryRow({
    required this.code,
    required this.isActive,
    this.restBaseUrl,
    this.displayName,
    this.logoRestApiUrl,
    this.logoFirmNr,
    this.logoPeriodNr,
    this.logoDb,
    this.updatedAt,
  });

  /// {@template tenant_registry_row_from_json}
  /// `jsonDecode` sonucu merkez satırını tipli modele çevirir.
  ///
  /// Parametreler:
  /// - [json]: PostgREST satırı (`Map<String, dynamic>`)
  ///
  /// Dönüş değeri:
  /// - [TenantRegistryRow]: Trim ve tip normalizasyonu uygulanmış satır
  ///
  /// Fırlatılan hatalar:
  /// - [FormatException]: `code` boş veya yoksa
  /// {@endtemplate}
  factory TenantRegistryRow.fromJson(Map<String, dynamic> json) {
    final code = _text(json['code']);
    if (code == null) {
      throw const FormatException('tenant_registry code boş');
    }
    return TenantRegistryRow(
      code: code,
      restBaseUrl: _text(json['rest_base_url']),
      displayName: _text(json['display_name']),
      isActive: _bool(json['is_active']),
      logoRestApiUrl: _text(json['logo_rest_api_url']),
      logoFirmNr: _positiveInt(json['logo_firm_nr']),
      logoPeriodNr: _positiveInt(json['logo_period_nr']),
      logoDb: _text(json['logo_db']),
      updatedAt: _date(json['updated_at']),
    );
  }

  /// Logo bootstrap için uygulanabilir bir URL taşıyor mu?
  bool get hasLogoConfig => (logoRestApiUrl ?? '').trim().isNotEmpty;

  @override
  String toString() {
    return 'TenantRegistryRow(code: $code, isActive: $isActive, '
        'logoFirmNr: $logoFirmNr, logoPeriodNr: $logoPeriodNr, '
        'logoDb: $logoDb, updatedAt: $updatedAt)';
  }

  /// [_text]: Boş / null değerleri `null`'a indirger, aksi halde trim eder.
  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// [_bool]: PostgREST `true` / `"true"` biçimlerini boolean'a çevirir.
  static bool _bool(Object? value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }

  /// [_positiveInt]: Yalnızca pozitif tam sayıları kabul eder.
  static int? _positiveInt(Object? value) {
    if (value == null) return null;
    final parsed = value is int ? value : int.tryParse(value.toString().trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  /// [_date]: ISO 8601 metnini UTC `DateTime`'a normalize eder.
  static DateTime? _date(Object? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString().trim());
    return parsed?.toUtc();
  }
}
