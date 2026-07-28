// Dosya Adı: default_currency_resolver_test.dart
// Açıklama: Merkez varsayılan döviz çözümleyici birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/modules/field_sales/currency/engine/collection_currency_exchange.dart';
import 'package:exfin_ops/modules/field_sales/currency/viewmodel/default_currency_resolver.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('firma dövizi öncelikli', () async {
    final resolver = DefaultCurrencyResolver(
      queryCompanyCurrency: (id, no) async => 'iqd',
      getSetting: (_) async => 'TRY',
    );
    expect(await resolver.resolve(), 'IQD');
  });

  test('firma yoksa settings', () async {
    final resolver = DefaultCurrencyResolver(
      queryCompanyCurrency: (id, no) async => null,
      getSetting: (key) async {
        if (key == DefaultCurrencyResolver.settingKeyAlt) return 'usd';
        return null;
      },
    );
    expect(await resolver.resolve(), 'USD');
  });

  test('hiçbiri yoksa TRY yedek', () async {
    final resolver = DefaultCurrencyResolver(
      queryCompanyCurrency: (id, no) async => null,
      getSetting: (_) async => null,
    );
    expect(
      await resolver.resolve(),
      CollectionCurrencyExchange.fallbackDefaultCode,
    );
  });

  test('prefs override settings sonrası', () async {
    await const DefaultCurrencyResolver().savePrefs('EUR');
    final resolver = DefaultCurrencyResolver(
      queryCompanyCurrency: (id, no) async => null,
      getSetting: (_) async => null,
    );
    expect(await resolver.resolve(), 'EUR');
  });
}
