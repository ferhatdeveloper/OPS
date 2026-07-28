// Dosya Adı: ai_chat_reply_sanitizer.dart
// Açıklama: Chat yanıtı — klon/internal ID gizle + TTS için durum odaklı metin
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_chat_reply_sanitizer}
/// Asistan yanıtını kullanıcıya ve sese hazırlar.
///
/// - Ekran: `ord_2` / `cust_2` gibi klon ID satırlarını çıkarır
/// - Ses: ID okumaz; durum / tutar / tarih / müşteri adı anlatır
///
/// Kullanım örneği:
/// ```dart
/// final shown = AiChatReplySanitizer.forDisplay(raw);
/// final spoken = AiChatReplySanitizer.forSpeech(raw);
/// ```
/// {@endtemplate}
class AiChatReplySanitizer {
  /// {@macro ai_chat_reply_sanitizer}
  const AiChatReplySanitizer._();

  /// Seed / demo / dahili ID kalıbı
  static final RegExp cloneIdToken = RegExp(
    r'\b(?:ord|cust|prod|vis|col|usr|demo)_[a-z0-9]+\b',
    caseSensitive: false,
  );

  /// UUID benzeri
  static final RegExp uuidLike = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );

  /// ID etiket satırı (Sipariş ID / Müşteri ID / …)
  static final RegExp idLabelLine = RegExp(
    r'^\s*[-•*]?\s*\*{0,2}\s*'
    r'(?:sipari[sş]\s*id|m[uü][sş]teri\s*id|order\s*id|customer\s*id|'
    r'ürün\s*id|urun\s*id|product\s*id|ziyaret\s*id|visit\s*id|'
    r'i[cç]\s*id|internal\s*id|kayıt\s*id|kayit\s*id)\s*'
    r'\*{0,2}\s*[:：].*$',
    caseSensitive: false,
  );

  /// Prompt kolonunun kullanıcıya gösterilmemesi gereken mi?
  static bool isInternalKey(String key) {
    final k = key.toLowerCase().trim();
    if (k == 'id' || k.endsWith('_id')) return true;
    if (k == 'uuid' || k == 'guid') return true;
    return false;
  }

  /// Değer klon/seed ID mi?
  static bool isInternalValue(dynamic value) {
    final v = (value ?? '').toString().trim();
    if (v.isEmpty) return false;
    if (cloneIdToken.hasMatch(v)) return true;
    if (uuidLike.hasMatch(v) && v.length >= 32) return true;
    return false;
  }

  /// {@template ai_chat_reply_sanitizer_for_display}
  /// Ekranda gösterilecek metin — klon ID satırları yok.
  /// {@endtemplate}
  static String forDisplay(String text) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final kept = <String>[];
    for (final line in lines) {
      if (idLabelLine.hasMatch(line)) continue;
      var t = line;
      t = t.replaceAll(cloneIdToken, '');
      t = t.replaceAll(uuidLike, '');
      t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trimRight();
      // Boş madde satırı at
      if (RegExp(r'^\s*[-•*]\s*$').hasMatch(t)) continue;
      if (t.trim().isEmpty && kept.isNotEmpty && kept.last.trim().isEmpty) {
        continue;
      }
      kept.add(t);
    }
    return kept.join('\n').trim();
  }

  /// {@template ai_chat_reply_sanitizer_for_speech}
  /// TTS: ID okuma; durum / tutar / tarih anlat.
  /// {@endtemplate}
  static String forSpeech(String text) {
    var t = forDisplay(text);
    if (t.isEmpty) return t;

    // Markdown / madde işaretleri
    t = t.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    t = t.replaceAll(RegExp(r'`[^`]+`'), ' ');
    t = t.replaceAll(RegExp(r'[*_#~>]+'), ' ');
    t = t.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    t = t.replaceAll(RegExp(r'^\s*[-•*]\s*', multiLine: true), '');

    // "Durum: Beklemede" → "Durum Beklemede"
    t = t.replaceAllMapped(
      RegExp(r'([A-Za-zÇĞİÖŞÜçğıöşü\s]+)\s*:\s*', unicode: true),
      (m) => '${m.group(1)!.trim()} ',
    );

    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 1200) {
      t = '${t.substring(0, 1200)}…';
    }
    return t;
  }

  /// Prompt satırı için kolon temizliği
  static Map<String, dynamic> slimRowForPrompt(Map<String, dynamic> row) {
    final slim = <String, dynamic>{};
    for (final e in row.entries) {
      if (isInternalKey(e.key)) continue;
      if (isInternalValue(e.value)) continue;
      slim[e.key] = e.value;
    }
    return slim;
  }
}
