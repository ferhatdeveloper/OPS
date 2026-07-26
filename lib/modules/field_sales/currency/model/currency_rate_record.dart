// Dosya Adı: currency_rate_record.dart
// Açıklama: Döviz kuru kalıcılık kaydı (tarih + kod→kur map)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'currency_rate_seed.dart';

/// {@template currency_rate_record}
/// SharedPreferences'taki döviz kuru kaydı.
///
/// Kullanım örneği:
/// ```dart
/// final record = CurrencyRateRecord.defaults();
/// ```
/// {@endtemplate}
class CurrencyRateRecord {
  /// [rateDate]: Kur tarihi
  final DateTime rateDate;

  /// [rates]: Para birimi kodu → kur metni (TR ondalık)
  final Map<String, String> rates;

  /// {@macro currency_rate_record}
  const CurrencyRateRecord({
    required this.rateDate,
    required this.rates,
  });

  /// {@template currency_rate_record_defaults}
  /// MBT seed satırlarından varsayılan kayıt üretir.
  ///
  /// Parametreler:
  /// - [rateDate]: Kur tarihi (varsayılan: bugün)
  ///
  /// Dönüş değeri:
  /// - [CurrencyRateRecord]: Seed kurları ile kayıt
  /// {@endtemplate}
  factory CurrencyRateRecord.defaults({DateTime? rateDate}) {
    return CurrencyRateRecord(
      rateDate: rateDate ?? DateTime.now(),
      rates: {
        for (final row in CurrencyRateSeed.defaultRows)
          row.code: row.rateText,
      },
    );
  }

  /// {@template currency_rate_record_rate_of}
  /// Kod için kur metnini döner; yoksa boş.
  ///
  /// Parametreler:
  /// - [code]: Para birimi kodu
  ///
  /// Dönüş değeri:
  /// - [String]: Kur metni
  /// {@endtemplate}
  String rateOf(String code) => rates[code] ?? '';
}
