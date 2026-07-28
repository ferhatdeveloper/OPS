// Dosya Adı: visit_transcript.dart
// Açıklama: Ziyaret transcript satırı (speaker · dil · duygu)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'visit_emotion.dart';

/// {@template visit_transcript}
/// Konuşma yazıya döküm satırı (`visit_transcripts`).
///
/// Kullanım örneği:
/// ```dart
/// VisitTranscript(
///   id: 't1',
///   visitId: 'v1',
///   speakerLabel: 'Speaker 1',
///   text: 'Merhaba',
///   startMs: 0,
///   endMs: 1200,
/// );
/// ```
/// {@endtemplate}
class VisitTranscript {
  /// [id]: PK
  final String id;

  /// [visitId]: visits.id
  final String visitId;

  /// [segmentId]: visit_audio_segments.id (opsiyonel)
  final String? segmentId;

  /// [speakerLabel]: Speaker 1 / 2 / plasiyer / müşteri
  final String speakerLabel;

  /// [startMs]
  final int startMs;

  /// [endMs]
  final int endMs;

  /// [text]: Transcript (PII — loglama)
  final String text;

  /// [lang]: tr/ar/ku/en…
  final String? lang;

  /// [emotion]: Duygu
  final VisitEmotion emotion;

  /// [queueStatus]: pending | done | error | draft
  final String queueStatus;

  /// [onay]: 0 draft silent · 1 kullanıcı onay
  final int onay;

  /// [isSynced]
  final int isSynced;

  /// [createdAt]
  final String createdAt;

  /// [updatedAt]
  final String updatedAt;

  /// [isDeleted]
  final int isDeleted;

  /// {@macro visit_transcript}
  const VisitTranscript({
    required this.id,
    required this.visitId,
    this.segmentId,
    this.speakerLabel = 'Speaker 1',
    this.startMs = 0,
    this.endMs = 0,
    required this.text,
    this.lang,
    this.emotion = VisitEmotion.unknown,
    this.queueStatus = 'draft',
    this.onay = 0,
    this.isSynced = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
  });

  /// SQLite map
  Map<String, Object?> toMap() => {
        'id': id,
        'visit_id': visitId,
        'segment_id': segmentId,
        'speaker_label': speakerLabel,
        'start_ms': startMs,
        'end_ms': endMs,
        'text': text,
        'lang': lang,
        'emotion': emotion.storageKey,
        'queue_status': queueStatus,
        'ONAY': onay,
        'is_synced': isSynced,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };

  /// SQLite → model
  factory VisitTranscript.fromMap(Map<String, dynamic> map) {
    return VisitTranscript(
      id: '${map['id'] ?? ''}',
      visitId: '${map['visit_id'] ?? ''}',
      segmentId: map['segment_id']?.toString(),
      speakerLabel: (map['speaker_label']?.toString() ?? 'Speaker 1').trim(),
      startMs: (map['start_ms'] as num?)?.toInt() ?? 0,
      endMs: (map['end_ms'] as num?)?.toInt() ?? 0,
      text: '${map['text'] ?? ''}',
      lang: map['lang']?.toString(),
      emotion: VisitEmotionParser.parse(map['emotion']?.toString()),
      queueStatus: (map['queue_status']?.toString() ?? 'draft').trim(),
      onay: (map['ONAY'] as num?)?.toInt() ?? 0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      createdAt: '${map['created_at'] ?? ''}',
      updatedAt: '${map['updated_at'] ?? ''}',
      isDeleted: (map['is_deleted'] as num?)?.toInt() ?? 0,
    );
  }

  /// AI diarize JSON satırı
  factory VisitTranscript.fromAiSegment({
    required String id,
    required String visitId,
    required Map<String, dynamic> json,
    String? segmentId,
    required String createdAt,
  }) {
    final speaker = (json['speaker'] ?? json['speaker_label'] ?? 'Speaker 1')
        .toString()
        .trim();
    final text = (json['text'] ?? json['content'] ?? '').toString().trim();
    final start = (json['start_ms'] as num?)?.toInt() ??
        ((json['start'] as num?)?.toInt() ?? 0);
    final end = (json['end_ms'] as num?)?.toInt() ??
        ((json['end'] as num?)?.toInt() ?? 0);
    return VisitTranscript(
      id: id,
      visitId: visitId,
      segmentId: segmentId,
      speakerLabel: speaker.isEmpty ? 'Speaker 1' : speaker,
      startMs: start,
      endMs: end,
      text: text,
      lang: json['lang']?.toString() ?? json['language']?.toString(),
      emotion: VisitEmotionParser.fromJsonMap(json),
      queueStatus: 'draft',
      onay: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  /// Kopya
  VisitTranscript copyWith({
    String? speakerLabel,
    String? text,
    String? lang,
    VisitEmotion? emotion,
    String? queueStatus,
    int? onay,
    int? isSynced,
    String? updatedAt,
  }) {
    return VisitTranscript(
      id: id,
      visitId: visitId,
      segmentId: segmentId,
      speakerLabel: speakerLabel ?? this.speakerLabel,
      startMs: startMs,
      endMs: endMs,
      text: text ?? this.text,
      lang: lang ?? this.lang,
      emotion: emotion ?? this.emotion,
      queueStatus: queueStatus ?? this.queueStatus,
      onay: onay ?? this.onay,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted,
    );
  }
}
