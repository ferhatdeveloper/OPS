// Dosya Adı: collection_currency_exchange.dart
// Açıklama: Tahsilat döviz kuru hesabı (seçilen → merkez varsayılan)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template collection_currency_exchange}
/// Tahsilat döviz dönüşümü — MBT: `1 işlem dövizi = [rate] merkez`.
///
/// Kullanım örneği:
/// ```dart
/// final base = CollectionCurrencyExchange.toBaseAmount(
///   amountInCurrency: 10,
///   exchangeRate: 47.25,
/// );
/// // 472.5
/// ```
/// {@endtemplate}
class CollectionCurrencyExchange {
  /// Merkez/tenant çözülemezse yedek kod
  static const String fallbackDefaultCode = 'TRY';

  CollectionCurrencyExchange._();

  /// {@template collection_currency_exchange_normalize}
  /// Para birimi kodunu normalize eder (`tl` → `TRY`).
  ///
  /// Parametreler:
  /// - [code]: Ham kod
  ///
  /// Dönüş değeri:
  /// - [String]: Büyük harf kod (boşsa boş)
  /// {@endtemplate}
  static String normalize(String? code) {
    final t = (code ?? '').trim().toUpperCase();
    if (t.isEmpty) return '';
    if (t == 'TL') return 'TRY';
    return t;
  }

  /// {@template collection_currency_exchange_is_default}
  /// Seçilen kod merkez varsayılanı mı.
  /// {@endtemplate}
  static bool isDefaultCurrency(String? selected, String? defaultCode) {
    final a = normalize(selected);
    final b = normalize(defaultCode);
    if (a.isEmpty || b.isEmpty) return a == b;
    return a == b;
  }

  /// {@template collection_currency_exchange_parse_rate}
  /// TR / EN ondalık kur metnini double? okur.
  ///
  /// Parametreler:
  /// - [raw]: Kur metni (`47,2497` / `47.2497`)
  ///
  /// Dönüş değeri:
  /// - [double?]: Geçerliyse kur
  /// {@endtemplate}
  static double? parseRate(String? raw) {
    if (raw == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (t.contains(',') && t.contains('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t);
  }

  /// {@template collection_currency_exchange_to_base}
  /// İşlem tutarını merkez dövize çevirir: `tutar × kur`.
  ///
  /// Parametreler:
  /// - [amountInCurrency]: Seçilen dövizdeki tutar
  /// - [exchangeRate]: 1 işlem dövizi = kaç merkez
  ///
  /// Dönüş değeri:
  /// - [double]: Merkez tutarı (geçersiz girdide 0)
  /// {@endtemplate}
  static double toBaseAmount({
    required double amountInCurrency,
    required double exchangeRate,
  }) {
    if (amountInCurrency <= 0 || exchangeRate <= 0) return 0;
    return amountInCurrency * exchangeRate;
  }

  /// {@template collection_currency_exchange_resolve_rate}
  /// Seçilen döviz için kur: varsayılan ise 1, değilse store map.
  ///
  /// Parametreler:
  /// - [currencyCode]: İşlem dövizi
  /// - [defaultCurrency]: Merkez varsayılan
  /// - [rates]: Kod → kur metni haritası
  ///
  /// Dönüş değeri:
  /// - [double]: Kur (≥ 0; bulunamazsa 0)
  /// {@endtemplate}
  static double resolveRate({
    required String currencyCode,
    required String defaultCurrency,
    required Map<String, String> rates,
  }) {
    if (isDefaultCurrency(currencyCode, defaultCurrency)) return 1.0;
    final code = normalize(currencyCode);
    if (code.isEmpty) return 0;
    final text = rates[code] ?? rates[currencyCode.trim()] ?? '';
    return parseRate(text) ?? 0;
  }

  /// {@template collection_currency_exchange_format_rate}
  /// Kuru dens metin olarak yazar (en fazla 6 ondalık, `.` ayırıcı).
  /// {@endtemplate}
  static String formatRate(double rate) {
    if (rate <= 0) return '';
    if (rate == rate.roundToDouble()) {
      return rate.toStringAsFixed(4);
    }
    var s = rate.toStringAsFixed(6);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      if (s.endsWith('.')) {
        s = s.substring(0, s.length - 1);
        break;
      }
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
