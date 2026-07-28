// Dosya Adı: ai_speech_language_detector_test.dart
// Açıklama: Konuşma dili algılama + locale eşleme birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/voice/ai_speech_language_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiSpeechLanguageDetector.detect', () {
    test('TR sample', () {
      expect(
        AiSpeechLanguageDetector.detect('Merhaba plasiyer, sipariş nedir?'),
        'tr',
      );
    });

    test('EN sample', () {
      expect(
        AiSpeechLanguageDetector.detect(
          'Hello customer, please check the order',
        ),
        'en',
      );
    });

    test('DE sample', () {
      expect(
        AiSpeechLanguageDetector.detect(
          'Hallo, die Bestellung ist nicht bereit',
        ),
        'de',
      );
    });

    test('RU sample (Cyrillic)', () {
      expect(
        AiSpeechLanguageDetector.detect('Здравствуйте, заказ готов'),
        'ru',
      );
    });

    test('AR sample', () {
      expect(
        AiSpeechLanguageDetector.detect('مرحبا، هذا الطلب من العميل'),
        'ar',
      );
    });

    test('FA sample', () {
      expect(
        AiSpeechLanguageDetector.detect('سلام، این سفارش برای مشتری است'),
        'fa',
      );
    });

    test('KU Sorani sample', () {
      expect(
        AiSpeechLanguageDetector.detect('سڵاو، داواکاری لە بەرەوە بوو'),
        'ku',
      );
    });

    test('empty → fallback', () {
      expect(AiSpeechLanguageDetector.detect('', fallback: 'en'), 'en');
    });
  });

  group('AiSpeechLanguageDetector.resolve preference', () {
    test('fixed EN ignores Turkish text', () {
      expect(
        AiSpeechLanguageDetector.resolve(
          preference: 'en',
          text: 'Merhaba plasiyer',
        ),
        'en',
      );
    });

    test('auto uses detect', () {
      expect(
        AiSpeechLanguageDetector.resolve(
          preference: 'auto',
          text: 'Hello and thank you for the order',
        ),
        'en',
      );
    });

    test('normalizePreference ckb → ku; junk → auto', () {
      expect(AiSpeechLanguageDetector.normalizePreference('ckb'), 'ku');
      expect(AiSpeechLanguageDetector.normalizePreference('xx'), 'auto');
      expect(AiSpeechLanguageDetector.normalizePreference(null), 'auto');
    });
  });

  group('locale mapping', () {
    test('tts + stt table', () {
      expect(AiSpeechLanguageDetector.ttsLocale('tr'), 'tr-TR');
      expect(AiSpeechLanguageDetector.ttsLocale('en'), 'en-US');
      expect(AiSpeechLanguageDetector.ttsLocale('ar'), 'ar-SA');
      expect(AiSpeechLanguageDetector.ttsLocale('fa'), 'fa-IR');
      expect(AiSpeechLanguageDetector.ttsLocale('de'), 'de-DE');
      expect(AiSpeechLanguageDetector.ttsLocale('ru'), 'ru-RU');
      expect(AiSpeechLanguageDetector.sttLocale('tr'), 'tr_TR');
      expect(AiSpeechLanguageDetector.sttLocale('en'), 'en_US');
      expect(AiSpeechLanguageDetector.sttLocale('ku'), 'ku_IQ');
    });

    test('sttLocaleForInput fixed vs auto', () {
      expect(
        AiSpeechLanguageDetector.sttLocaleForInput(
          preference: 'de',
          typedText: 'hello',
          appOrDeviceLang: 'tr',
        ),
        'de_DE',
      );
      expect(
        AiSpeechLanguageDetector.sttLocaleForInput(
          preference: 'auto',
          typedText: 'Hello please',
          appOrDeviceLang: 'tr',
        ),
        'en_US',
      );
      expect(
        AiSpeechLanguageDetector.sttLocaleForInput(
          preference: 'auto',
          typedText: '',
          appOrDeviceLang: 'ru',
        ),
        'ru_RU',
      );
    });

    test('labelFor', () {
      expect(AiSpeechLanguageDetector.labelFor('auto'), 'Auto');
      expect(AiSpeechLanguageDetector.labelFor('tr'), 'TR');
    });
  });
}
