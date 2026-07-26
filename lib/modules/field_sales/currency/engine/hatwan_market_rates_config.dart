// Dosya Adı: hatwan_market_rates_config.dart
// Açıklama: Hatwan serbest piyasa çekim URL / proxy yapılandırması
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template hatwan_market_rates_config}
/// RetailEX uyumlu Hatwan kaynak ayarları.
///
/// - Native (Android/iOS/desktop): doğrudan HTTPS GET yeterlidir.
/// - Web: tarayıcı CORS engeli → [proxyBaseUrl] zorunlu (RetailEX pg_bridge
///   tarzı `/api/market-rates/proxy?url=`).
/// - Android HTTP proxy: cleartext için
///   `network_security_config.xml` + `usesCleartextTraffic` iskeleti.
///
/// Kullanım örneği:
/// ```dart
/// const cfg = HatwanMarketRatesConfig();
/// ```
/// {@endtemplate}
class HatwanMarketRatesConfig {
  /// [exchangePageUrl]: Hatwan ana sayfa (Inertia HTML)
  final String exchangePageUrl;

  /// [proxyBaseUrl]: CORS / kurumsal proxy kökü (örn. `http://10.0.2.2:8787`)
  /// Boşsa doğrudan URL kullanılır (web'de CORS riski).
  final String proxyBaseUrl;

  /// [userAgent]: Kaynak istek başlığı
  final String userAgent;

  /// [connectTimeout]: HTTP zaman aşımı
  final Duration connectTimeout;

  /// {@macro hatwan_market_rates_config}
  const HatwanMarketRatesConfig({
    this.exchangePageUrl = HatwanMarketRatesConfig.defaultExchangePageUrl,
    this.proxyBaseUrl = '',
    this.userAgent = HatwanMarketRatesConfig.defaultUserAgent,
    this.connectTimeout = const Duration(seconds: 30),
  });

  /// [defaultExchangePageUrl]: RetailEX varsayılanı
  static const String defaultExchangePageUrl = 'https://hatwanexchange.com/';

  /// [defaultUserAgent]: Tanımlayıcı UA
  static const String defaultUserAgent = 'EXFINOPS-MarketRates/1.0';

  /// [usdPer100Threshold]: ≥ eşik → 100$ notu; ÷100 ile 1 USD
  static const double usdPer100Threshold = 10000;

  /// Proxy path — RetailEX `pg_bridge` ile aynı sözleşme.
  static const String proxyPath = '/api/market-rates/proxy';

  /// {@template hatwan_market_rates_config_resolve_fetch_url}
  /// Çekim URL'sini üretir (doğrudan veya proxy üzerinden).
  ///
  /// Parametreler:
  /// - [targetUrl]: Asıl kaynak URL
  ///
  /// Dönüş değeri:
  /// - [Uri]: GET adresi
  /// {@endtemplate}
  Uri resolveFetchUrl(String targetUrl) {
    final target = targetUrl.trim();
    final proxy = proxyBaseUrl.trim();
    if (proxy.isEmpty) {
      return Uri.parse(target);
    }
    final base = proxy.endsWith('/')
        ? proxy.substring(0, proxy.length - 1)
        : proxy;
    return Uri.parse('$base$proxyPath').replace(
      queryParameters: {'url': target},
    );
  }
}
