// Dosya Adı: visit_speech_notes.dart
// Açıklama: Ziyaret notuna STT metni ekleme, locale ve ses dosya yolu (saf mantık)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template visit_speech_notes}
/// Ziyaret ses→metin için saf yardımcılar (UI / platform yok).
///
/// Kullanım örneği:
/// ```dart
/// final next = VisitSpeechNotes.appendFinal('Merhaba', 'dünya');
/// // → 'Merhaba dünya'
/// final path = VisitSpeechNotes.buildAudioFilePath(
///   directory: '/tmp/visits',
///   visitId: 'v1',
/// );
/// // → '/tmp/visits/v1_speech.m4a'
/// ```
/// {@endtemplate}
class VisitSpeechNotes {
  /// {@macro visit_speech_notes}
  const VisitSpeechNotes._();

  /// STT oturumu için varsayılan ses dosya uzantısı
  static const String audioExtension = 'm4a';

  /// {@template visit_speech_notes_append_final}
  /// Nihai STT parçasını mevcut not metnine ekler.
  ///
  /// Parametreler:
  /// - [existing]: Mevcut not alanı
  /// - [chunk]: Tanınan nihai metin
  ///
  /// Dönüş değeri:
  /// - [String]: Birleşik not metni
  /// {@endtemplate}
  static String appendFinal(String existing, String chunk) {
    final c = chunk.trim();
    if (c.isEmpty) return existing;
    if (existing.trim().isEmpty) return c;
    // Sadece sondaki boşluk/tab; satır sonu (\n) korunur
    final e = existing.replaceFirst(RegExp(r'[ \t]+$'), '');
    if (e.isEmpty) return c;
    if (e.endsWith('\n')) return '$e$c';
    return '$e $c';
  }

  /// {@template visit_speech_notes_build_audio_file_path}
  /// Ziyaret STT oturumu için yerel ses dosya yolu üretir.
  ///
  /// Parametreler:
  /// - [directory]: Uygulama belge / temp kökü (slash’sız veya slash’lı)
  /// - [visitId]: Açık ziyaret kimliği
  /// - [extension]: Dosya uzantısı (varsayılan m4a)
  ///
  /// Dönüş değeri:
  /// - [String]: `{directory}/{visitId}_speech.{ext}`
  /// {@endtemplate}
  static String buildAudioFilePath({
    required String directory,
    required String visitId,
    String extension = audioExtension,
  }) {
    final dir = directory.trim().replaceAll(RegExp(r'[/\\]+$'), '');
    final id = visitId.trim().isEmpty ? 'unknown' : visitId.trim();
    final ext = extension.trim().isEmpty
        ? audioExtension
        : extension.trim().replaceFirst(RegExp(r'^\.'), '');
    final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (dir.isEmpty) return '${safeId}_speech.$ext';
    return '$dir/${safeId}_speech.$ext';
  }

  /// {@template visit_speech_notes_resolve_locale}
  /// Uygulama dil kodundan cihaz ASR `localeId` seçer.
  ///
  /// Öncelik: tam dil öneki → dil ailesi yedekleri (ku→ar/tr) → null.
  ///
  /// Parametreler:
  /// - [languageCode]: App locale (tr, ar, ku, …)
  /// - [availableLocaleIds]: `SpeechToText.locales()` id listesi
  ///
  /// Dönüş değeri:
  /// - [String?]: Eşleşen localeId veya null (sistem varsayılanı)
  /// {@endtemplate}
  static String? resolveLocaleId(
    String languageCode,
    List<String> availableLocaleIds,
  ) {
    if (availableLocaleIds.isEmpty) return null;
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty) return null;

    final normalized = availableLocaleIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) return null;

    String? pickPrefix(String prefix) {
      final p = prefix.toLowerCase();
      for (final id in normalized) {
        final lower = id.toLowerCase().replaceAll('-', '_');
        if (lower == p || lower.startsWith('${p}_')) return id;
      }
      return null;
    }

    final primary = pickPrefix(code);
    if (primary != null) return primary;

    // Kürtçe cihaz ASR nadir; Arapça sonra Türkçe yedek.
    if (code == 'ku' || code == 'ckb') {
      return pickPrefix('ar') ?? pickPrefix('tr');
    }
    if (code == 'fa') {
      return pickPrefix('fa') ?? pickPrefix('ar');
    }
    return null;
  }
}
