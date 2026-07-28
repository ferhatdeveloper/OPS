// Dosya Adı: visit_emotion_parser_test.dart
// Açıklama: VisitEmotionParser birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_visit_intelligence/model/visit_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisitEmotionParser', () {
    test('parses TR/EN happy synonyms', () {
      expect(VisitEmotionParser.parse('mutlu'), VisitEmotion.happy);
      expect(VisitEmotionParser.parse('Happy'), VisitEmotion.happy);
      expect(VisitEmotionParser.parse('memnun'), VisitEmotion.happy);
    });

    test('parses angry and irritable', () {
      expect(VisitEmotionParser.parse('sinirli'), VisitEmotion.angry);
      expect(VisitEmotionParser.parse('asabi'), VisitEmotion.irritable);
      expect(VisitEmotionParser.parse('gergin'), VisitEmotion.irritable);
    });

    test('parses neutral and unknown', () {
      expect(VisitEmotionParser.parse('nötr'), VisitEmotion.neutral);
      expect(VisitEmotionParser.parse(''), VisitEmotion.unknown);
      expect(VisitEmotionParser.parse('xyz'), VisitEmotion.unknown);
    });

    test('fromJsonMap reads emotion field', () {
      expect(
        VisitEmotionParser.fromJsonMap({'emotion': 'angry'}),
        VisitEmotion.angry,
      );
      expect(
        VisitEmotionParser.fromJsonMap({'mood': 'neutral'}),
        VisitEmotion.neutral,
      );
    });
  });
}
