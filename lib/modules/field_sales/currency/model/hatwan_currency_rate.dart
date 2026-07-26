// Dosya Adı: hatwan_currency_rate.dart
// Açıklama: Hatwan Exchange serbest piyasa döviz satırı (alış/satış)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template hatwan_currency_rate}
/// Hatwan HTML Inertia `props.currencies[]` satırı.
///
/// Kullanım örneği:
/// ```dart
/// const rate = HatwanCurrencyRate(
///   code: 'USD',
///   name: 'Dollar',
///   buy: 1500,
///   sell: 1502.5,
/// );
/// ```
/// {@endtemplate}
class HatwanCurrencyRate {
  /// [code]: Para birimi kodu (USD, EUR, …)
  final String code;

  /// [name]: Kaynak adı (yerel dil olabilir)
  final String name;

  /// [buy]: Alış (IQD karşılığı; USD için 1 birim normalize)
  final double buy;

  /// [sell]: Satış (IQD karşılığı; USD için 1 birim normalize)
  final double sell;

  /// [updatedAt]: Kaynak `updated_at` (opsiyonel)
  final String? updatedAt;

  /// {@macro hatwan_currency_rate}
  const HatwanCurrencyRate({
    required this.code,
    required this.name,
    required this.buy,
    required this.sell,
    this.updatedAt,
  });
}
