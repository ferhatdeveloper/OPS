// Dosya Adı: visit_audio_segment.dart
// Açıklama: Ziyaret ses segmenti modeli (SQLite visit_audio_segments)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template visit_audio_segment}
/// Tek ses dilimi (dosya yolu + zaman aralığı).
///
/// Kullanım örneği:
/// ```dart
/// VisitAudioSegment(id: '1', visitId: 'v', filePath: '/a.m4a');
/// ```
/// {@endtemplate}
class VisitAudioSegment {
  /// [id]: PK
  final String id;

  /// [visitId]: visits.id
  final String visitId;

  /// [filePath]: Yerel ses dosyası (PII — loglama)
  final String filePath;

  /// [startMs]: Ziyaret başlangıcına göre ms
  final int startMs;

  /// [endMs]: Bitiş ms (0 = açık)
  final int endMs;

  /// [lang]: Algılanan dil kodu (tr/ar/ku/en…)
  final String? lang;

  /// [onay]: 0 draft · 1 onay · 2 sync · 3 reject · 4 error
  final int onay;

  /// [isSynced]
  final int isSynced;

  /// [createdAt]: ISO
  final String createdAt;

  /// [updatedAt]: ISO
  final String updatedAt;

  /// [isDeleted]
  final int isDeleted;

  /// {@macro visit_audio_segment}
  const VisitAudioSegment({
    required this.id,
    required this.visitId,
    required this.filePath,
    this.startMs = 0,
    this.endMs = 0,
    this.lang,
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
        'file_path': filePath,
        'start_ms': startMs,
        'end_ms': endMs,
        'lang': lang,
        'ONAY': onay,
        'is_synced': isSynced,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };

  /// SQLite → model
  factory VisitAudioSegment.fromMap(Map<String, dynamic> map) {
    return VisitAudioSegment(
      id: '${map['id'] ?? ''}',
      visitId: '${map['visit_id'] ?? ''}',
      filePath: '${map['file_path'] ?? ''}',
      startMs: (map['start_ms'] as num?)?.toInt() ?? 0,
      endMs: (map['end_ms'] as num?)?.toInt() ?? 0,
      lang: map['lang']?.toString(),
      onay: (map['ONAY'] as num?)?.toInt() ?? 0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      createdAt: '${map['created_at'] ?? ''}',
      updatedAt: '${map['updated_at'] ?? ''}',
      isDeleted: (map['is_deleted'] as num?)?.toInt() ?? 0,
    );
  }

  /// Kopya
  VisitAudioSegment copyWith({
    String? filePath,
    int? startMs,
    int? endMs,
    String? lang,
    int? onay,
    int? isSynced,
    String? updatedAt,
    int? isDeleted,
  }) {
    return VisitAudioSegment(
      id: id,
      visitId: visitId,
      filePath: filePath ?? this.filePath,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      lang: lang ?? this.lang,
      onay: onay ?? this.onay,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
