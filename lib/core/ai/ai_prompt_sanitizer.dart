// Dosya Adı: ai_prompt_sanitizer.dart
// Açıklama: AI prompt PII maskeleme (ad / telefon) — key log yok
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_prompt_sanitizer}
/// Forecast / vision prompt’larına giden metni PII açısından temizler.
/// API key asla bu sınıfa verilmez; loglanmaz.
///
/// Kullanım örneği:
/// ```dart
/// final s = AiPromptSanitizer.sanitize('Ali 0532 111 22 33');
/// // → [NAME] [PHONE]
/// ```
/// {@endtemplate}
class AiPromptSanitizer {
  AiPromptSanitizer._();

  /// TR cep / sabit benzeri telefon kalıpları
  static final RegExp _phone = RegExp(
    r'(?:\+?90[\s\-]?)?(?:0?5\d{2}|0?\d{3})[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}'
    r'|\b\d{3}[\s\-]?\d{3}[\s\-]?\d{4}\b',
  );

  /// E-posta
  static final RegExp _email = RegExp(
    r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );

  /// Ünvan / kişi adı benzeri: 2–4 kelime, büyük harf / Türkçe harf
  static final RegExp _personLike = RegExp(
    r'\b([A-ZÇĞİÖŞÜ][a-zçğıöşü]{1,30}'
    r'(?:\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]{1,30}){1,3})\b',
  );

  /// {@template ai_prompt_sanitizer_sanitize}
  /// Telefon / e-posta / kişi adı benzeri metni maskeler.
  ///
  /// Parametreler:
  /// - [input]: Ham prompt parçası
  ///
  /// Dönüş değeri:
  /// - [String]: Maskelenmiş metin
  /// {@endtemplate}
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    var out = input;
    out = out.replaceAllMapped(_email, (_) => '[EMAIL]');
    out = out.replaceAllMapped(_phone, (_) => '[PHONE]');
    out = out.replaceAllMapped(_personLike, (m) {
      final t = m.group(0) ?? '';
      // Kod benzeri (kısa ALLCAPS / alfanumerik) dokunma
      if (RegExp(r'^[A-Z0-9_\-]{1,12}$').hasMatch(t)) return t;
      // Ürün / kategori tek kelime dokunma — yalnızca 2+ kelime
      if (!t.contains(' ')) return t;
      return '[NAME]';
    });
    return out;
  }

  /// {@template ai_prompt_sanitizer_redact_secrets}
  /// Log satırından API key benzeri secret’ları çıkarır (audit).
  /// {@endtemplate}
  static String redactSecrets(String line) {
    if (line.isEmpty) return line;
    var out = line;
    // sk-… / Bearer … / x-api-key değerleri
    out = out.replaceAllMapped(
      RegExp(
        r'(sk-[A-Za-z0-9_\-]{8,})|(Bearer\s+)[A-Za-z0-9\-._~+/]+=*',
        caseSensitive: false,
      ),
      (m) {
        if (m.group(2) != null) return '${m.group(2)}[REDACTED]';
        return '[REDACTED_KEY]';
      },
    );
    out = out.replaceAllMapped(
      RegExp(
        r'((?:api[_-]?key|x-api-key|authorization)\s*[:=]\s*)\S+',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}[REDACTED]',
    );
    return out;
  }
}
