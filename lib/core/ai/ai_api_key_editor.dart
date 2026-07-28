// Dosya Adı: ai_api_key_editor.dart
// Açıklama: AI API key alan mantığı — maske / dirty / persist kararı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_api_key_editor}
/// TextField’da düz key tutulmaz; kayıtlı key varsa maske gösterilir.
/// Kaydet: yalnızca kullanıcı düzenlediyse ve maske değilse persist.
///
/// Kullanım örneği:
/// ```dart
/// AiApiKeyEditor.shouldPersist(dirty: true, text: 'sk-or-v1-test');
/// ```
/// {@endtemplate}
class AiApiKeyEditor {
  AiApiKeyEditor._();

  /// Kayıtlı key için alan maskesi (düz key değil)
  static const String maskToken = '••••••••••••••••';

  /// {@template ai_api_key_editor_should_persist}
  /// Persist edilmeli mi?
  ///
  /// Parametreler:
  /// - [text]: Controller metni (maske veya düz key)
  ///
  /// Dönüş değeri:
  /// - [bool]: true → saveApiKey çağır (maske/boş asla yazılmaz)
  /// {@endtemplate}
  static bool shouldPersist({required String text}) {
    final plain = text.trim();
    if (plain.isEmpty) return false;
    if (plain == maskToken) return false;
    return true;
  }

  /// {@template ai_api_key_editor_display_text}
  /// Hydrate / sync sonrası gösterilecek metin.
  ///
  /// Parametreler:
  /// - [hasApiKey]: Store’da key var mı
  ///
  /// Dönüş değeri:
  /// - [String]: maske veya boş
  /// {@endtemplate}
  static String displayText({required bool hasApiKey}) {
    return hasApiKey ? maskToken : '';
  }
}
