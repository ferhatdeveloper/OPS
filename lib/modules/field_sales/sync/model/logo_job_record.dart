// Dosya Adı: logo_job_record.dart
// Açıklama: Logo iş kuyruğu dens satırı — sync_queue / job_queue eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template logo_job_record}
/// Logo REST job_queue dens satırı (`sync_queue` tablosu).
///
/// Kullanım örneği:
/// ```dart
/// final row = LogoJobRecord.fromMap(map);
/// print(row.titleLine); // order · O-1
/// ```
/// {@endtemplate}
class LogoJobRecord {
  /// [id]: sync_queue.id
  final String id;

  /// [entityType]: Belge tipi (order, invoice, …)
  final String entityType;

  /// [entityId]: Yerel belge kimliği
  final String entityId;

  /// [payload]: JSON payload (opsiyonel)
  final String? payload;

  /// [priority]: Kuyruk önceliği
  final int priority;

  /// [retryCount]: Yeniden deneme sayısı
  final int retryCount;

  /// [lastError]: Son hata metni
  final String? lastError;

  /// [scheduledAt]: Planlanan yeniden deneme
  final String? scheduledAt;

  /// [createdAt]: Oluşturulma zamanı
  final String? createdAt;

  /// {@macro logo_job_record}
  const LogoJobRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.payload,
    this.priority = 0,
    this.retryCount = 0,
    this.lastError,
    this.scheduledAt,
    this.createdAt,
  });

  /// {@template logo_job_record_title_line}
  /// Dens liste başlığı (`entity_type · entity_id`).
  /// {@endtemplate}
  String get titleLine => '$entityType · $entityId';

  /// {@template logo_job_record_from_map}
  /// sync_queue satırından dens kayıt üretir.
  ///
  /// Parametreler:
  /// - [map]: SQLite sync_queue satırı
  ///
  /// Dönüş değeri:
  /// - [LogoJobRecord]: Dens satır
  /// {@endtemplate}
  factory LogoJobRecord.fromMap(Map<String, dynamic> map) {
    return LogoJobRecord(
      id: (map['id'] ?? '').toString(),
      entityType: (map['entity_type'] ?? '-').toString(),
      entityId: (map['entity_id'] ?? '-').toString(),
      payload: map['payload']?.toString(),
      priority: map['priority'] as int? ?? 0,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error']?.toString(),
      scheduledAt: map['scheduled_at']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  /// {@template logo_job_record_from_maps}
  /// Birden fazla sync_queue satırını dens listeye çevirir.
  ///
  /// Parametreler:
  /// - [maps]: SQLite satırları
  ///
  /// Dönüş değeri:
  /// - [List]: Dens job satırları
  /// {@endtemplate}
  static List<LogoJobRecord> fromMaps(List<Map<String, dynamic>> maps) {
    return maps.map(LogoJobRecord.fromMap).toList(growable: false);
  }

  /// {@template logo_job_record_to_map}
  /// LogoSyncQueueList / JobQueueService uyumlu map.
  ///
  /// Dönüş değeri:
  /// - [Map]: sync_queue alanları
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      if (payload != null) 'payload': payload,
      'priority': priority,
      'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
