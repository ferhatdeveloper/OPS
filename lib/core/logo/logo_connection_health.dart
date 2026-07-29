// Dosya Adı: logo_connection_health.dart
// Açıklama: Logo REST bağlantı sağlık denetimi (yeşil / kırmızı gösterge kaynağı)
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/foundation.dart';

import '../services/logo_api_service.dart';
import 'logo_tiger_rest_client.dart';
import 'logo_tiger_settings_store.dart';

/// {@template logo_connection_status}
/// Logo REST bağlantı durumu.
/// {@endtemplate}
enum LogoConnectionStatus {
  /// Henüz denetlenmedi
  unknown,

  /// Denetim sürüyor
  checking,

  /// Bağlantı kuruldu (yeşil)
  online,

  /// Help erişilebilir ancak pull için OAuth kimliği eksik
  credentialsMissing,

  /// Bağlantı kurulamadı (kırmızı)
  offline,
}

/// {@template logo_health_probe_result}
/// Tek sağlık denetimi çıktısı.
/// {@endtemplate}
class LogoHealthProbeResult {
  /// [ok]: Bağlantı kuruldu mu
  final bool ok;

  /// [detail]: Ham teknik detay (tooltip)
  final String? detail;

  /// [authReady]: Pull için OAuth kimlik bilgileri hazır mı
  final bool authReady;

  /// {@macro logo_health_probe_result}
  const LogoHealthProbeResult({
    required this.ok,
    this.detail,
    this.authReady = true,
  });

  /// Başarılı denetim.
  factory LogoHealthProbeResult.online({
    String? detail,
    bool authReady = true,
  }) =>
      LogoHealthProbeResult(
        ok: true,
        detail: detail,
        authReady: authReady,
      );

  /// Başarısız denetim.
  factory LogoHealthProbeResult.offline({String? detail}) =>
      LogoHealthProbeResult(ok: false, detail: detail);
}

/// {@template logo_connection_health}
/// Göstergenin okuduğu bağlantı sağlık anlık görüntüsü.
///
/// Kullanım örneği:
/// ```dart
/// final health = await LogoConnectionHealthChecker.shared.check();
/// final green = health.isOnline;
/// ```
/// {@endtemplate}
class LogoConnectionHealth {
  /// [status]: Bağlantı durumu
  final LogoConnectionStatus status;

  /// [checkedAt]: Son denetim zamanı
  final DateTime? checkedAt;

  /// [detail]: Ham teknik detay
  final String? detail;

  /// {@macro logo_connection_health}
  const LogoConnectionHealth({
    required this.status,
    this.checkedAt,
    this.detail,
  });

  /// Hiç denetlenmemiş başlangıç durumu.
  static const LogoConnectionHealth initial = LogoConnectionHealth(
    status: LogoConnectionStatus.unknown,
  );

  /// Gösterge yeşil mi?
  bool get isOnline => status == LogoConnectionStatus.online;

  /// Gösterge kırmızı mı?
  bool get isOffline => status == LogoConnectionStatus.offline;

  /// Durum etiketi l10n anahtarı.
  String get labelKey {
    switch (status) {
      case LogoConnectionStatus.online:
        return 'field_sales.logo_connection_online';
      case LogoConnectionStatus.credentialsMissing:
        return 'field_sales.logo_connection_credentials_missing';
      case LogoConnectionStatus.offline:
        return 'field_sales.logo_connection_offline';
      case LogoConnectionStatus.checking:
        return 'field_sales.logo_connection_checking';
      case LogoConnectionStatus.unknown:
        return 'field_sales.logo_connection_unknown';
    }
  }
}

/// {@template logo_health_probe}
/// Sağlık denetimi fonksiyonu (test için enjekte edilir).
/// {@endtemplate}
typedef LogoHealthProbe = Future<LogoHealthProbeResult> Function();

