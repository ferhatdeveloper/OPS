// Dosya Adı: ai_tts_voice_test.dart
// Açıklama: Neural TTS ses seçici birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/voice/ai_tts_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTtsVoiceSelector', () {
    final voices = [
      const AiTtsVoiceInfo(
        name: 'tr-TR-language',
        locale: 'tr-TR',
      ),
      const AiTtsVoiceInfo(
        name: 'tr-tr-x-trm-local',
        locale: 'tr-TR',
      ),
      const AiTtsVoiceInfo(
        name: 'tr-tr-x-trf-network',
        locale: 'tr-TR',
      ),
      const AiTtsVoiceInfo(
        name: 'en-us-x-sfg-network',
        locale: 'en-US',
      ),
    ];

    test('network kadın sesi warm_f için seçilir', () {
      final best = AiTtsVoiceSelector.pickBest(
        voices: voices,
        langCode: 'tr',
        persona: AiTtsVoicePersona.warmF,
      );
      expect(best?.name, 'tr-tr-x-trf-network');
    });

    test('erkek persona local erkek sesini tercih eder', () {
      final best = AiTtsVoiceSelector.pickBest(
        voices: voices,
        langCode: 'tr',
        persona: AiTtsVoicePersona.calmM,
      );
      expect(best?.name, 'tr-tr-x-trm-local');
    });

    test('device persona null döner', () {
      final best = AiTtsVoiceSelector.pickBest(
        voices: voices,
        langCode: 'tr',
        persona: AiTtsVoicePersona.device,
      );
      expect(best, isNull);
    });

    test('network skoru language üstünde', () {
      final net = AiTtsVoiceSelector.score(
        const AiTtsVoiceInfo(
          name: 'tr-tr-x-trf-network',
          locale: 'tr-TR',
        ),
      );
      final lang = AiTtsVoiceSelector.score(
        const AiTtsVoiceInfo(
          name: 'tr-TR-language',
          locale: 'tr-TR',
        ),
      );
      expect(net, greaterThan(lang));
    });
  });

  test('persona parse bilinmeyeni natural yapar', () {
    expect(
      AiTtsVoicePersonaX.parse('xyz'),
      AiTtsVoicePersona.natural,
    );
    expect(
      AiTtsVoicePersonaX.parse('calm_m').storageKey,
      'calm_m',
    );
  });
}
