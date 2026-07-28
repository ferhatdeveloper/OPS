// Dosya Adı: ai_tts_voice.dart
// Açıklama: Insansı TTS konuşmacı tercihi + cihaz sesi sıralama
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_tts_voice_persona}
/// Sesli asistan konuşmacı stili.
///
/// Cihaz TTS motorundaki neural/network sesleri tercih eder.
///
/// Kullanım örneği:
/// ```dart
/// final p = AiTtsVoicePersona.parse('warm_f');
/// ```
/// {@endtemplate}
enum AiTtsVoicePersona {
  /// En iyi neural (tercihen sıcak kadın sesi)
  natural,

  /// Sıcak / kadın neural
  warmF,

  /// Sakin / erkek neural
  calmM,

  /// Sistem varsayılanı (eski robotik dil seçimi)
  device,
}

/// {@template ai_tts_voice_persona_x}
/// [AiTtsVoicePersona] yardımcıları.
/// {@endtemplate}
extension AiTtsVoicePersonaX on AiTtsVoicePersona {
  /// Depolama anahtarı
  String get storageKey {
    switch (this) {
      case AiTtsVoicePersona.natural:
        return 'natural';
      case AiTtsVoicePersona.warmF:
        return 'warm_f';
      case AiTtsVoicePersona.calmM:
        return 'calm_m';
      case AiTtsVoicePersona.device:
        return 'device';
    }
  }

  /// l10n anahtarı
  String get labelKey {
    switch (this) {
      case AiTtsVoicePersona.natural:
        return 'ai.tts_voice_natural';
      case AiTtsVoicePersona.warmF:
        return 'ai.tts_voice_warm_f';
      case AiTtsVoicePersona.calmM:
        return 'ai.tts_voice_calm_m';
      case AiTtsVoicePersona.device:
        return 'ai.tts_voice_device';
    }
  }

  /// Cinsiyet tercihi (null = en iyi genel)
  AiTtsVoiceGender? get preferredGender {
    switch (this) {
      case AiTtsVoicePersona.natural:
        return AiTtsVoiceGender.female;
      case AiTtsVoicePersona.warmF:
        return AiTtsVoiceGender.female;
      case AiTtsVoicePersona.calmM:
        return AiTtsVoiceGender.male;
      case AiTtsVoicePersona.device:
        return null;
    }
  }

  /// String → persona (bilinmeyen → natural)
  static AiTtsVoicePersona parse(String? raw) {
    final k = (raw ?? '').trim().toLowerCase();
    for (final p in AiTtsVoicePersona.values) {
      if (p.storageKey == k) return p;
    }
    return AiTtsVoicePersona.natural;
  }
}

/// {@template ai_tts_voice_gender}
/// Algılanan konuşmacı cinsiyeti (isim heuristiği).
/// {@endtemplate}
enum AiTtsVoiceGender { female, male, unknown }

/// {@template ai_tts_voice_info}
/// flutter_tts `getVoices` satırı.
/// {@endtemplate}
class AiTtsVoiceInfo {
  /// [name]: Motor ses adı
  final String name;

  /// [locale]: BCP-47 / languageTag
  final String locale;

  /// [quality]: iOS quality (enhanced/default/…) — Android boş
  final String quality;

  /// [gender]: iOS gender — Android boş
  final String genderRaw;

  /// {@macro ai_tts_voice_info}
  const AiTtsVoiceInfo({
    required this.name,
    required this.locale,
    this.quality = '',
    this.genderRaw = '',
  });

  /// Map → model
  factory AiTtsVoiceInfo.fromMap(Map<dynamic, dynamic> map) {
    return AiTtsVoiceInfo(
      name: (map['name'] ?? '').toString(),
      locale: (map['locale'] ?? '').toString(),
      quality: (map['quality'] ?? '').toString(),
      genderRaw: (map['gender'] ?? '').toString(),
    );
  }

  /// setVoice için map
  Map<String, String> toSetVoiceMap() => {
        'name': name,
        'locale': locale,
      };

  /// Kısa dil kodu (tr, en, …)
  String get langPrefix {
    final l = locale.toLowerCase().replaceAll('_', '-');
    if (l.length >= 2) return l.substring(0, 2);
    return l;
  }
}

/// {@template ai_tts_voice_selector}
/// Cihaz seslerini neural/insansı öncelikle sıralar.
///
/// Kullanım örneği:
/// ```dart
/// final best = AiTtsVoiceSelector.pickBest(
///   voices: list,
///   langCode: 'tr',
///   persona: AiTtsVoicePersona.warmF,
/// );
/// ```
/// {@endtemplate}
class AiTtsVoiceSelector {
  /// {@macro ai_tts_voice_selector}
  const AiTtsVoiceSelector._();

