// Dosya Adı: gps_last_location_record.dart
// Açıklama: GPS Takip dens son konum satırı (gps_logs)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template gps_last_location_record}
/// Plasiyer / cihaz son konum dens satırı (`gps_logs`).
///
/// Kullanım örneği:
/// ```dart
/// final row = GpsLastLocationRecord(
///   id: 'gps-1',
///   latitude: 41.0082,
///   longitude: 28.9784,
///   recordedAt: DateTime(2026, 7, 26, 10, 0),
///   salespersonCode: 'PLS01',
/// );
/// ```
/// {@endtemplate}
class GpsLastLocationRecord {
  /// [id]: Yerel birincil anahtar
  final String id;

  /// [latitude]: Enlem
  final double latitude;

  /// [longitude]: Boylam
  final double longitude;

  /// [recordedAt]: Konum zamanı
  final DateTime recordedAt;

  /// [salespersonCode]: Plasiyer / kullanıcı kodu
  final String salespersonCode;

  /// [label]: Dens görünen etiket (cari / yer)
  final String label;

  /// [accuracy]: Metre cinsinden doğruluk (opsiyonel)
  final double? accuracy;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// [isDeleted]: Soft delete
  final int isDeleted;

  /// [createdAt]: Oluşturma
  final DateTime? createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime? updatedAt;

  /// {@macro gps_last_location_record}
  const GpsLastLocationRecord({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.salespersonCode = '',
    this.label = '',
    this.accuracy,
    this.isSynced = 0,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template gps_last_location_record_coord_text}
  /// Dens alt satır için lat/lng metni.
  /// {@endtemplate}
  String get coordinateText =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// {@template gps_last_location_record_to_map}
  /// SQLite `gps_logs` satır map’i.
  ///
  /// Dönüş değeri:
  /// - [Map]: Kolon → değer
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': recordedAt.toIso8601String(),
      'salesperson_code': salespersonCode,
      'label': label,
      'accuracy': accuracy,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// {@template gps_last_location_record_from_map}
  /// SQLite / seed map → model.
  ///
  /// Parametreler:
  /// - [map]: Kolon map’i
  ///
  /// Dönüş değeri:
  /// - [GpsLastLocationRecord]: Dens satırı
  /// {@endtemplate}
  factory GpsLastLocationRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final recorded = parseDate(map['timestamp']) ??
        parseDate(map['recorded_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return GpsLastLocationRecord(
      id: map['id']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      recordedAt: recorded,
      salespersonCode: map['salesperson_code']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      isDeleted: (map['is_deleted'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  /// {@template gps_last_location_record_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  GpsLastLocationRecord copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? recordedAt,
    String? salespersonCode,
    String? label,
    double? accuracy,
    int? isSynced,
    int? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GpsLastLocationRecord(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recordedAt: recordedAt ?? this.recordedAt,
      salespersonCode: salespersonCode ?? this.salespersonCode,
      label: label ?? this.label,
      accuracy: accuracy ?? this.accuracy,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
