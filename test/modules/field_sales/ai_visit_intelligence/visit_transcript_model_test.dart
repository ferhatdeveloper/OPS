// Dosya Adı: visit_transcript_model_test.dart
// Açıklama: VisitTranscript model / AI segment parse testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_visit_intelligence/model/visit_emotion.dart';
import 'package:exfin_ops/modules/field_sales/ai_visit_intelligence/model/visit_transcript.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisitTranscript', () {
    test('toMap/fromMap roundtrip', () {
      const row = VisitTranscript(
        id: 't1',
        visitId: 'v1',
        speakerLabel: 'Speaker 2',
        startMs: 100,
        endMs: 900,
        text: 'Merhaba',
        lang: 'tr',
        emotion: VisitEmotion.happy,
        queueStatus: 'pending',
        onay: 0,
        createdAt: '2026-07-28T10:00:00.000',
        updatedAt: '2026-07-28T10:00:00.000',
      );
      final again = VisitTranscript.fromMap(row.toMap());
      expect(again.id, 't1');
      expect(again.speakerLabel, 'Speaker 2');
      expect(again.text, 'Merhaba');
      expect(again.emotion, VisitEmotion.happy);
      expect(again.lang, 'tr');
      expect(again.queueStatus, 'pending');
    });

    test('fromAiSegment maps speaker/text/emotion', () {
      final row = VisitTranscript.fromAiSegment(
        id: 'd1',
        visitId: 'v1',
        createdAt: '2026-07-28T11:00:00.000',
        json: {
          'speaker_label': 'Speaker 1',
          'text': 'Sipariş vereceğim',
          'start_ms': 0,
          'end_ms': 1500,
          'lang': 'tr',
          'emotion': 'mutlu',
        },
      );
      expect(row.speakerLabel, 'Speaker 1');
      expect(row.text, 'Sipariş vereceğim');
      expect(row.emotion, VisitEmotion.happy);
      expect(row.onay, 0);
      expect(row.queueStatus, 'draft');
    });
  });
}
