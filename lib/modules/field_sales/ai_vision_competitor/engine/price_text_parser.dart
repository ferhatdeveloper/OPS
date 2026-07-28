// Dosya Adı: price_text_parser.dart
// Açıklama: Raf etiketi fiyat metnini double’a çevirir (çoklu dil)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template price_text_parser}
/// "12,50 TL", "₺15.99", "1.250,00" vb. → double?
///
/// Kullanım örneği:
/// ```dart
/// PriceTextParser.parse('12,50 TL'); // 12.5
/// ```
/// {@endtemplate}
class PriceTextParser {
  PriceTextParser._();

  /// Para birimi / gürültü temizliği
  static final RegExp _noise = RegExp(
    r'(tl|try|usd|eur|₺|\$|€|£|iqd|irr|rub|¥)',
    caseSensitive: false,
  );

  /// {@template price_text_parser_parse}
  /// Metinden fiyat çıkar.
  ///
  /// Dönüş değeri:
  /// - [double?]: Geçersizse null
  /// {@endtemplate}
  static double? parse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(_noise, '').trim();
    // Yalnız sayı, nokta, virgül, boşluk, eksi
    s = s.replaceAll(RegExp(r'[^\d,.\-]'), '').trim();
    if (s.isEmpty || s == '-' || s == '.' || s == ',') return null;

    // Hem nokta hem virgül: Avrupa (1.234,56) vs US (1,234.56)
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastComma > lastDot) {
        // 1.234,56
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,234.56
        s = s.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      // 12,50 veya 1.250 → virgül ondalık varsay
      final parts = s.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        s = '${parts[0]}.${parts[1]}';
      } else {
        s = s.replaceAll(',', '');
      }
    }

    return double.tryParse(s);
  }
}
