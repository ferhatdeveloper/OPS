// Dosya Adı: logo_server_url_bridge.dart
// Açıklama: Sunucu ayarları / Logo REST → Tiger URL çözümleyici
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';

import '../../service/database_service.dart';
import '../services/logo_rest_settings_service.dart';
import 'logo_tiger_config.dart';
import 'logo_tiger_settings_store.dart';
import 'logo_tiger_urls.dart';

/// {@template logo_server_url_bridge}
/// Logo API veriyi **sunucu ayarlarında** (veya Logo REST ekranında)
/// girilen linkten alır. Öncelik:
/// 1) Tiger store (açıkça kaydedilmiş)
/// 2) Logo REST prefs (`logo_rest_base_url`)
/// 3) Ayarlar → API `base_url` (+ api_key)
///
/// Kullanım örneği:
/// ```dart
/// final r = await LogoServerUrlBridge.resolve();
/// print(r.baseUrl);
/// ```
/// {@endtemplate}
class LogoServerUrlBridge {
  LogoServerUrlBridge._();

  /// {@template logo_server_url_bridge_resolve}
  /// Etkin Logo Tiger base URL + opsiyonel api_key.
  /// [tigerOverride]: verilirse store okunmaz (döngü önleme).
  /// {@endtemplate}
  static Future<LogoResolvedEndpoint> resolve({
    LogoTigerConfig? tigerOverride,
  }) async {
    final tiger = tigerOverride ?? await LogoTigerSettingsStore().loadRaw();
    if (tiger.baseUrl.trim().isNotEmpty) {
      return LogoResolvedEndpoint(
        baseUrl: tiger.baseUrl.trim(),
        apiKey: tiger.apiKey,
        source: LogoUrlSource.tigerStore,
      );
    }

    final rest = await LogoRestSettingsService().getSettings();
    if (_usableLogoUrl(rest.baseUrl)) {
      return LogoResolvedEndpoint(
        baseUrl: rest.baseUrl.trim(),
        apiKey: rest.apiKey ?? '',
        source: LogoUrlSource.logoRestSettings,
      );
    }

    try {
      final db = await DatabaseService.getInstance();
      final cfg = await db.getApiConfig();
      final raw = (cfg['base_url'] as String? ?? '').trim();
      final useHttps = cfg['use_https'] == 1;
      final base = _normalizeApiConfigUrl(raw, useHttps: useHttps);
      final key = (cfg['api_key'] as String?)?.trim() ?? '';
      if (_usableLogoUrl(base)) {
        return LogoResolvedEndpoint(
          baseUrl: base,
          apiKey: key,
          source: LogoUrlSource.serverSettings,
        );
      }
    } catch (e) {
      debugPrint('LogoServerUrlBridge.resolve server: $e');
    }

    return const LogoResolvedEndpoint(
      baseUrl: '',
      apiKey: '',
      source: LogoUrlSource.none,
    );
  }

  /// {@template logo_server_url_bridge_merge}
  /// Tiger config’e sunucu/Logo REST URL yedeklerini uygular.
  /// {@endtemplate}
  static Future<LogoTigerConfig> mergeIntoConfig(LogoTigerConfig cfg) async {
    if (cfg.baseUrl.trim().isNotEmpty && cfg.apiKey.trim().isNotEmpty) {
      return cfg;
    }
    final resolved = await resolve(tigerOverride: cfg);
    if (resolved.baseUrl.isEmpty) return cfg;
    return cfg.copyWith(
      baseUrl: cfg.baseUrl.trim().isEmpty ? resolved.baseUrl : cfg.baseUrl,
      apiKey: cfg.apiKey.trim().isEmpty ? resolved.apiKey : cfg.apiKey,
    );
  }

  /// {@template logo_server_url_bridge_sync_from_server}
  /// Ayarlar ekranı kaydında: Logo-benzeri URL → Logo REST + Tiger store.
  /// {@endtemplate}
  static Future<void> syncFromServerSettings({
    required String baseUrl,
    String? apiKey,
    bool useHttps = true,
  }) async {
    final normalized = _normalizeApiConfigUrl(baseUrl, useHttps: useHttps);
    if (!_usableLogoUrl(normalized) && !_looksLikeLogoHost(normalized)) {
      return;
    }

    final restSvc = LogoRestSettingsService();
    final current = await restSvc.getSettings();
    await restSvc.saveSettings(
      current.copyWith(
        baseUrl: normalized,
        apiKey: (apiKey != null && apiKey.trim().isNotEmpty)
            ? apiKey.trim()
            : current.apiKey,
      ),
    );

    final store = LogoTigerSettingsStore();
    final tiger = await store.loadRaw();
    // Sunucu linki her zaman Tiger base’e yazılır (çekim kaynağı)
    await store.save(
      tiger.copyWith(
        baseUrl: normalized,
        apiKey: (apiKey != null && apiKey.trim().isNotEmpty)
            ? apiKey.trim()
            : tiger.apiKey,
      ),
    );
    // Tiger’ı otomatik açma — kullanıcı toggle’ı kullanır; URL hazır olsun
    debugPrint(
      'LogoServerUrlBridge: sunucu URL → Tiger/LogoREST ($normalized)',
    );
  }

  /// Logo REST ayar kaydı → sunucu api_config yansıt (tek kaynak).
  static Future<void> syncServerFromLogoRest({
    required String baseUrl,
    String? apiKey,
  }) async {
    final normalized = LogoTigerUrls.normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) return;
    try {
      final db = await DatabaseService.getInstance();
      final host = LogoTigerUrls.hostPortOnly(normalized);
      await db.updateApiConfig(
        baseUrl: host.replaceFirst(RegExp(r'^https?://'), ''),
        apiKey: apiKey,
        useHttps: normalized.startsWith('https'),
      );
    } catch (e) {
      debugPrint('LogoServerUrlBridge.syncServerFromLogoRest: $e');
    }
  }

  static bool _usableLogoUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return false;
    if (u.contains('default.com')) return false;
    if (u.contains('exfinerp.com') && !u.contains('32001')) return false;
    if (u == '//' || u.startsWith('//api.')) return false;
    // Exfin middleware varsayılanı — Tiger host değil
    if (u.contains('127.0.0.1:8000') || u.contains('10.0.2.2:8000')) {
      return false;
    }
    if (u.contains('localhost:8000')) return false;
    return true;
  }

  static bool _looksLikeLogoHost(String url) {
    final u = url.toLowerCase();
    return u.contains('32001') ||
        u.contains('/api/v1') ||
        u.contains('logotiger') ||
        RegExp(r'\d+\.\d+\.\d+\.\d+').hasMatch(u);
  }

  static String _normalizeApiConfigUrl(String raw, {required bool useHttps}) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('//')) {
      u = '${useHttps ? 'https' : 'http'}:$u';
    } else if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = '${useHttps ? 'https' : 'http'}://$u';
    }
    return u;
  }
}

/// URL çözüm kaynağı.
enum LogoUrlSource {
  tigerStore,
  logoRestSettings,
  serverSettings,
  none,
}

/// {@template logo_resolved_endpoint}
/// Çözülmüş Logo endpoint.
/// {@endtemplate}
class LogoResolvedEndpoint {
  /// [baseUrl]: Host veya /api/v1
  final String baseUrl;

  /// [apiKey]: Query api_key
  final String apiKey;

  /// [source]: Nereden geldi
  final LogoUrlSource source;

  /// {@macro logo_resolved_endpoint}
  const LogoResolvedEndpoint({
    required this.baseUrl,
    required this.apiKey,
    required this.source,
  });
}
