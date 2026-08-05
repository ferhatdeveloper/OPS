// Dosya Adı: logo_tiger_urls.dart
// Açıklama: Logo Tiger Objects REST URL normalize ve query build
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template logo_tiger_parsed_input}
/// Kullanıcı girişinden ayrıştırılmış Logo endpoint.
/// {@endtemplate}
class LogoTigerParsedInput {
  /// Normalize `/api/v1` taban (şema + host:port + path)
  final String baseUrl;

  /// URL query’den çıkarılan api_key (yoksa boş)
  final String apiKey;

  /// Host (port yok)
  final String host;

  /// Port (varsayılan [LogoTigerUrls.defaultPort])
  final int port;

  /// {@macro logo_tiger_parsed_input}
  const LogoTigerParsedInput({
    required this.baseUrl,
    this.apiKey = '',
    this.host = '',
    this.port = LogoTigerUrls.defaultPort,
  });
}

/// {@template logo_tiger_urls}
/// RetailEX `normalizeLogoRestBaseUrl` karşılığı — düz adres yeterli.
///
/// Kullanım örneği:
/// ```dart
/// final base = LogoTigerUrls.normalizeBaseUrl(
///   '${LogoTigerUrls.defaultHost}:${LogoTigerUrls.defaultPort}',
/// );
/// // http://185.86.15.238:32001/api/v1
/// ```
/// {@endtemplate}
class LogoTigerUrls {
  LogoTigerUrls._();

  /// Logo Objects REST varsayılan host (IP). Secret / api_key içermez.
  static const String defaultHost = '185.86.15.238';

  /// Logo Objects REST varsayılan port.
  static const int defaultPort = 32001;

  /// Sayfa boyutu üst sınırı (Logo sunucu doğrulaması).
  static const int maxPageSize = 25;

  /// {@template logo_tiger_urls_compose}
  /// Host + port → `http://host:port/api/v1`.
  /// Port boş/null → [defaultPort]. Host’ta `:port` varsa (ve port verilmediyse) o kullanılır.
  /// {@endtemplate}
  static String composeBaseUrl(String host, {int? port}) {
    var h = _stripToHostPort(host);
    if (h.isEmpty) return '';
    var p = port ?? defaultPort;
    final lastColon = h.lastIndexOf(':');
    if (lastColon > 0 && !h.contains(']')) {
      final maybePort = int.tryParse(h.substring(lastColon + 1).trim());
      if (maybePort != null && maybePort > 0) {
        if (port == null) p = maybePort;
        h = h.substring(0, lastColon).trim();
      }
    }
    if (h.isEmpty) return '';
    return normalizeBaseUrl('$h:$p');
  }

  /// {@template logo_tiger_urls_split}
  /// URL / host:port → host + port (port yoksa [fallbackPort], varsayılan 32001).
  /// Normalize sırasında port uydurmaz — ham metinden okur.
  /// {@endtemplate}
  static ({String host, int port}) splitHostPort(
    String raw, {
    int fallbackPort = defaultPort,
  }) {
    final plain = _stripToHostPort(raw);
    if (plain.isEmpty) {
      return (host: '', port: fallbackPort);
    }
    final lastColon = plain.lastIndexOf(':');
    if (lastColon > 0 && !plain.contains(']')) {
      final hostPart = plain.substring(0, lastColon).trim();
      final portPart = plain.substring(lastColon + 1).trim();
      final parsed = int.tryParse(portPart);
      if (hostPart.isNotEmpty && parsed != null && parsed > 0) {
        return (host: hostPart, port: parsed);
      }
    }
    return (host: plain, port: fallbackPort);
  }

  /// Şema / path / query kırp → `host` veya `host:port`.
  static String _stripToHostPort(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    final q = u.indexOf('?');
    if (q >= 0) u = u.substring(0, q);
    final hash = u.indexOf('#');
    if (hash >= 0) u = u.substring(0, hash);
    u = u.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    if (u.startsWith('//')) u = u.substring(2);
    u = u.replaceFirst(
      RegExp(r'/services/help.*$', caseSensitive: false),
      '',
    );
    // path kırp (/api/v1 …)
    final slash = u.indexOf('/');
    if (slash >= 0) u = u.substring(0, slash);
    return u.trim();
  }

  /// {@template logo_tiger_urls_parse_user_input}
  /// Düz host, host:port, http URL veya help link → taban + api_key + host/port.
  /// {@endtemplate}
  static LogoTigerParsedInput parseUserInput(String raw, {int? portHint}) {
    var u = raw.trim();
    if (u.isEmpty) {
      return LogoTigerParsedInput(
        baseUrl: '',
        port: portHint ?? defaultPort,
      );
    }

    var extractedKey = '';
    final qIndex = u.indexOf('?');
    if (qIndex >= 0) {
      final query = u.substring(qIndex + 1);
      u = u.substring(0, qIndex);
      try {
        final params = Uri.splitQueryString(query);
        extractedKey = (params['api_key'] ?? params['apikey'] ?? '').trim();
      } catch (_) {}
    }
    final hash = u.indexOf('#');
    if (hash >= 0) u = u.substring(0, hash);

    final split = splitHostPort(u, fallbackPort: portHint ?? defaultPort);
    final base = composeBaseUrl(split.host, port: split.port);
    return LogoTigerParsedInput(
      baseUrl: base,
      apiKey: extractedKey,
      host: split.host,
      port: split.port,
    );
  }

  /// {@template logo_tiger_urls_normalize}
  /// Base URL’i `/api/v1` ile biten forma getirir.
  /// Port yoksa [defaultPort] (32001) eklenir.
  /// {@endtemplate}
  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return '';

    final q = u.indexOf('?');
    if (q >= 0) u = u.substring(0, q);
    final h = u.indexOf('#');
    if (h >= 0) u = u.substring(0, h);
    u = u.replaceAll(RegExp(r'/+$'), '');

    if (u.startsWith('//')) {
      u = 'http:$u';
    }

    u = u.replaceFirst(
      RegExp(r'/services/help.*$', caseSensitive: false),
      '',
    );
    u = u.replaceAll(RegExp(r'/+$'), '');

    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }

    // Host’ta port yoksa varsayılan 32001
    final uri = Uri.tryParse(u);
    if (uri != null && uri.host.isNotEmpty && !uri.hasPort) {
      u = '${uri.scheme}://${uri.host}:$defaultPort'
          '${uri.path.isEmpty || uri.path == '/' ? '' : uri.path}';
    }

    if (RegExp(r'/api/v1/?$', caseSensitive: false).hasMatch(u)) {
      return u.replaceAll(RegExp(r'/+$'), '');
    }
    final apiIdx = u.toLowerCase().indexOf('/api/v1');
    if (apiIdx >= 0) {
      return u.substring(0, apiIdx + '/api/v1'.length);
    }
    if (u.toLowerCase().endsWith('/api')) {
      return '$u/v1';
    }
    return '$u/api/v1';
  }

  /// {@template logo_tiger_urls_host_port}
  /// Yalnızca host:port (UI — şemasız düz adres).
  /// {@endtemplate}
  static String hostPortOnly(String url) {
    final split = splitHostPort(url);
    if (split.host.isEmpty) return '';
    return '${split.host}:${split.port}';
  }

  /// UI alanı için düz adres (host:port).
  static String displayPlain(String url) => hostPortOnly(url);

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
