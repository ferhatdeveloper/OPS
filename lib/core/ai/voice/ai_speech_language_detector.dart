// Dosya Adı: ai_speech_language_detector.dart
// Açıklama: Konuşma metni dil algılama + TTS/STT locale eşlemesi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_speech_language_detector}
/// Yazılan / AI cevabı metninden dil kodu (tr/en/ar/ku/fa/de/ru).
///
/// Script aralıkları + anahtar kelime skorları. Visit intelligence `lang`
/// alanı ile uyumlu kısa kodlar. Tercih `auto` ise metinden algılar.
///
/// Kullanım örneği:
/// ```dart
/// final code = AiSpeechLanguageDetector.detect('Merhaba plasiyer');
/// final tts = AiSpeechLanguageDetector.ttsLocale(code); // tr-TR
/// final eff = AiSpeechLanguageDetector.resolve(
///   preference: 'auto',
///   text: 'Hello',
/// ); // en
/// ```
/// {@endtemplate}
class AiSpeechLanguageDetector {
  AiSpeechLanguageDetector._();

  /// Otomatik dil (metinden algıla).
  static const String auto = 'auto';

  /// Desteklenen kısa dil kodları.
  static const List<String> supportedCodes = [
    'tr',
    'en',
    'ar',
    'ku',
    'fa',
    'de',
    'ru',
  ];

  /// UI seçenekleri: Auto + sabit diller.
  static const List<String> preferenceOptions = [
    auto,
    ...supportedCodes,
  ];

  /// Chip / menü etiketi (ISO — l10n gerekmez).
  static String labelFor(String? preference) {
    final p = (preference ?? auto).trim().toLowerCase();
    if (p == auto || p.isEmpty) return 'Auto';
    final n = normalize(p);
    if (n == null) return 'Auto';
    return n.toUpperCase();
  }

  /// TTS BCP-47 benzeri locale (flutter_tts `setLanguage`).
  static const Map<String, String> ttsLocales = {
    'tr': 'tr-TR',
    'en': 'en-US',
    'ar': 'ar-SA',
    'ku': 'ku', // Cihazda yoksa motor tr-TR’ye düşer
    'fa': 'fa-IR',
    'de': 'de-DE',
    'ru': 'ru-RU',
  };

  /// TTS yedek locale listesi (önce tercih, sonra fallback).
  static const Map<String, List<String>> ttsLocaleCandidates = {
    'tr': ['tr-TR', 'tr_TR', 'tr'],
    'en': ['en-US', 'en_US', 'en-GB', 'en'],
    'ar': ['ar-SA', 'ar_SA', 'ar-IQ', 'ar_IQ', 'ar'],
    'ku': ['ku', 'ckb-IQ', 'ckb_IQ', 'ckb', 'ku-IQ', 'tr-TR', 'tr'],
    'fa': ['fa-IR', 'fa_IR', 'fa'],
    'de': ['de-DE', 'de_DE', 'de'],
    'ru': ['ru-RU', 'ru_RU', 'ru'],
  };

  /// STT `localeId` (speech_to_text — genelde `_` ayırıcı).
  static const Map<String, String> sttLocales = {
    'tr': 'tr_TR',
    'en': 'en_US',
    'ar': 'ar_SA',
    'ku': 'ku_IQ',
    'fa': 'fa_IR',
    'de': 'de_DE',
    'ru': 'ru_RU',
  };

  /// {@template ai_speech_language_detector_tts_locale}
  /// Kısa kod → TTS locale; bilinmeyen → tr-TR.
  ///
  /// Parametreler:
  /// - [code]: Kısa dil kodu
  ///
  /// Dönüş değeri:
  /// - [String]: flutter_tts dili
  /// {@endtemplate}
  static String ttsLocale(String? code) {
    final c = normalize(code) ?? 'tr';
    return ttsLocales[c] ?? 'tr-TR';
  }

  /// {@template ai_speech_language_detector_tts_candidates}
  /// TTS için denenecek locale adayları.
  ///
  /// Parametreler:
  /// - [code]: Kısa dil kodu
  ///
  /// Dönüş değeri:
  /// - [List<String>]: Aday locale listesi
  /// {@endtemplate}
  static List<String> ttsCandidates(String? code) {
    final c = normalize(code) ?? 'tr';
    return List<String>.unmodifiable(
      ttsLocaleCandidates[c] ?? ttsLocaleCandidates['tr']!,
    );
  }

