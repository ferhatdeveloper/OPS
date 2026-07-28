// Dosya Adı: ai_openai_tts_voice_test.dart
// Açıklama: OpenAI TTS voice eşleme + bulut fallback politika testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/voice/ai_openai_tts_voice.dart';
import 'package:exfin_ops/core/ai/voice/ai_tts_service.dart';
import 'package:exfin_ops/core/ai/voice/ai_tts_voice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockEngine implements AiTtsEngine {
  AiTtsVoicePersona persona = AiTtsVoicePersona.natural;
  final List<String> spoken = <String>[];
  bool speakResult;
  int stopCount = 0;

  _MockEngine({this.speakResult = true});

  @override
  set voicePersona(AiTtsVoicePersona value) => persona = value;

  @override
  Future<void> setLanguageCode(String langCode) async {}

  @override
  Future<bool> speak(String text) async {
    spoken.add(text);
    return speakResult;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  void setOnComplete(VoidCallback? callback) {}

  @override
  void setOnCancel(VoidCallback? callback) {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AiOpenAiTtsVoiceMapper', () {
    test('persona → OpenAI voice id', () {
      expect(
        AiOpenAiTtsVoiceMapper.voiceId(AiTtsVoicePersona.natural),
        'nova',
      );
      expect(
        AiOpenAiTtsVoiceMapper.voiceId(AiTtsVoicePersona.warmF),
        'shimmer',
      );
      expect(
        AiOpenAiTtsVoiceMapper.voiceId(AiTtsVoicePersona.calmM),
        'onyx',
      );
      expect(
        AiOpenAiTtsVoiceMapper.voiceId(AiTtsVoicePersona.device),
        isNull,
      );
    });

    test('default model gpt-4o-mini-tts', () {
      expect(AiOpenAiTtsVoiceMapper.defaultModel, 'gpt-4o-mini-tts');
    });
  });

  group('AiTtsCloudPolicy', () {
    test('key yoksa bulut denemez', () {
      expect(
        AiTtsCloudPolicy.shouldAttemptCloud(
          ttsEnabled: true,
          cloudTtsEnabled: true,
          persona: AiTtsVoicePersona.natural,
          hasOpenAiKey: false,
        ),
        isFalse,
      );
    });

    test('device persona bulut denemez', () {
      expect(
        AiTtsCloudPolicy.shouldAttemptCloud(
          ttsEnabled: true,
          cloudTtsEnabled: true,
          persona: AiTtsVoicePersona.device,
          hasOpenAiKey: true,
        ),
        isFalse,
      );
    });

    test('cloud kapalıysa denemez', () {
      expect(
        AiTtsCloudPolicy.shouldAttemptCloud(
          ttsEnabled: true,
          cloudTtsEnabled: false,
          persona: AiTtsVoicePersona.warmF,
          hasOpenAiKey: true,
        ),
        isFalse,
      );
    });

    test('koşullar uygunsa bulut dener', () {
      expect(
        AiTtsCloudPolicy.shouldAttemptCloud(
          ttsEnabled: true,
          cloudTtsEnabled: true,
          persona: AiTtsVoicePersona.calmM,
          hasOpenAiKey: true,
        ),
        isTrue,
      );
    });
  });

  group('AiTtsService cloud fallback', () {
    test('bulut başarılı → cihaz speak yok', () async {
      final device = _MockEngine();
      final cloud = _MockEngine(speakResult: true);
      final svc = AiTtsService(
        engine: device,
        cloudEngine: cloud,
        hasOpenAiKey: () async => true,
        cloudTtsEnabled: true,
        voicePersona: AiTtsVoicePersona.natural,
      );

      final ok = await svc.speakIfEnabled('Merhaba dünya');
      expect(ok, isTrue);
      expect(svc.lastUsedCloud, isTrue);
      expect(cloud.spoken, isNotEmpty);
      expect(device.spoken, isEmpty);
    });

    test('bulut başarısız → cihaz fallback', () async {
      final device = _MockEngine(speakResult: true);
      final cloud = _MockEngine(speakResult: false);
      final svc = AiTtsService(
        engine: device,
        cloudEngine: cloud,
        hasOpenAiKey: () async => true,
        cloudTtsEnabled: true,
        voicePersona: AiTtsVoicePersona.warmF,
      );

      final ok = await svc.speakIfEnabled('Test cevap');
      expect(ok, isTrue);
      expect(svc.lastUsedCloud, isFalse);
      expect(cloud.spoken, isNotEmpty);
      expect(device.spoken, isNotEmpty);
    });

    test('OpenAI key yok → doğrudan cihaz', () async {
      final device = _MockEngine();
      final cloud = _MockEngine();
      final svc = AiTtsService(
        engine: device,
        cloudEngine: cloud,
        hasOpenAiKey: () async => false,
        cloudTtsEnabled: true,
        voicePersona: AiTtsVoicePersona.natural,
      );

      await svc.speakIfEnabled('Sadece cihaz');
      expect(svc.lastUsedCloud, isFalse);
      expect(cloud.spoken, isEmpty);
      expect(device.spoken, isNotEmpty);
    });

    test('stop her iki motoru keser', () async {
      final device = _MockEngine();
      final cloud = _MockEngine();
      final svc = AiTtsService(
        engine: device,
        cloudEngine: cloud,
        hasOpenAiKey: () async => true,
      );
      await svc.stop();
      expect(device.stopCount, 1);
      expect(cloud.stopCount, 1);
    });
  });
}
