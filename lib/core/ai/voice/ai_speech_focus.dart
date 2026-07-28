// Dosya Adı: ai_speech_focus.dart
// Açıklama: STT odak — transcript temizliği, güven eşiği, ses seviyesi kapısı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_speech_focus}
/// Çevre gürültüsünü azaltmak için transcript temizleyici + ses seviyesi kapısı.
///
/// Kullanım örneği:
/// ```dart
/// final clean = AiSpeechFocus.cleanTranscript('ee selam  ');
/// final ok = AiSpeechFocus.isVoiceLevelUseful(-10);
/// ```
/// {@endtemplate}
class AiSpeechFocus {
  AiSpeechFocus._();

  /// [minSoundLevel]: Bu seviyenin altı çevre gürültüsü sayılır (speech_to_text dB)
  static const double minSoundLevel = -22;

  /// [minConfidence]: Final sonuç güven eşiği (0–1); -1 yok sayılır
  static const double minConfidence = 0.45;

  /// [minFinalChars]: Çok kısa final sonuçları reddet
  static const int minFinalChars = 2;

  /// Dolgu / gürültü kelimeleri (TR + genel)
  static const Set<String> _fillerTokens = {
    'ee',
    'eee',
    'aa',
    'aaa',
    'ıı',
    'hmm',
    'hımm',
    'hm',
    'uh',
    'um',
    'şey',
    'yani',
  };

  /// {@template ai_speech_focus_clean}
  /// Tanınan metni temizler: boşluk, tekrar, dolgu kelimeleri.
  ///
  /// Parametreler:
  /// - [raw]: Ham STT metni
  ///
  /// Dönüş değeri:
  /// - [String]: Temiz metin
  /// {@endtemplate}
  static String cleanTranscript(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return '';
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    // Ardışık aynı kelime tekrarı (gürültü yankısı)
    final parts = t.split(' ');
    final out = <String>[];
    String? prev;
    for (final p in parts) {
      final low = p.toLowerCase();
      if (_fillerTokens.contains(low) && out.isEmpty) continue;
      if (prev != null && prev.toLowerCase() == low) continue;
      out.add(p);
      prev = p;
    }
    return out.join(' ').trim();
  }

  /// {@template ai_speech_focus_voice_level}
  /// Mikrofon seviyesi konuşma için yeterli mi?
  ///
  /// Parametreler:
  /// - [level]: speech_to_text onSoundLevelChange değeri
  ///
  /// Dönüş değeri:
  /// - [bool]: true = sese odaklanılabilir
  /// {@endtemplate}
  static bool isVoiceLevelUseful(double level) {
    // Paket tipik aralık ~ -2 … 10; çok düşük = sessizlik / uzak gürültü
    return level >= minSoundLevel;
  }

  /// {@template ai_speech_focus_accept_final}
  /// Final STT sonucunu kabul et?
  ///
  /// Parametreler:
  /// - [text]: Temizlenmiş metin
  /// - [confidence]: 0–1 veya -1 (yok)
  ///
  /// Dönüş değeri:
  /// - [bool]: Gönderime uygun mu
  /// {@endtemplate}
  static bool acceptFinal({
    required String text,
    required double confidence,
  }) {
    final t = cleanTranscript(text);
    if (t.length < minFinalChars) return false;
    if (confidence < 0) return true; // platform güven vermiyorsa metni kabul et
    return confidence >= minConfidence;
  }

  /// {@template ai_speech_focus_pick_best}
  /// Alternatifler arasından en güvenilir metni seçer.
  ///
  /// Parametreler:
  /// - [primary]: Ana tanıma
  /// - [primaryConfidence]: Ana güven
  /// - [alternates]: (metin, güven) listesi
  ///
  /// Dönüş değeri:
  /// - [String]: En iyi metin
  /// {@endtemplate}
  static String pickBest({
    required String primary,
    required double primaryConfidence,
    List<({String words, double confidence})> alternates = const [],
  }) {
    var best = primary;
    var bestC = primaryConfidence < 0 ? 0.5 : primaryConfidence;
    for (final a in alternates) {
      final c = a.confidence < 0 ? 0.0 : a.confidence;
      if (c > bestC && a.words.trim().length >= minFinalChars) {
        best = a.words;
        bestC = c;
      }
    }
    return cleanTranscript(best);
  }
}
