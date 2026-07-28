// Dosya Adı: visit_transcript_analyze_service.dart
// Açıklama: Ziyaret transcript AI analiz (özet · duygu · diarize hint)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../ai_completion.dart';
import '../ai_gateway.dart';
import '../../../modules/field_sales/ai_visit_intelligence/model/visit_emotion.dart';
import '../../../modules/field_sales/ai_visit_intelligence/model/visit_transcript.dart';

/// {@template visit_transcript_analyze_result}
/// Analiz sonucu (draft; kullanıcı onayı ayrı).
/// {@endtemplate}
class VisitTranscriptAnalyzeResult {
  /// [status]
  final AiCompletionStatus status;

  /// [summary]
  final String? summary;

  /// [statusSuggestion]
  final String? statusSuggestion;

  /// [lang]
  final String? lang;

  /// [emotion]
  final VisitEmotion emotion;

  /// [segments]: Diarize hint satırları
  final List<VisitTranscript> segments;

  /// [l10nKey]
  final String? l10nKey;

  /// [isDraft]: Silent write işareti
  final bool isDraft;

  /// {@macro visit_transcript_analyze_result}
  const VisitTranscriptAnalyzeResult({
    required this.status,
    this.summary,
    this.statusSuggestion,
    this.lang,
    this.emotion = VisitEmotion.unknown,
    this.segments = const [],
    this.l10nKey,
    this.isDraft = true,
  });

  bool get isOk => status == AiCompletionStatus.ok;
}

/// {@template visit_transcript_analyze_service}
/// AiGateway visitTranscriptAnalyze / emotionDetect / diarizeHint.
/// Ham ses ve PII loglanmaz.
/// {@endtemplate}
class VisitTranscriptAnalyzeService {
  final AiGateway _gateway;

  /// {@macro visit_transcript_analyze_service}
  VisitTranscriptAnalyzeService({AiGateway? gateway})
      : _gateway = gateway ?? AiGateway();

  /// {@template visit_transcript_analyze_service_analyze}
  /// Transcript metni → özet + duygu + durum önerisi (draft).
  /// {@endtemplate}
  Future<VisitTranscriptAnalyzeResult> analyze({
    required String visitId,
    required String transcriptText,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return const VisitTranscriptAnalyzeResult(
        status: AiCompletionStatus.noKey,
        l10nKey: 'ai.no_api_key',
      );
    }

    final completion = await _gateway.visitTranscriptAnalyze(
      transcriptText: transcriptText,
    );
    if (!completion.isOk || (completion.text ?? '').trim().isEmpty) {
      return VisitTranscriptAnalyzeResult(
        status: completion.status,
        l10nKey: completion.l10nKey ?? 'ai.request_failed',
      );
    }

    final map = _parseJsonObject(completion.text!);
    if (map == null) {
      return const VisitTranscriptAnalyzeResult(
        status: AiCompletionStatus.error,
        l10nKey: 'field_sales.visit_voice.err_parse',
      );
    }

    final emotion = VisitEmotionParser.fromJsonMap(map);
    return VisitTranscriptAnalyzeResult(
      status: AiCompletionStatus.ok,
      summary: map['summary']?.toString(),
      statusSuggestion: map['status_suggestion']?.toString() ??
          map['statusSuggestion']?.toString(),
      lang: map['lang']?.toString(),
      emotion: emotion,
      isDraft: map['draft'] != false,
    );
  }

  /// {@template visit_transcript_analyze_service_emotion}
  /// Kısa metin duygu.
  /// {@endtemplate}
  Future<VisitEmotion> detectEmotion(String text) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) return VisitEmotion.unknown;
    final r = await _gateway.emotionDetect(text: text);
    if (!r.isOk || (r.text ?? '').isEmpty) return VisitEmotion.unknown;
    final map = _parseJsonObject(r.text!);
    return VisitEmotionParser.fromJsonMap(map);
  }

  /// {@template visit_transcript_analyze_service_diarize}
  /// Metin segmentleri → Speaker etiketleri (draft satırlar).
  /// {@endtemplate}
  Future<List<VisitTranscript>> diarizeHint({
    required String visitId,
    required String segmentsText,
    String? segmentId,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) return const [];
    final r = await _gateway.diarizeHint(segmentsText: segmentsText);
    if (!r.isOk || (r.text ?? '').isEmpty) return const [];
    final list = _parseJsonList(r.text!);
    if (list == null) return const [];
    final now = DateTime.now().toIso8601String();
    final out = <VisitTranscript>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      out.add(
        VisitTranscript.fromAiSegment(
          id: 'diarize-$visitId-$i',
          visitId: visitId,
          json: map,
          segmentId: segmentId,
          createdAt: now,
        ),
      );
    }
    return out;
  }

  static Map<String, dynamic>? _parseJsonObject(String raw) {
    final t = raw.trim();
    try {
      final decoded = jsonDecode(_stripFence(t));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static List<dynamic>? _parseJsonList(String raw) {
    final t = raw.trim();
    try {
      final decoded = jsonDecode(_stripFence(t));
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['segments'] is List) {
        return decoded['segments'] as List;
      }
    } catch (_) {}
    return null;
  }

  static String _stripFence(String t) {
    var s = t.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
      s = s.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return s.trim();
  }
}
