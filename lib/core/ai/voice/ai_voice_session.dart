// Dosya Adı: ai_voice_session.dart
// Açıklama: Sesli sohbet state machine — mic interrupt / TTS / STT akışı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'ai_voice_phase.dart';

/// {@template ai_voice_mic_action}
/// Mikrofon / pill basışında UI’nın yapması gereken yan etki.
/// {@endtemplate}
enum AiVoiceMicAction {
  /// [ignored]: İşlenmiyor (ör. AI yanıt beklenirken)
  ignored,

  /// [startListening]: STT başlat (önce TTS kesilmiş olabilir)
  startListening,

  /// [stopListening]: STT durdur; transcript varsa gönder
  stopListening,
}

/// {@template ai_voice_mic_result}
/// [AiVoiceSession.pressMic] sonucu.
/// {@endtemplate}
class AiVoiceMicResult {
  /// [action]: STT başlat / durdur / yok say
  final AiVoiceMicAction action;

  /// [stopTts]: Gemini interrupt — TTS kesilsin
  final bool stopTts;

  /// {@macro ai_voice_mic_result}
  const AiVoiceMicResult({
    required this.action,
    this.stopTts = false,
  });

  /// Yok say
  static const AiVoiceMicResult ignored = AiVoiceMicResult(
    action: AiVoiceMicAction.ignored,
  );
}

/// {@template ai_voice_session}
/// Saf (platform bağımsız) ses oturumu state machine.
/// STT/TTS motorları UI katmanında; burada yalnızca faz geçişleri.
///
/// Kullanım örneği:
/// ```dart
/// final s = AiVoiceSession();
/// final r = s.pressMic(); // startListening
/// s.beginProcessing();
/// final speak = s.onReplyOk('Merhaba');
/// ```
/// {@endtemplate}
class AiVoiceSession {
  /// [phase]: Güncel faz
  AiVoicePhase phase;

  /// [ttsEnabled]: AI cevabını sesli oku (varsayılan açık)
  bool ttsEnabled;

  /// {@macro ai_voice_session}
  AiVoiceSession({
    this.phase = AiVoicePhase.idle,
    this.ttsEnabled = true,
  });

  /// Dinliyor mu
  bool get isListening => phase == AiVoicePhase.listening;

  /// TTS konuşuyor mu
  bool get isSpeaking => phase == AiVoicePhase.speaking;

  /// AI yanıt bekleniyor mu
  bool get isProcessing => phase == AiVoicePhase.processing;

  /// Pill / mic animasyonu (listening)
  bool get showListeningUi => isListening;

  /// “AI konuşuyor” UI
  bool get showSpeakingUi => isSpeaking;

  /// {@template ai_voice_session_press_mic}
  /// Mic veya pill basıldı (tap-to-talk / hold başlangıcı).
  /// Konuşurken basılırsa TTS kesilir ve dinleme başlar (interrupt).
  ///
  /// Dönüş değeri:
  /// - [AiVoiceMicResult]: Yan etkiler
  /// {@endtemplate}
  AiVoiceMicResult pressMic() {
    if (phase == AiVoicePhase.processing) {
      return AiVoiceMicResult.ignored;
    }
    if (phase == AiVoicePhase.listening) {
      return const AiVoiceMicResult(action: AiVoiceMicAction.stopListening);
    }
    final wasSpeaking = phase == AiVoicePhase.speaking;
    phase = AiVoicePhase.listening;
    return AiVoiceMicResult(
      action: AiVoiceMicAction.startListening,
      stopTts: wasSpeaking,
    );
  }

  /// Hold bırakıldı / tap ile dinleme bitti → processing’e geçmeden önce
  /// transcript boşsa [cancelListening], doluysa [beginProcessing].
  void cancelListening() {
    if (phase == AiVoicePhase.listening) {
      phase = AiVoicePhase.idle;
    }
  }

  /// Mesaj AI’ya gönderiliyor
  void beginProcessing() {
    phase = AiVoicePhase.processing;
  }

  /// {@template ai_voice_session_on_reply_ok}
  /// AI cevabı geldi. TTS açıksa speaking’e geçer.
  ///
  /// Dönüş değeri:
  /// - [bool]: true → UI TTS konuştursun
  /// {@endtemplate}
  bool onReplyOk(String text) {
    final trimmed = text.trim();
    if (ttsEnabled && trimmed.isNotEmpty) {
      phase = AiVoicePhase.speaking;
      return true;
    }
    phase = AiVoicePhase.idle;
    return false;
  }

  /// AI hata / no-key
  void onReplyFail() {
    phase = AiVoicePhase.idle;
  }

  /// TTS tamamlandı
  void onSpeakCompleted() {
    if (phase == AiVoicePhase.speaking) {
      phase = AiVoicePhase.idle;
    }
  }

  /// TTS kullanıcı interrupt veya stop ile kesildi
  void onSpeakInterrupted() {
    if (phase == AiVoicePhase.speaking) {
      phase = AiVoicePhase.idle;
    }
  }

  /// Manuel yeniden oku (assistant bubble volume)
  void beginSpeaking() {
    phase = AiVoicePhase.speaking;
  }

  /// Yeni sohbet / dispose
  void reset() {
    phase = AiVoicePhase.idle;
  }
}