  /// {@template ai_speech_language_detector_stt_locale}
  /// Kısa kod → STT localeId.
  ///
  /// Parametreler:
  /// - [code]: Kısa dil kodu
  ///
  /// Dönüş değeri:
  /// - [String]: speech_to_text localeId
  /// {@endtemplate}
  static String sttLocale(String? code) {
    final c = normalize(code) ?? 'tr';
    return sttLocales[c] ?? 'tr_TR';
  }

  /// {@template ai_speech_language_detector_normalize}
  /// Dil kodunu desteklenen forma getirir.
  ///
  /// Parametreler:
  /// - [raw]: Ham kod (tr, tr-TR, ckb, …)
  ///
  /// Dönüş değeri:
  /// - [String?]: Normalize kod veya null
  /// {@endtemplate}
  static String? normalize(String? raw) {
    var code = (raw ?? '').trim().toLowerCase().replaceAll('_', '-');
    if (code.isEmpty) return null;
    if (code.contains('-')) {
      code = code.split('-').first;
    }
    if (code == 'ckb') return 'ku';
    if (supportedCodes.contains(code)) return code;
    return null;
  }

  /// {@template ai_speech_language_detector_normalize_preference}
  /// Tercih değerini `auto` veya desteklenen dile normalize eder.
  ///
  /// Parametreler:
  /// - [raw]: Ham tercih
  ///
  /// Dönüş değeri:
  /// - [String]: auto | tr | en | …
  /// {@endtemplate}
  static String normalizePreference(String? raw) {
    final code = (raw ?? '').trim().toLowerCase();
    if (code.isEmpty || code == auto) return auto;
    return normalize(code) ?? auto;
  }

  /// {@template ai_speech_language_detector_resolve}
  /// Kullanıcı tercihi + metin → etkili dil kodu.
  ///
  /// Parametreler:
  /// - [preference]: auto veya sabit dil
  /// - [text]: Algı için metin (AI cevabı / yazılan)
  /// - [fallback]: Auto’da belirsiz metin varsayılanı
  ///
  /// Dönüş değeri:
  /// - [String]: tr | en | ar | ku | fa | de | ru
  /// {@endtemplate}
  static String resolve({
    String? preference,
    String? text,
    String fallback = 'tr',
  }) {
    final pref = normalizePreference(preference);
    if (pref != auto) return pref;
    return detect(text, fallback: fallback);
  }

  /// {@template ai_speech_language_detector_detect}
  /// Metinden dil kodu üretir. Boş / belirsiz → [fallback].
  ///
  /// Parametreler:
  /// - [text]: Algılanacak metin
  /// - [fallback]: Varsayılan (genelde uygulama dili)
  ///
  /// Dönüş değeri:
  /// - [String]: tr | en | ar | ku | fa | de | ru
  /// {@endtemplate}
  static String detect(String? text, {String fallback = 'tr'}) {
    final fb = normalize(fallback) ?? 'tr';
    final raw = (text ?? '').trim();
    if (raw.isEmpty) return fb;

    final arabic = _countMatches(raw, _arabicScript);
    final cyrillic = _countMatches(raw, _cyrillicScript);
    final latin = _countMatches(raw, _latinScript);
    final totalLetters = arabic + cyrillic + latin;
    if (totalLetters == 0) return fb;

    if (cyrillic > arabic && cyrillic > latin) {
      return 'ru';
    }

    if (arabic >= latin && arabic >= cyrillic && arabic > 0) {
      return _detectArabicScriptFamily(raw, fallback: fb);
    }

    return _detectLatinFamily(raw, fallback: fb);
  }

  /// {@template ai_speech_language_detector_stt_for_input}
  /// STT locale: sabit tercih → o dil; Auto → yazılan metin / app dili.
  ///
  /// Parametreler:
  /// - [preference]: auto veya sabit dil
  /// - [typedText]: Metin alanı içeriği
  /// - [appOrDeviceLang]: Uygulama veya cihaz dil kodu
  ///
  /// Dönüş değeri:
  /// - [String]: STT localeId
  /// {@endtemplate}
  static String sttLocaleForInput({
    String? preference,
    String? typedText,
    String? appOrDeviceLang,
  }) {
    final pref = normalizePreference(preference);
    final fb = normalize(appOrDeviceLang) ?? 'tr';
    if (pref != auto) return sttLocale(pref);
    final typed = (typedText ?? '').trim();
    if (typed.length >= 2) {
      return sttLocale(detect(typed, fallback: fb));
    }
    return sttLocale(fb);
  }

