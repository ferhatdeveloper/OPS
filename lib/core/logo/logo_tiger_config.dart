// Dosya Adı: logo_tiger_config.dart
// Açıklama: Logo Tiger REST bağlantı yapılandırması modeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'logo_tiger_urls.dart';

/// {@template logo_tiger_config}
/// RetailEX `LogoRestConfig` karşılığı — OPS Tiger REST ayarları.
///
/// Kullanım örneği:
/// ```dart
/// final cfg = LogoTigerConfig(
///   baseUrl: 'http://host:32001',
///   apiKey: '…',
/// );
/// ```
/// {@endtemplate}
class LogoTigerConfig {
  /// [baseUrl]: Host:port veya tam `/api/v1` URL
  final String baseUrl;

  /// [apiKey]: Help / bazı isteklerde query `api_key` (client_id ile aynı olabilir)
  final String apiKey;

  /// [username]: Logo ERP kullanıcısı
  final String username;

  /// [password]: Logo ERP şifresi
  final String password;

  /// [clientId]: OAuth uygulama client_id
  final String clientId;

  /// [clientSecret]: OAuth client_secret
  final String clientSecret;

  /// [firmNr]: Firma no
  final int firmNr;

  /// [periodNr]: Dönem no
  final int periodNr;

  /// [logoDb]: Opsiyonel Logo DB adı
  final String? logoDb;

  /// [connectTimeout]: Bağlantı zaman aşımı
  final Duration connectTimeout;

  /// [receiveTimeout]: Okuma zaman aşımı
  final Duration receiveTimeout;

  /// {@macro logo_tiger_config}
  const LogoTigerConfig({
    required this.baseUrl,
    this.apiKey = '',
    this.username = '',
    this.password = '',
    this.clientId = '',
    this.clientSecret = '',
    this.firmNr = 1,
    this.periodNr = 1,
    this.logoDb,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 120),
  });

  /// Normalize edilmiş `/api/v1` taban.
  String get normalizedBaseUrl => LogoTigerUrls.normalizeBaseUrl(baseUrl);

  /// OAuth için yeterli kimlik var mı?
  bool get hasAuthCredentials => missingAuthFields.isEmpty;

  /// {@template logo_tiger_config_missing_auth_fields}
  /// OAuth token isteği için eksik zorunlu alan adları.
  /// {@endtemplate}
  List<String> get missingAuthFields => [
        if (username.trim().isEmpty) 'username',
        if (password.isEmpty) 'password',
        if (clientId.trim().isEmpty) 'client_id',
      ];

  /// Help ping için base + api_key yeterli mi?
  bool get canPingHelp =>
      normalizedBaseUrl.isNotEmpty && apiKey.trim().isNotEmpty;

  /// JobQueue push için base URL + OAuth yeterli mi?
  bool get canPush =>
      normalizedBaseUrl.isNotEmpty && hasAuthCredentials;

  LogoTigerConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? username,
    String? password,
    String? clientId,
    String? clientSecret,
    int? firmNr,
    int? periodNr,
    String? logoDb,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    return LogoTigerConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
      password: password ?? this.password,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      firmNr: firmNr ?? this.firmNr,
      periodNr: periodNr ?? this.periodNr,
      logoDb: logoDb ?? this.logoDb,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    );
  }

  /// Log / snapshot — secret yok.
  Map<String, dynamic> toSafeMap() => {
        'baseUrl': normalizedBaseUrl,
        'hasApiKey': apiKey.trim().isNotEmpty,
        'username': username,
        'hasPassword': password.isNotEmpty,
        'hasClientId': clientId.trim().isNotEmpty,
        'hasClientSecret': clientSecret.isNotEmpty,
        'firmNr': firmNr,
        'periodNr': periodNr,
        'logoDb': logoDb,
      };
}
