// Dosya Adı: hatwan_market_rates_service.dart
// Açıklama: Hatwan HTML Inertia scrape — serbest piyasa kur çekimi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../model/hatwan_currency_rate.dart';
import 'hatwan_market_rates_config.dart';

/// {@template hatwan_market_rates_exception}
/// Hatwan çekim / parse hatası.
/// {@endtemplate}
class HatwanMarketRatesException implements Exception {
  /// [message]: Kullanıcıya / log'a gösterilecek mesaj
  final String message;

  /// {@macro hatwan_market_rates_exception}
  const HatwanMarketRatesException(this.message);

  @override
  String toString() => 'HatwanMarketRatesException: $message';
}

/// {@template hatwan_market_rates_service}
/// RetailEX `fetchHatwanCurrencies` eşdeğeri — manuel pull iskeleti.
///
/// HTML içinde `data-page="..."` Inertia JSON → `props.currencies[]`.
/// USD ≥ [HatwanMarketRatesConfig.usdPer100Threshold] ise ÷100.
///
/// Kullanım örneği:
/// ```dart
/// final rates = await HatwanMarketRatesService().fetchCurrencies();
/// ```
/// {@endtemplate}
class HatwanMarketRatesService {
  /// [config]: Kaynak / proxy ayarları
  final HatwanMarketRatesConfig config;

  /// [_client]: Enjekte edilebilir HTTP istemcisi (test)
  final http.Client _client;

