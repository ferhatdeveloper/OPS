// Dosya Adı: currency_rate_seed.dart
// Açıklama: MBT Döviz Kuru dens listesi için kur seed satırları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template currency_rate_seed_row}
/// Tek döviz satırı (kod + kur metni, TR ondalık).
///
/// Kullanım örneği:
/// ```dart
/// const row = CurrencyRateSeedRow(code: 'USD', rateText: '47,2497');
/// ```
/// {@endtemplate}
class CurrencyRateSeedRow {
  /// [code]: Para birimi kodu (USD, EUR, …)
  final String code;

  /// [rateText]: Kur değeri (TR: `47,2497`)
  final String rateText;

  /// {@macro currency_rate_seed_row}
  const CurrencyRateSeedRow({
    required this.code,
    required this.rateText,
  });
}

/// {@template currency_rate_seed}
/// MBT Döviz Kuru ekranı seed listesi (cihaz gözlemi 14_doviz).
///
/// Kullanım örneği:
/// ```dart
/// final rows = CurrencyRateSeed.defaultRows;
/// ```
/// {@endtemplate}
class CurrencyRateSeed {
  CurrencyRateSeed._();

  /// [codes]: MBT sıra — USD…TL
  static const List<String> codes = [
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
  ];

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/currency-rates';

  /// [submenuTitle]: Menü seed alt başlık (MBT: Döviz Kuru)
  static const String submenuTitle = 'Döviz Kuru';

  /// Yer tutucu dens satırlar (MBT örnek kurlar).
  static const List<CurrencyRateSeedRow> defaultRows = [
    CurrencyRateSeedRow(code: 'USD', rateText: '47,2497'),
    CurrencyRateSeedRow(code: 'EUR', rateText: '53,7918'),
    CurrencyRateSeedRow(code: 'GBP', rateText: '63,0648'),
    CurrencyRateSeedRow(code: 'JPY', rateText: '0,2892'),
    CurrencyRateSeedRow(code: 'SAR', rateText: '12,5872'),
    CurrencyRateSeedRow(code: 'CNY', rateText: '7,0147'),
    CurrencyRateSeedRow(code: 'IQD', rateText: '0,0000'),
    CurrencyRateSeedRow(code: 'IRR', rateText: '0,0000'),
    CurrencyRateSeedRow(code: 'TRY', rateText: '1,0000'),
    CurrencyRateSeedRow(code: 'SYP', rateText: '0,0000'),
    CurrencyRateSeedRow(code: 'TL', rateText: '1,0000'),
  ];

  /// {@template currency_rate_seed_format_date}
  /// Tarihi MBT biçiminde `dd-MM-yyyy` döndürür.
  ///
  /// Parametreler:
  /// - [date]: Biçimlenecek gün
  ///
  /// Dönüş değeri:
  /// - [String]: `26-07-2026` gibi metin
  /// {@endtemplate}
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d-$m-$y';
  }
}