  /// Ham liste → modeller
  static List<AiTtsVoiceInfo> parseVoices(dynamic raw) {
    if (raw is! List) return const [];
    final out = <AiTtsVoiceInfo>[];
    for (final item in raw) {
      if (item is Map) {
        final v = AiTtsVoiceInfo.fromMap(item);
        if (v.name.isNotEmpty && v.locale.isNotEmpty) {
          out.add(v);
        }
      }
    }
    return out;
  }

  /// {@template ai_tts_voice_selector_gender}
  /// İsim / gender alanından cinsiyet.
  /// {@endtemplate}
  static AiTtsVoiceGender detectGender(AiTtsVoiceInfo v) {
    final g = v.genderRaw.toLowerCase();
    if (g.contains('female') || g == 'f') {
      return AiTtsVoiceGender.female;
    }
    if (g.contains('male') || g == 'm') {
      return AiTtsVoiceGender.male;
    }
    final n = v.name.toLowerCase();
    // Google TR: tr-tr-x-trf-… / tr-tr-x-trm-…
    if (RegExp(r'(^|[^a-z])(female|woman|girl|trf|zf|xf)([^a-z]|$)')
            .hasMatch(n) ||
        n.contains('-f-') ||
        n.endsWith('-f') ||
        n.contains('#female')) {
      return AiTtsVoiceGender.female;
    }
    if (RegExp(r'(^|[^a-z])(male|man|boy|trm|zm|xm)([^a-z]|$)')
            .hasMatch(n) ||
        n.contains('-m-') ||
        n.endsWith('-m') ||
        n.contains('#male')) {
      return AiTtsVoiceGender.male;
    }
    return AiTtsVoiceGender.unknown;
  }

  /// {@template ai_tts_voice_selector_score}
  /// Yüksek = daha insansı / neural.
  /// {@endtemplate}
  static int score(AiTtsVoiceInfo v, {AiTtsVoiceGender? preferGender}) {
    final n = v.name.toLowerCase();
    final q = v.quality.toLowerCase();
    var s = 0;

    // Neural / cloud kalite işaretleri
    if (n.contains('network')) s += 120;
    if (n.contains('neural')) s += 110;
    if (n.contains('wavenet')) s += 110;
    if (n.contains('natural')) s += 90;
    if (n.contains('enhanced') || q.contains('enhanced')) s += 80;
    if (n.contains('premium') || q.contains('premium')) s += 85;
    if (n.contains('quality')) s += 40;
    if (n.contains('google')) s += 25;

    // Yerel ama yine de modern (x-trf-local)
    if (n.contains('local') && !n.contains('network')) s += 35;
    if (n.contains('-x-')) s += 30;

    // Klasik robotik motor isimleri
    if (n.contains('language') || n.endsWith('-language')) s -= 60;
    if (n.contains('compact') || n.contains('robot')) s -= 40;

    final gender = detectGender(v);
    if (preferGender != null) {
      if (gender == preferGender) {
        s += 90;
      } else if (gender != AiTtsVoiceGender.unknown) {
        s -= 80;
      }
    }

    return s;
  }

  /// {@template ai_tts_voice_selector_pick}
  /// Dil + persona için en iyi ses; yoksa null.
  ///
  /// Parametreler:
  /// - [voices]: getVoices listesi
  /// - [langCode]: tr/en/…
  /// - [persona]: konuşmacı
  ///
  /// Dönüş değeri:
  /// - [AiTtsVoiceInfo?]: Seçilen ses
  /// {@endtemplate}
  static AiTtsVoiceInfo? pickBest({
    required List<AiTtsVoiceInfo> voices,
    required String langCode,
    required AiTtsVoicePersona persona,
  }) {
    if (persona == AiTtsVoicePersona.device) return null;
    final lang = langCode.toLowerCase().trim();
    if (lang.isEmpty) return null;

    final matched = voices
        .where((v) => v.langPrefix == lang ||
            v.locale.toLowerCase().startsWith(lang))
        .toList();
    if (matched.isEmpty) return null;

    final prefer = persona.preferredGender;
    matched.sort((a, b) {
      final sb = score(b, preferGender: prefer);
      final sa = score(a, preferGender: prefer);
      if (sb != sa) return sb.compareTo(sa);
      return a.name.compareTo(b.name);
    });
    return matched.first;
  }
}
