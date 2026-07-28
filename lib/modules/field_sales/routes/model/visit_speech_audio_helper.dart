// Dosya Adı: visit_speech_audio_helper.dart
// Açıklama: Ziyaret STT oturumu için ses dosyası yolu (metadata / stub)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28
//
// Not: `record` paketi ile dosya kaydı `VisitVoiceRecordingStore` içinde.
// Bu helper yol üretir; klasörü oluşturur.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// {@template visit_speech_audio_helper}
/// STT sırasında kaydedilecek ses dosyası yolu üretir.
///
/// Kullanım örneği:
/// ```dart
/// final path = await VisitSpeechAudioHelper.plannedRecordingPath(
///   visitId: 'visit-1',
/// );
/// ```
/// {@endtemplate}
class VisitSpeechAudioHelper {
  /// {@macro visit_speech_audio_helper}
  const VisitSpeechAudioHelper._();

  /// {@template visit_speech_audio_build_relative}
  /// Göreli dosya adı (test / saf mantık).
  ///
  /// Parametreler:
  /// - [visitId]: Ziyaret kimliği
  /// - [epochMs]: Zaman damgası (ms)
  ///
  /// Dönüş değeri:
  /// - [String]: visits/{id}/speech_{ms}.m4a
  /// {@endtemplate}
  static String buildRelativeFileName(String visitId, int epochMs) {
    final safeId = visitId.trim().isEmpty ? 'unknown' : visitId.trim();
    return 'visits/$safeId/speech_$epochMs.m4a';
  }

  /// {@template visit_speech_audio_planned_path}
  /// Uygulama belgeleri altında planlanan tam dosya yolu.
  ///
  /// Parametreler:
  /// - [visitId]: Açık ziyaret id
  /// - [nowMs]: Opsiyonel sabit zaman (test)
  /// - [documentsRoot]: Test enjeksiyonu
  ///
  /// Dönüş değeri:
  /// - [String?]: Tam yol veya null (platform hatası)
  /// {@endtemplate}
  static Future<String?> plannedRecordingPath({
    required String visitId,
    int? nowMs,
    Future<Directory> Function()? documentsRoot,
  }) async {
    try {
      final root = documentsRoot != null
          ? await documentsRoot()
          : await getApplicationDocumentsDirectory();
      final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
      final relative = buildRelativeFileName(visitId, ts);
      final file = File('${root.path}/$relative');
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