/// {@template logo_connection_health_checker}
/// Logo REST bağlantısını hafif bir istekle denetler.
///
/// Politika:
/// 1. Tiger REST açıksa OAuth gerektirmeyen `GET /services/help` kullanılır.
/// 2. Kapalıysa ExfinApi middleware `testConnection` çağrılır.
/// 3. [minInterval] içindeki tekrar istekler önbellekten döner (pil koruması).
/// 4. Eşzamanlı çağrılar tek denetimi paylaşır.
/// 5. Denetim asla exception fırlatmaz; hata `offline` olarak raporlanır.
///
/// Kullanım örneği:
/// ```dart
/// final health = await LogoConnectionHealthChecker.shared.check(force: true);
/// ```
/// {@endtemplate}
class LogoConnectionHealthChecker {
  /// [shared]: Uygulama genelinde tek örnek (aralık paylaşımı için)
  static final LogoConnectionHealthChecker shared =
      LogoConnectionHealthChecker();

  /// [probe]: Sağlık denetimi fonksiyonu
  final LogoHealthProbe probe;

  /// [minInterval]: İki gerçek denetim arasındaki en kısa süre
  final Duration minInterval;

  /// [_now]: Test edilebilir zaman kaynağı
  final DateTime Function() _now;

  LogoConnectionHealth _last = LogoConnectionHealth.initial;
  Future<LogoConnectionHealth>? _inFlight;

  /// {@macro logo_connection_health_checker}
  LogoConnectionHealthChecker({
    LogoHealthProbe? probe,
    this.minInterval = const Duration(seconds: 60),
    DateTime Function()? now,
  })  : probe = probe ?? defaultProbe,
        _now = now ?? DateTime.now;

  /// [last]: Son bilinen durum
  LogoConnectionHealth get last => _last;

  /// {@template logo_connection_health_checker_check}
  /// Bağlantıyı denetler.
  ///
  /// Parametreler:
  /// - [force]: `true` ise [minInterval] yok sayılır (manuel yenileme)
  ///
  /// Dönüş değeri:
  /// - [LogoConnectionHealth]: Güncel veya önbellekli durum
  /// {@endtemplate}
  Future<LogoConnectionHealth> check({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;

    final previousAt = _last.checkedAt;
    if (!force && previousAt != null) {
      final elapsed = _now().difference(previousAt);
      if (!elapsed.isNegative && elapsed < minInterval) {
        return Future.value(_last);
      }
    }

    final future = _run();
    _inFlight = future;
    return future;
  }

  Future<LogoConnectionHealth> _run() async {
    try {
      final result = await probe();
      _last = LogoConnectionHealth(
        status: !result.ok
            ? LogoConnectionStatus.offline
            : result.authReady
                ? LogoConnectionStatus.online
                : LogoConnectionStatus.credentialsMissing,
        checkedAt: _now(),
        detail: result.detail,
      );
    } on Object catch (error) {
      _last = LogoConnectionHealth(
        status: LogoConnectionStatus.offline,
        checkedAt: _now(),
        detail: error.toString(),
      );
    } finally {
      _inFlight = null;
    }
    return _last;
  }

  /// {@template logo_connection_health_checker_default_probe}
  /// Varsayılan denetim: Tiger açıksa help ping, değilse ExfinApi testi.
  /// {@endtemplate}
  static Future<LogoHealthProbeResult> defaultProbe() async {
    try {
      final tigerEnabled = await LogoTigerSettingsStore().isEnabled();
      if (tigerEnabled) {
        final store = LogoTigerSettingsStore();
        final config = await store.load();
        final result = await LogoTigerRestClient(store: store).pingHelp();
        return LogoHealthProbeResult(
          ok: result.success,
          detail: result.success
              ? config.hasAuthCredentials
                  ? 'HTTP ${result.statusCode ?? 200}'
                  : config.missingAuthFields.join(', ')
              : result.error,
          authReady: config.hasAuthCredentials,
        );
      }

      final api = LogoApiService();
      await api.ensureReady();
      final result = await api.testConnection();
      return LogoHealthProbeResult(
        ok: result.success,
        detail: result.success
            ? 'HTTP ${result.statusCode ?? 200}'
            : result.error,
      );
    } on Object catch (error) {
      debugPrint('LogoConnectionHealthChecker probe: ${error.runtimeType}');
      return LogoHealthProbeResult.offline(detail: error.toString());
    }
  }
}
