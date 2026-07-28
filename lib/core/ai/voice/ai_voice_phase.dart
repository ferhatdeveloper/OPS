// Dosya Adı: ai_voice_phase.dart
// Açıklama: Gemini-like sesli sohbet oturum fazları (STT / AI / TTS)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_voice_phase}
/// Sesli sohbet durum makinesi fazları.
///
/// Kullanım örneği:
/// ```dart
/// if (phase == AiVoicePhase.speaking) { /* TTS aktif */ }
/// ```
/// {@endtemplate}
enum AiVoicePhase {
  /// [idle]: Dinlemiyor, konuşmuyor, beklemiyor
  idle,

  /// [listening]: STT aktif (mikrofon)
  listening,

  /// [processing]: Kullanıcı mesajı AI’ya gitti, yanıt bekleniyor
  processing,

  /// [speaking]: TTS AI cevabını okuyor
  speaking,
}
