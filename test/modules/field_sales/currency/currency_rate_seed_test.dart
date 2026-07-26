// Dosya Adı: currency_rate_seed_test.dart
// Açıklama: MBT Döviz Kuru seed kodları / route / tarih biçimi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/currency/model/currency_rate_seed.dart';
import 'package:exfin_ops/modules/field_sales/currency/view/currency_rates_screen.dart';

void main() {
  test('CurrencyRateSeed MBT kod sırası ve satır sayısı', () {
    expect(CurrencyRateSeed.codes, [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'SAR',
      'CNY',
      'IQD',
      'IRR',
      'TRY',
      'SYP',
      'TL',
    ]);
    expect(CurrencyRateSeed.defaultRows.length, CurrencyRateSeed.codes.length);
    expect(CurrencyRateSeed.defaultRows.first.code, 'USD');
    expect(CurrencyRateSeed.defaultRows.first.rateText, '47,2497');
    expect(CurrencyRateSeed.defaultRows.last.code, 'TL');
    expect(CurrencyRateSeed.defaultRows.last.rateText, '1,0000');
  });

  test('CurrencyRateSeed route ve submenu başlığı', () {
    expect(CurrencyRateSeed.route, '/field-sales/currency-rates');
    expect(CurrencyRateSeed.submenuTitle, 'Döviz Kuru');
    expect(CurrencyRatesScreen.routeName, CurrencyRateSeed.route);
  });

  test('CurrencyRateSeed.formatDate dd-MM-yyyy', () {
    expect(
      CurrencyRateSeed.formatDate(DateTime(2026, 7, 26)),
      '26-07-2026',
    );
  });
}
