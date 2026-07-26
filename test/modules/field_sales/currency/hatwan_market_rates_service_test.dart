// Dosya Adı: hatwan_market_rates_service_test.dart
// Açıklama: Hatwan Inertia scrape parse / USD normalize birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/currency/engine/hatwan_market_rates_config.dart';
import 'package:exfin_ops/modules/field_sales/currency/engine/hatwan_market_rates_service.dart';

void main() {
  group('HatwanMarketRatesService normalize / format', () {
    test('USD 100\$ notu ≥10000 → ÷100', () {
      expect(HatwanMarketRatesService.normalizeUsdToPer1(151000), 1510);
      expect(HatwanMarketRatesService.normalizeUsdToPer1(152000), 1520);
      expect(HatwanMarketRatesService.normalizeUsdToPer1(1500), 1500);
      expect(HatwanMarketRatesService.normalizeUsdToPer1(0), 0);
    });

    test('formatRateTr virgüllü TR metin', () {
      expect(HatwanMarketRatesService.formatRateTr(1520), '1520,0000');
      expect(HatwanMarketRatesService.formatRateTr(112.85), '112,8500');
    });
  });

  group('HatwanMarketRatesConfig proxy', () {
    test('proxy boşsa doğrudan URL', () {
      const cfg = HatwanMarketRatesConfig();
      expect(
        cfg.resolveFetchUrl(HatwanMarketRatesConfig.defaultExchangePageUrl),
        Uri.parse(HatwanMarketRatesConfig.defaultExchangePageUrl),
      );
    });

    test('proxy doluysa RetailEX path + url query', () {
      const cfg = HatwanMarketRatesConfig(
        proxyBaseUrl: 'http://10.0.2.2:8787',
      );
      final uri = cfg.resolveFetchUrl('https://hatwanexchange.com/');
      expect(uri.scheme, 'http');
      expect(uri.host, '10.0.2.2');
      expect(uri.port, 8787);
      expect(uri.path, HatwanMarketRatesConfig.proxyPath);
      expect(uri.queryParameters['url'], 'https://hatwanexchange.com/');
    });
  });

  group('HatwanMarketRatesService.parseInertiaHtml', () {
    test('fixture HTML → USD normalize + Aud→AUD', () {
      final file = File(
        'test/modules/field_sales/currency/fixtures/hatwan_home_sample.html',
      );
      expect(file.existsSync(), isTrue);
      final rates = HatwanMarketRatesService.parseInertiaHtml(
        file.readAsStringSync(),
      );
      expect(rates.length, 4);

      final usd = rates.firstWhere((r) => r.code == 'USD');
      expect(usd.buy, 1510);
      expect(usd.sell, 1520);

      final eur = rates.firstWhere((r) => r.code == 'EUR');
      expect(eur.buy, 1600);
      expect(eur.sell, 1650);

      final aud = rates.firstWhere((r) => r.code == 'AUD');
      expect(aud.sell, 69);

      final byCode = HatwanMarketRatesService.sellRatesByCode(rates);
      expect(byCode['USD'], 1520);
      expect(byCode['TRY'], 42);
    });

    test('data-page yoksa exception', () {
      expect(
        () => HatwanMarketRatesService.parseInertiaHtml('<html></html>'),
        throwsA(isA<HatwanMarketRatesException>()),
      );
    });
  });
}
