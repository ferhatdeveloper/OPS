// Dosya Adı: ai_voice_session_test.dart
// Açıklama: Sesli sohbet state machine birim testleri (STT/TTS interrupt)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/voice/ai_tts_service.dart';
import 'package:exfin_ops/core/ai/voice/ai_voice_phase.dart';
import 'package:exfin_ops/core/ai/voice/ai_voice_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test TTS motoru
class _FakeTtsEngine implements AiTtsEngine {
  final List<String> spoken = [];
  final List<String> languages = [];
  int stopCount = 0;
  VoidCallback? onComplete;
  VoidCallback? onCancel;

  @override
  void setOnComplete(VoidCallback? callback) => onComplete = callback;

  @override
  void setOnCancel(VoidCallback? callback) => onCancel = callback;

  @override
  Future<void> setLanguageCode(String langCode) async {
    languages.add(langCode);
  }

  @override
  Future<bool> speak(String text) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AiVoiceSession state machine', () {
    test('idle → mic → listening', () {
      final s = AiVoiceSession();
      final r = s.pressMic();
      expect(r.action, AiVoiceMicAction.startListening);
      expect(r.stopTts, isFalse);
      expect(s.phase, AiVoicePhase.listening);
    });

    test('listening → mic → stopListening', () {
      final s = AiVoiceSession(phase: AiVoicePhase.listening);
      final r = s.pressMic();
      expect(r.action, AiVoiceMicAction.stopListening);
      expect(s.phase, AiVoicePhase.listening);
    });

    test('speaking → mic → interrupt TTS + startListening', () {
      final s = AiVoiceSession(phase: AiVoicePhase.speaking);
      final r = s.pressMic();
      expect(r.action, AiVoiceMicAction.startListening);
      expect(r.stopTts, isTrue);
      expect(s.phase, AiVoicePhase.listening);
    });

    test('processing → mic ignored', () {
      final s = AiVoiceSession(phase: AiVoicePhase.processing);
      final r = s.pressMic();
      expect(r.action, AiVoiceMicAction.ignored);
      expect(s.phase, AiVoicePhase.processing);
    });

    test('reply ok + ttsEnabled → speaking', () {
      final s = AiVoiceSession(phase: AiVoicePhase.processing);
      expect(s.onReplyOk('Merhaba plasiyer'), isTrue);
      expect(s.phase, AiVoicePhase.speaking);
    });

    test('reply ok + ttsDisabled → idle', () {
      final s = AiVoiceSession(
        phase: AiVoicePhase.processing,
        ttsEnabled: false,
      );
      expect(s.onReplyOk('Merhaba'), isFalse);
      expect(s.phase, AiVoicePhase.idle);
    });

    test('reply empty → idle even if tts on', () {
      final s = AiVoiceSession(phase: AiVoicePhase.processing);
      expect(s.onReplyOk('  '), isFalse);
      expect(s.phase, AiVoicePhase.idle);
    });

    test('speak completed → idle', () {
      final s = AiVoiceSession(phase: AiVoicePhase.speaking);
      s.onSpeakCompleted();
      expect(s.phase, AiVoicePhase.idle);
    });

    test('full loop: listen → process → speak → interrupt → listen', () {
      final s = AiVoiceSession();
      expect(s.pressMic().action, AiVoiceMicAction.startListening);
      s.beginProcessing();
      expect(s.phase, AiVoicePhase.processing);
      expect(s.onReplyOk('Cevap metni'), isTrue);
      expect(s.isSpeaking, isTrue);
      final interrupt = s.pressMic();
      expect(interrupt.stopTts, isTrue);
      expect(interrupt.action, AiVoiceMicAction.startListening);
      expect(s.isListening, isTrue);
    });

    test('cancelListening empty transcript → idle', () {
      final s = AiVoiceSession(phase: AiVoicePhase.listening);
      s.cancelListening();
      expect(s.phase, AiVoicePhase.idle);
    });
  });

  group('AiTtsService mock', () {
    test('speakIfEnabled false when disabled', () async {
      final engine = _FakeTtsEngine();
      final tts = AiTtsService(engine: engine, enabled: false);
      expect(await tts.speakIfEnabled('Merhaba'), isFalse);
      expect(engine.spoken, isEmpty);
    });

    test('speakIfEnabled true speaks text', () async {
      final engine = _FakeTtsEngine();
      final tts = AiTtsService(engine: engine, enabled: true);
      expect(await tts.speakIfEnabled('Merhaba'), isTrue);
      expect(engine.spoken, ['Merhaba']);
      expect(engine.languages, isNotEmpty);
      expect(tts.lastSpokenLang, 'tr');
    });

    test('speakIfEnabled EN preference sets en locale', () async {
      final engine = _FakeTtsEngine();
      final tts = AiTtsService(
        engine: engine,
        enabled: true,
        speechLanguagePreference: 'en',
      );
      expect(await tts.speakIfEnabled('Merhaba plasiyer'), isTrue);
      expect(engine.languages.last, 'en');
      expect(tts.lastSpokenLang, 'en');
    });

    test('speakIfEnabled auto detects English', () async {
      final engine = _FakeTtsEngine();
      final tts = AiTtsService(
        engine: engine,
        enabled: true,
        speechLanguagePreference: 'auto',
      );
      await tts.speakIfEnabled('Hello customer, please check the order');
      expect(engine.languages.last, 'en');
    });

    test('stop increments engine stop', () async {
      final engine = _FakeTtsEngine();
      final tts = AiTtsService(engine: engine);
      await tts.stop();
      expect(engine.stopCount, 1);
    });
  });
}
