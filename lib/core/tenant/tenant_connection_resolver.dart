// Dosya Adı: tenant_connection_resolver.dart
// Açıklama: Kiracı kodu / URL → PostgREST base URL çözümleme (RetailEX parity)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'postgrest_tenant_defaults.dart';

/// {@template parsed_tenant_connection}
/// Giriş satırının ayrıştırılmış hali.
/// {@endtemplate}
sealed class ParsedTenantConnection {
  const ParsedTenantConnection();
}

/// Kiracı kodu veya UUID (merkez registry / SaaS slug)
class ParsedTenantRegistryCode extends ParsedTenantConnection {
  /// [code]: Kiracı kodu veya UUID
  final String code;

  /// {@macro parsed_tenant_connection}
  const ParsedTenantRegistryCode(this.code);
}

/// Doğrudan PostgREST tabanı (`https://api…/aqua`)
class ParsedTenantDirectPostgrest extends ParsedTenantConnection {
  /// [url]: Normalize edilmiş base URL
  final String url;

  /// [pathSlug]: Son path segment (kod / UUID) veya null
  final String? pathSlug;

  /// {@macro parsed_tenant_connection}
  const ParsedTenantDirectPostgrest({
    required this.url,
    required this.pathSlug,
  });
}

/// {@template tenant_resolve_result}
/// Çözümlenmiş kiracı PostgREST bağlamı.
/// {@endtemplate}
class TenantResolveResult {
  /// [tenantCode]: Kiracı kodu / slug
  final String tenantCode;

  /// [remoteRestUrl]: PostgREST base URL
  final String remoteRestUrl;

  /// [schema]: Accept-Profile şeması
  final String schema;

  /// [source]: Çözümleme kaynağı (`saas_slug` | `direct_url` | `cached`)
  final String source;

  /// [usedOfflineCache]: Ağ yokken son kayıt kullanıldı mı
  final bool usedOfflineCache;

  /// {@macro tenant_resolve_result}
  const TenantResolveResult({
    required this.tenantCode,
    required this.remoteRestUrl,
    this.schema = PostgrestTenantDefaults.defaultSchema,
    this.source = 'saas_slug',
    this.usedOfflineCache = false,
  });

  /// Boş mu?
  bool get isEmpty =>
      tenantCode.trim().isEmpty || remoteRestUrl.trim().isEmpty;

  /// Kopya.
  TenantResolveResult copyWith({
    String? tenantCode,
    String? remoteRestUrl,
    String? schema,
    String? source,
    bool? usedOfflineCache,
  }) {
    return TenantResolveResult(
      tenantCode: tenantCode ?? this.tenantCode,
      remoteRestUrl: remoteRestUrl ?? this.remoteRestUrl,
      schema: schema ?? this.schema,
      source: source ?? this.source,
      usedOfflineCache: usedOfflineCache ?? this.usedOfflineCache,
    );
  }
}

