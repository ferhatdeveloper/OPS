// Dosya Adı: ai_prompt_sanitizer_test.dart
// Açıklama: AI prompt PII maskeleme + secret redact unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/ai_prompt_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiPromptSanitizer', () {
    test('telefon maskelenir', () {
      final s = AiPromptSanitizer.sanitize('Ara 0532 111 22 33 hemen');
      expect(s.contains('0532'), isFalse);
      expect(s.contains('[PHONE]'), isTrue);
    });

    test('kişi adı benzeri maskelenir', () {
      final s = AiPromptSanitizer.sanitize('Müşteri: Ahmet Yılmaz kod C1');
      expect(s.contains('Ahmet Yılmaz'), isFalse);
      expect(s.contains('[NAME]'), isTrue);
      expect(s.contains('C1'), isTrue);
    });

    test('API key log satırından çıkarılır', () {
      final s = AiPromptSanitizer.redactSecrets(
        'Authorization: Bearer sk-abc123456789xyz',
      );
      expect(s.contains('sk-abc'), isFalse);
      expect(s.contains('[REDACTED'), isTrue);
    });
  });
}
