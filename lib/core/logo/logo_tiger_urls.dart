// Dosya Adı: logo_tiger_urls.dart
// Açıklama: Logo Tiger Objects REST URL normalize ve query build
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template logo_tiger_urls}
/// RetailEX `normalizeLogoRestBaseUrl` karşılığı — host/port → `/api/v1`.
///
/// Kullanım örneği:
/// ```dart
/// final base = LogoTigerUrls.normalizeBaseUrl('http://host:32001');
/// // http://host:32001/api/v1
/// ```
/// {@endtemplate}
class LogoTigerUrls {
  LogoTigerUrls._();

  /// Sayfa boyutu üst sınırı (Logo sunucu doğrulaması).
  static const int maxPageSize = 25;

  /// {@template logo_tiger_urls_normalize}
  /// Base URL’i `/api/v1` ile biten forma getirir.
  ///
  /// Parametreler:
  /// - [url]: Ham URL (help path içerebilir)
  ///
  /// Dönüş değeri:
  /// - [String]: Normalize edilmiş taban; boş giriş → boş
  /// {@endtemplate}
  static String normalizeBaseUrl(String url) {
    var u = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (u.isEmpty) return '';
    u = u.replaceFirst(RegExp(r'/services/help.*$', caseSensitive: false), '');
    u = u.replaceAll(RegExp(r'/+$'), '');
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    if (!u.endsWith('/api/v1')) {
      if (u.endsWith('/api')) {
        u = '$u/v1';
      } else if (!u.contains('/api/v1')) {
        u = '$u/api/v1';
      }
    }
    return u;
  }

  /// {@template logo_tiger_urls_host_port}
  /// Yalnızca host:port (şema yoksa http ekler, path kırpılır).
  /// {@endtemplate}
  static String hostPortOnly(String url) {
    final normalized = normalizeBaseUrl(url);
    if (normalized.isEmpty) return '';
    final uri = Uri.parse(normalized);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// {@template logo_tiger_urls_help}
  /// Help discovery URL’si.
  /// {@endtemplate}
  static Uri helpUri(String baseUrl, {required String apiKey}) {
    final base = normalizeBaseUrl(baseUrl);
    return Uri.parse('$base/services/help').replace(
      queryParameters: {
        'expandLevel': 'full',
        if (apiKey.isNotEmpty) 'api_key': apiKey,
      },
    );
  }

  /// {@template logo_tiger_urls_resource}
  /// Kaynak listesi yolu (RetailEX: `/{resource}`).
  /// {@endtemplate}
  static String resourcePath(String resource) {
    final r = resource.trim().replaceAll(RegExp(r'^/+'), '');
    return '/$r';
  }

  /// {@template logo_tiger_urls_services_resource}
  /// Alternatif swagger yolu: `/services/{resource}`.
  /// {@endtemplate}
  static String servicesResourcePath(String resource) {
    final r = resource.trim().replaceAll(RegExp(r'^/+'), '');
    if (r.startsWith('services/')) return '/$r';
    return '/services/$r';
  }

  /// {@template logo_tiger_urls_with_query}
  /// Query map → encode edilmiş string (boş değerler atılır).
  /// {@endtemplate}
  static String encodeQuery(Map<String, String> query) {
    final entries = query.entries
        .where((e) => e.value.isNotEmpty)
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}='
              '${Uri.encodeQueryComponent(e.value)}',
        );
    return entries.join('&');
  }

  /// {@template logo_tiger_urls_auth_headers}
  /// Bearer + opsiyonel Accept header map.
  /// {@endtemplate}
  static Map<String, String> authHeaders(String? accessToken) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// Liste limit clamp (1..[maxPageSize]).
  static int clampLimit(int? limit) {
    if (limit == null) return maxPageSize;
    if (limit < 1) return 1;
    if (limit > maxPageSize) return maxPageSize;
    return limit;
  }
}