  /// {@macro hatwan_market_rates_service}
  HatwanMarketRatesService({
    this.config = const HatwanMarketRatesConfig(),
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// {@template hatwan_normalize_usd_to_per1}
  /// 100$ notu kurunu 1 USD'ye indirger.
  ///
  /// Parametreler:
  /// - [value]: Ham alış/satış
  ///
  /// Dönüş değeri:
  /// - [double]: Normalize değer (geçersizse 0)
  /// {@endtemplate}
  static double normalizeUsdToPer1(double value) {
    if (!_isValidPrice(value)) return 0;
    if (value >= HatwanMarketRatesConfig.usdPer100Threshold) {
      return value / 100;
    }
    return value;
  }

  /// {@template hatwan_format_rate_tr}
  /// Kur değerini dens TR ondalık metnine çevirir (`47,2497`).
  ///
  /// Parametreler:
  /// - [value]: Sayısal kur
  /// - [fractionDigits]: Ondalık basamak (varsayılan 4)
  ///
  /// Dönüş değeri:
  /// - [String]: Virgüllü metin
  /// {@endtemplate}
  static String formatRateTr(double value, {int fractionDigits = 4}) {
    if (!_isValidPrice(value)) return '0,0000';
    return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
  }

  /// {@template hatwan_decode_html_entities}
  /// Inertia `data-page` HTML entity çözümlemesi.
  ///
  /// Parametreler:
  /// - [s]: Ham attribute değeri
  ///
  /// Dönüş değeri:
  /// - [String]: JSON metni
  /// {@endtemplate}
  static String decodeHtmlEntities(String s) {
    return s
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'");
  }

  /// {@template hatwan_parse_inertia_html}
  /// Hatwan HTML gövdesinden kur listesini parse eder.
  ///
  /// Parametreler:
  /// - [html]: Sayfa HTML
  ///
  /// Dönüş değeri:
  /// - [List<HatwanCurrencyRate>]: Geçerli kurlar
  ///
  /// Fırlatılan hatalar:
  /// - [HatwanMarketRatesException]: data-page yok / JSON bozuk
  /// {@endtemplate}
  static List<HatwanCurrencyRate> parseInertiaHtml(String html) {
    final match = RegExp(r'data-page="([^"]+)"').firstMatch(html);
    if (match == null || match.group(1) == null) {
      throw const HatwanMarketRatesException(
        'Hatwan: sayfa verisi bulunamadı',
      );
    }
    final decoded = decodeHtmlEntities(match.group(1)!);
    late final Map<String, dynamic> page;
    try {
      final dynamic parsed = jsonDecode(decoded);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('root not object');
      }
      page = parsed;
    } on FormatException {
      throw const HatwanMarketRatesException(
        'Hatwan: Inertia JSON çözülemedi',
      );
    }

    final props = page['props'];
    if (props is! Map) {
      return const <HatwanCurrencyRate>[];
    }
    final list = props['currencies'];
    if (list is! List) {
      return const <HatwanCurrencyRate>[];
    }

    final rates = <HatwanCurrencyRate>[];
    for (final item in list) {
      if (item is! Map) continue;
      final codeRaw = item['currency_code']?.toString().trim() ?? '';
      if (codeRaw.isEmpty) continue;
      final buy = _toDouble(item['buy']);
      final sell = _toDouble(item['sale']);
      if (!_isValidPrice(buy) || !_isValidPrice(sell)) continue;

      final code = codeRaw.toUpperCase();
      var buyN = buy;
      var sellN = sell;
      if (code == 'USD') {
        buyN = normalizeUsdToPer1(buy);
        sellN = normalizeUsdToPer1(sell);
      }

      rates.add(
        HatwanCurrencyRate(
          code: code,
          name: (item['name']?.toString() ?? codeRaw).trim(),
          buy: buyN,
          sell: sellN,
          updatedAt: item['updated_at']?.toString(),
        ),
      );
    }
    return rates;
  }

  /// {@template hatwan_fetch_currencies}
  /// Manuel pull: HTML GET → Inertia parse.
  ///
  /// Web'de [HatwanMarketRatesConfig.proxyBaseUrl] boşsa CORS hatası
  /// fırlatır (doğrudan tarayıcı isteği engellenir).
  ///
  /// Dönüş değeri:
  /// - [List<HatwanCurrencyRate>]: Kur listesi
  ///
  /// Fırlatılan hatalar:
  /// - [HatwanMarketRatesException]: ağ / CORS / parse
  /// {@endtemplate}
  Future<List<HatwanCurrencyRate>> fetchCurrencies() async {
    if (kIsWeb && config.proxyBaseUrl.trim().isEmpty) {
      throw const HatwanMarketRatesException(
        'Hatwan: web CORS — proxyBaseUrl gerekli',
      );
    }

    final target = config.exchangePageUrl.trim();
    if (target.isEmpty) {
      throw const HatwanMarketRatesException('Hatwan: URL boş');
    }

    final uri = config.resolveFetchUrl(target);
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': config.userAgent,
              'Accept': 'text/html,application/json,*/*',
            },
          )
          .timeout(config.connectTimeout);
    } catch (e) {
      throw HatwanMarketRatesException('Hatwan: ağ hatası ($e)');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HatwanMarketRatesException(
        'Hatwan: HTTP ${response.statusCode}',
      );
    }

    var body = response.body;
    // Proxy JSON sözleşmesi: { "text": "<html>...", "ok": true }
    if (config.proxyBaseUrl.trim().isNotEmpty) {
      final trimmed = body.trimLeft();
      if (trimmed.startsWith('{')) {
        try {
          final dynamic json = jsonDecode(body);
          if (json is Map && json['text'] is String) {
            body = json['text'] as String;
          }
        } on FormatException {
          // Ham HTML gelebilir — scrape devam
        }
      }
    }

    return parseInertiaHtml(body);
  }

  /// {@template hatwan_rates_by_code}
  /// Kod → satış kuru haritası (dens satır doldurma).
  ///
  /// Parametreler:
  /// - [rates]: Parse edilmiş liste
  ///
  /// Dönüş değeri:
  /// - [Map<String, double>]: `USD` → sell
  /// {@endtemplate}
  static Map<String, double> sellRatesByCode(
    List<HatwanCurrencyRate> rates,
  ) {
    return {
      for (final r in rates) r.code: r.sell,
    };
  }

  static bool _isValidPrice(double v) => v.isFinite && v > 0;

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }
}
