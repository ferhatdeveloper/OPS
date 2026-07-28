// Dosya Adı: visit_emotion.dart
// Açıklama: Ziyaret konuşma duygu / memnuniyet sınıfları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template visit_emotion}
/// AI duygu sınıfları (KVKK: ham ses loglanmaz).
///
/// Kullanım örneği:
/// ```dart
/// VisitEmotionParser.parse('mutlu');
/// ```
/// {@endtemplate}
enum VisitEmotion {
  /// Mutlu / memnun
  happy,

  /// Asabi / gergin
  irritable,

  /// Sinirli / öfkeli
  angry,

  /// Nötr
  neutral,

  /// Bilinmiyor / parse edilemedi
  unknown,
}

/// {@template visit_emotion_x}
/// [VisitEmotion] serileştirme + l10n.
/// {@endtemplate}
extension VisitEmotionX on VisitEmotion {
  /// SQLite / JSON storage
  String get storageKey {
    switch (this) {
      case VisitEmotion.happy:
        return 'happy';
      case VisitEmotion.irritable:
        return 'irritable';
      case VisitEmotion.angry:
        return 'angry';
      case VisitEmotion.neutral:
        return 'neutral';
      case VisitEmotion.unknown:
        return 'unknown';
    }
  }

  /// l10n: `field_sales.visit_voice.emotion_<key>`
  String get labelKey => 'field_sales.visit_voice.emotion_$storageKey';
}

/// {@template visit_emotion_parser}
/// AI / serbest metin → [VisitEmotion] (unit-testable).
/// {@endtemplate}
class VisitEmotionParser {
  /// {@macro visit_emotion_parser}
  const VisitEmotionParser._();

  /// {@template visit_emotion_parser_parse}
  /// Ham etiket → enum (TR/EN eşanlamlılar).
  ///
  /// Parametreler:
  /// - [raw]: AI etiketi
  ///
  /// Dönüş değeri:
  /// - [VisitEmotion]
  /// {@endtemplate}
  static VisitEmotion parse(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t.isEmpty) return VisitEmotion.unknown;

    if (_matches(t, const [
      'happy',
      'mutlu',
      'memnun',
      'positive',
      'pozitif',
      'glad',
      'satisfied',
    ])) {
      return VisitEmotion.happy;
    }
    if (_matches(t, const [
      'angry',
      'sinirli',
      'öfkeli',
      'ofkeli',
      'rage',
      'furious',
    ])) {
      return VisitEmotion.angry;
    }
    if (_matches(t, const [
      'irritable',
      'asabi',
      'gergin',
      'tense',
      'annoyed',
      'irritated',
    ])) {
      return VisitEmotion.irritable;
    }
    if (_matches(t, const [
      'neutral',
      'nötr',
      'notr',
      'calm',
      'sakin',
    ])) {
      return VisitEmotion.neutral;
    }
    for (final e in VisitEmotion.values) {
      if (e.storageKey == t) return e;
    }
    return VisitEmotion.unknown;
  }

  /// JSON map’ten emotion alanı
  static VisitEmotion fromJsonMap(Map<String, dynamic>? json) {
    if (json == null) return VisitEmotion.unknown;
    final v = json['emotion'] ?? json['label'] ?? json['mood'];
    return parse(v?.toString());
  }

  static bool _matches(String t, List<String> keys) {
    for (final k in keys) {
      if (t == k || t.contains(k)) return true;
    }
    return false;
  }
}