/// {@template tenant_connection_resolver}
/// RetailEX `merkezTenantRegistry` ile uyumlu saf çözümleme.
///
/// Kullanım örneği:
/// ```dart
/// final r = TenantConnectionResolver.resolveFromInput('lovan');
/// print(r.remoteRestUrl); // https://api.retailex.app/lovan
/// ```
/// {@endtemplate}
class TenantConnectionResolver {
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Trailing slash temizler.
  static String normalizeBaseUrl(String input) {
    return input.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Aktif SaaS kökü proxy / override ise prod `api.retailex.app` URL’lerini
  /// aynı path ile yeni köke taşır (web CORS proxy).
  ///
  /// Örnek: origin=`http://127.0.0.1:8799`,
  /// url=`https://api.retailex.app/lovan` → `http://127.0.0.1:8799/lovan`
  static String rewriteRestUrlForSaasOrigin(
    String restUrl, {
    required String saasOrigin,
  }) {
    final url = normalizeBaseUrl(restUrl);
    final origin = normalizeBaseUrl(saasOrigin);
    if (url.isEmpty || origin.isEmpty) return url;
    final prod = normalizeBaseUrl(PostgrestTenantDefaults.saasOrigin);
    if (origin == prod) return url;
    if (url.startsWith(prod)) {
      return '$origin${url.substring(prod.length)}';
    }
    return url;
  }

  /// SaaS kiracı URL: `https://api.retailex.app/{slug}`
  static String buildSaaSTenantPostgrestUrl(
    String slug, {
    String origin = PostgrestTenantDefaults.saasOrigin,
  }) {
    final o = normalizeBaseUrl(origin);
    final s = slug.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (s.isEmpty) return o;
    return '$o/$s';
  }

  /// Merkez kayıt kökü: `{origin}/merkez`
  static String buildMerkezRestBaseUrl({
    String origin = PostgrestTenantDefaults.saasOrigin,
  }) {
    return buildSaaSTenantPostgrestUrl(
      PostgrestTenantDefaults.merkezPath,
      origin: origin,
    );
  }

  /// Tek satır: kod veya tam PostgREST URL.
  ///
  /// Parametreler:
  /// - [raw]: Kullanıcı girişi
  ///
  /// Dönüş değeri:
  /// - [ParsedTenantConnection]: Ayrıştırılmış bağlantı
  ///
  /// Fırlatılan hatalar:
  /// - [FormatException]: Boş veya geçersiz adres
  static ParsedTenantConnection parseTenantConnectionLine(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      throw const FormatException('Kiracı bağlantısı boş olamaz.');
    }

    if (RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(t)) {
      final sanitized = normalizeBaseUrl(t);
      final uri = Uri.tryParse(sanitized);
      if (uri == null || uri.host.isEmpty) {
        throw const FormatException('Geçerli bir http(s) adresi girin.');
      }
      final pathParts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathParts.isEmpty) {
        throw const FormatException(
          'Adreste kiracı yolu yok. Örnek: https://api.retailex.app/aqua',
        );
      }
      final last = pathParts.last;
      if (last == PostgrestTenantDefaults.merkezPath) {
        throw const FormatException(
          'Bu adres merkez kayıt servisidir. Kiracı kodunu veya '
          'tam kiracı API adresini girin.',
        );
      }
      final pathSlug = (_uuidRe.hasMatch(last) ||
              RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(last))
          ? last
          : null;
      return ParsedTenantDirectPostgrest(
        url: normalizeBaseUrl(uri.toString()),
        pathSlug: pathSlug,
      );
    }

    return ParsedTenantRegistryCode(t);
  }

  /// Kök SaaS + kiracı kodu birleşimi (RetailEX `resolveEffectiveRemoteRestUrl`).
  static String resolveEffectiveRemoteRestUrl(
    String? remoteRestUrl,
    String? merkezTenantCode, {
    String saasOrigin = PostgrestTenantDefaults.saasOrigin,
  }) {
    final remote = normalizeBaseUrl(remoteRestUrl ?? '');
    if (remote.isEmpty) return remote;

    final uri = Uri.tryParse(
      RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(remote)
          ? remote
          : 'https://$remote',
    );
    if (uri == null) return remote;

    final saasHost = Uri.parse(saasOrigin).host;
    if (uri.host == saasHost) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.length == 1 && segs.first != PostgrestTenantDefaults.merkezPath) {
        return remote;
      }
    }

    final tenant = (merkezTenantCode ?? '').trim();
    if (tenant.isEmpty || tenant == PostgrestTenantDefaults.merkezPath) {
      return remote;
    }

    if (uri.host == saasHost) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isEmpty) {
        return buildSaaSTenantPostgrestUrl(tenant, origin: saasOrigin);
      }
    }
    return remote;
  }

  /// Login girişi → PostgREST bağlamı (ağ gerekmez; SaaS slug / direct URL).
  ///
  /// Parametreler:
  /// - [input]: Kiracı kodu veya tam URL
  /// - [saasOrigin]: SaaS kök override
  /// - [schema]: PostgREST şema
  ///
  /// Dönüş değeri:
  /// - [TenantResolveResult]: Çözümlenmiş bağlam
  static TenantResolveResult resolveFromInput(
    String input, {
    String saasOrigin = PostgrestTenantDefaults.saasOrigin,
    String schema = PostgrestTenantDefaults.defaultSchema,
  }) {
    final parsed = parseTenantConnectionLine(input);
    switch (parsed) {
      case ParsedTenantDirectPostgrest(:final url, :final pathSlug):
        final code = (pathSlug ?? '').trim();
        return TenantResolveResult(
          tenantCode: code.isNotEmpty ? code : Uri.parse(url).host,
          remoteRestUrl: url,
          schema: schema,
          source: 'direct_url',
        );
      case ParsedTenantRegistryCode(:final code):
        final effective = resolveEffectiveRemoteRestUrl(
          saasOrigin,
          code,
          saasOrigin: saasOrigin,
        );
        return TenantResolveResult(
          tenantCode: code,
          remoteRestUrl: effective.isNotEmpty
              ? effective
              : buildSaaSTenantPostgrestUrl(code, origin: saasOrigin),
          schema: schema,
          source: 'saas_slug',
        );
    }
  }
}
