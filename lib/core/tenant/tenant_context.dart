// Dosya Adı: tenant_context.dart
// Açıklama: Aktif kiracı PostgREST oturum modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'postgrest_tenant_defaults.dart';
import 'tenant_connection_resolver.dart';

/// {@template tenant_context}
/// Kaydedilmiş / aktif kiracı PostgREST bağlamı.
///
/// Kullanım örneği:
/// ```dart
/// final ctx = TenantContext(
///   tenantCode: 'lovan',
///   remoteRestUrl: 'https://api.retailex.app/lovan',
/// );
/// print(ctx.isEmpty); // false
/// ```
/// {@endtemplate}
class TenantContext {
  /// [tenantCode]: Kiracı kodu
  final String tenantCode;

  /// [remoteRestUrl]: PostgREST base URL
  final String remoteRestUrl;

  /// [schema]: Accept-Profile
  final String schema;

  /// [apiKey]: İsteğe bağlı anon / service key
  final String? apiKey;

  /// [jwt]: İsteğe bağlı Bearer JWT
  final String? jwt;

  /// [merkezRestUrl]: tenant_registry kökü (opsiyonel)
  final String? merkezRestUrl;

  /// [displayName]: Görünen ad
  final String? displayName;

  /// [resolvedAtIso]: Son çözümleme zamanı (ISO-8601)
  final String? resolvedAtIso;

  /// {@macro tenant_context}
  const TenantContext({
    required this.tenantCode,
    required this.remoteRestUrl,
    this.schema = PostgrestTenantDefaults.defaultSchema,
    this.apiKey,
    this.jwt,
    this.merkezRestUrl,
    this.displayName,
    this.resolvedAtIso,
  });

  /// Boş bağlam
  static const TenantContext empty = TenantContext(
    tenantCode: '',
    remoteRestUrl: '',
  );

  /// Boş mu?
  bool get isEmpty =>
      tenantCode.trim().isEmpty || remoteRestUrl.trim().isEmpty;

  /// Dolu mu?
  bool get isNotEmpty => !isEmpty;

  /// Dashboard dens chip metni (`displayName` yoksa `tenantCode`).
  String get chipLabel {
    final name = (displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return tenantCode.trim();
  }

  /// Resolve sonucundan üretir.
  factory TenantContext.fromResolve(
    TenantResolveResult result, {
    String? apiKey,
    String? jwt,
    String? merkezRestUrl,
    String? displayName,
  }) {
    return TenantContext(
      tenantCode: result.tenantCode,
      remoteRestUrl: result.remoteRestUrl,
      schema: result.schema,
      apiKey: apiKey,
      jwt: jwt,
      merkezRestUrl: merkezRestUrl,
      displayName: displayName ?? result.tenantCode,
      resolvedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Prefs / JSON haritası.
  Map<String, String> toPrefsMap() {
    return {
      'tenantCode': tenantCode,
      'remoteRestUrl': remoteRestUrl,
      'schema': schema,
      if (apiKey != null && apiKey!.isNotEmpty) 'apiKey': apiKey!,
      if (jwt != null && jwt!.isNotEmpty) 'jwt': jwt!,
      if (merkezRestUrl != null && merkezRestUrl!.isNotEmpty)
        'merkezRestUrl': merkezRestUrl!,
      if (displayName != null && displayName!.isNotEmpty)
        'displayName': displayName!,
      if (resolvedAtIso != null) 'resolvedAtIso': resolvedAtIso!,
    };
  }

  /// Prefs haritasından.
  factory TenantContext.fromPrefsMap(Map<String, String?> map) {
    return TenantContext(
      tenantCode: (map['tenantCode'] ?? '').trim(),
      remoteRestUrl: (map['remoteRestUrl'] ?? '').trim(),
      schema: (map['schema'] ?? PostgrestTenantDefaults.defaultSchema).trim(),
      apiKey: map['apiKey'],
      jwt: map['jwt'],
      merkezRestUrl: map['merkezRestUrl'],
      displayName: map['displayName'],
      resolvedAtIso: map['resolvedAtIso'],
    );
  }

  /// Kopya.
  TenantContext copyWith({
    String? tenantCode,
    String? remoteRestUrl,
    String? schema,
    String? apiKey,
    String? jwt,
    String? merkezRestUrl,
    String? displayName,
    String? resolvedAtIso,
  }) {
    return TenantContext(
      tenantCode: tenantCode ?? this.tenantCode,
      remoteRestUrl: remoteRestUrl ?? this.remoteRestUrl,
      schema: schema ?? this.schema,
      apiKey: apiKey ?? this.apiKey,
      jwt: jwt ?? this.jwt,
      merkezRestUrl: merkezRestUrl ?? this.merkezRestUrl,
      displayName: displayName ?? this.displayName,
      resolvedAtIso: resolvedAtIso ?? this.resolvedAtIso,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TenantContext &&
        other.tenantCode == tenantCode &&
        other.remoteRestUrl == remoteRestUrl &&
        other.schema == schema &&
        other.apiKey == apiKey &&
        other.jwt == jwt;
  }

  @override
  int get hashCode => Object.hash(tenantCode, remoteRestUrl, schema, apiKey, jwt);
}