  static String _detectArabicScriptFamily(
    String text, {
    required String fallback,
  }) {
    final kuChars = _countMatches(text, _kuDistinctive);
    final faChars = _countMatches(text, _faDistinctive);
    final arMarks = _countMatches(text, _arDistinctive);

    final scores = <String, int>{
      'ku': kuChars * 4 + _keywordHits(text, _kuArKeywords) * 3,
      'fa': faChars * 3 + _keywordHits(text, _faKeywords) * 3,
      'ar': arMarks * 2 + _keywordHits(text, _arKeywords) * 3,
    };

    return _bestScore(scores, fallback: 'ar');
  }

  static String _detectLatinFamily(String text, {required String fallback}) {
    final lower = text.toLowerCase();
    final scores = <String, int>{
      'tr': _countMatches(text, _trChars) * 3 +
          _keywordHits(lower, _trKeywords) * 2,
      'de': _countMatches(text, _deChars) * 3 +
          _keywordHits(lower, _deKeywords) * 2,
      'ku': _countMatches(text, _kuLatinChars) * 2 +
          _keywordHits(lower, _kuLatinKeywords) * 3,
      'en': _keywordHits(lower, _enKeywords) * 2,
    };

    // Türkçe karakter yoksa ve İngilizce skor yüksekse EN
    if (scores['tr'] == 0 && scores['de'] == 0 && scores['ku'] == 0) {
      if ((scores['en'] ?? 0) > 0) return 'en';
      return fallback;
    }

    return _bestScore(scores, fallback: fallback);
  }

  static String _bestScore(
    Map<String, int> scores, {
    required String fallback,
  }) {
    var best = fallback;
    var bestScore = -1;
    scores.forEach((code, score) {
      if (score > bestScore) {
        bestScore = score;
        best = code;
      }
    });
    if (bestScore <= 0) return fallback;
    return best;
  }

  static int _countMatches(String text, RegExp re) =>
      re.allMatches(text).length;

  static int _keywordHits(String text, List<String> words) {
    final tokens = text
        .toLowerCase()
        .split(RegExp(r'[^\w\u0400-\u04FF\u0600-\u06FF]+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    var hits = 0;
    for (final w in words) {
      if (tokens.contains(w.toLowerCase())) hits++;
    }
    return hits;
  }

  // --- Script / char ranges ---

  static final RegExp _arabicScript = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _cyrillicScript = RegExp(r'[\u0400-\u04FF]');
  static final RegExp _latinScript = RegExp(r'[A-Za-z\u00C0-\u024F]');

  static final RegExp _trChars = RegExp(r'[ğüşıöçĞÜŞİÖÇ]');
  static final RegExp _deChars = RegExp(r'[äöüßÄÖÜ]');
  static final RegExp _kuLatinChars = RegExp(r'[êîûÊÎÛ]');
  static final RegExp _kuDistinctive = RegExp(r'[ڕڵێۆڤھ]');
  static final RegExp _faDistinctive = RegExp(r'[پچژگکیی]');
  static final RegExp _arDistinctive = RegExp(r'[ةىأإآ]');

  static const List<String> _trKeywords = [
    've',
    'bir',
    'için',
    'değil',
    'ile',
    'bu',
    'şu',
    'olarak',
    'sipariş',
    'müşteri',
    'plasiyer',
    'merhaba',
    'teşekkür',
    'lütfen',
    'nedir',
    'nasıl',
  ];

  static const List<String> _enKeywords = [
    'the',
    'and',
    'is',
    'are',
    'you',
    'for',
    'with',
    'this',
    'that',
    'please',
    'hello',
    'order',
    'customer',
    'what',
    'how',
    'thank',
  ];

  static const List<String> _deKeywords = [
    'und',
    'der',
    'die',
    'das',
    'ist',
    'nicht',
    'bitte',
    'hallo',
    'kunde',
    'bestellung',
    'was',
    'wie',
    'danke',
  ];

  static const List<String> _kuLatinKeywords = [
    'û',
    'bi',
    'ji',
    're',
    'ye',
    'ne',
    'ez',
    'tu',
    'ew',
    'spas',
  ];

  static const List<String> _arKeywords = [
    'في',
    'من',
    'على',
    'هذا',
    'هذه',
    'التي',
    'التي',
    'مرحبا',
    'شكرا',
    'طلب',
    'عميل',
  ];

  static const List<String> _faKeywords = [
    'است',
    'این',
    'که',
    'برای',
    'با',
    'می',
    'سلام',
    'لطفا',
    'سفارش',
    'مشتری',
  ];

  static const List<String> _kuArKeywords = [
    'بە',
    'لە',
    'بوو',
    'نە',
    'ئەم',
    'سڵاو',
    'سوپاس',
    'داواکاری',
  ];
}
