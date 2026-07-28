// Dosya Adı: visit_speech_audio_helper_test.dart
// Açıklama: Ziyaret STT ses yolu yardımcı birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/routes/model/visit_speech_audio_helper.dart';

void main() {
  test('buildRelativeFileName visits/{id}/speech_{ms}.m4a', () {
    expect(
      VisitSpeechAudioHelper.buildRelativeFileName('v1', 123),
      'visits/v1/speech_123.m4a',
    );
  });

  test('plannedRecordingPath creates parent dir under inject root', () async {
    final tmp = await Directory.systemTemp.createTemp('visit_audio_test');
    addTearDown(() async {
      if (await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    });
    final path = await VisitSpeechAudioHelper.plannedRecordingPath(
      visitId: 'visit-abc',
      nowMs: 999,
      documentsRoot: () async => tmp,
    );
    expect(path, '${tmp.path}/visits/visit-abc/speech_999.m4a');
    expect(await Directory('${tmp.path}/visits/visit-abc').exists(), isTrue);
  });
}
