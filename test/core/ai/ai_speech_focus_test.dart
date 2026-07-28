// Dosya Adı: ai_speech_focus_test.dart
// Açıklama: STT odak temizleyici / güven eşiği testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/voice/ai_speech_focus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiSpeechFocus.cleanTranscript', () {
    test('boşluk ve tekrar temizler', () {
      expect(
        AiSpeechFocus.cleanTranscript('  selam   selam  dünya '),
        'selam dünya',
      );
    });

    test('baştaki dolgu kelimesini atar', () {
      expect(AiSpeechFocus.cleanTranscript('eee bugün sipariş'), 'bugün sipariş');
    });
  });

  group('AiSpeechFocus.acceptFinal', () {
    test('kısa metni reddeder', () {
      expect(
        AiSpeechFocus.acceptFinal(text: 'a', confidence: 0.9),
        isFalse,
      );
    });

    test('düşük güveni reddeder', () {
      expect(
        AiSpeechFocus.acceptFinal(text: 'merhaba', confidence: 0.2),
        isFalse,
      );
    });

    test('güven yoksa metni kabul eder', () {
      expect(
        AiSpeechFocus.acceptFinal(text: 'merhaba', confidence: -1),
        isTrue,
      );
    });
  });

  group('AiSpeechFocus.isVoiceLevelUseful', () {
    test('çok düşük seviye gürültü', () {
      expect(AiSpeechFocus.isVoiceLevelUseful(-40), isFalse);
      expect(AiSpeechFocus.isVoiceLevelUseful(0), isTrue);
    });
  });
}
