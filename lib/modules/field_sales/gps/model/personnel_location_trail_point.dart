// Dosya Adı: personnel_location_trail_point.dart
// Açıklama: Kişi bazlı GPS geçmiş trail noktası (gps_logs / uzak)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template personnel_location_trail_point}
/// Plasiyer konum geçmişi polyline noktası.
///
/// Kullanım örneği:
/// ```dart
/// final p = PersonnelLocationTrailPoint(
///   id: 'g1',
///   salespersonCode: 'PLS01',
///   latitude: 41.0,
///   longitude: 29.0,
///   recordedAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class PersonnelLocationTrailPoint {
  /// [id]: Kayıt kimliği
  final String id;

  /// [salespersonCode]: Plasiyer kodu
  final String salespersonCode;

  /// [userId]: Uzak kaynak kullanıcı id (opsiyonel)
  final String userId;

  /// [latitude]: Enlem
  final double latitude;

  /// [longitude]: Boylam
  final double longitude;

  /// [recordedAt]: Kayıt zamanı
  final DateTime recordedAt;

  /// [accuracy]: Metre doğruluk
  final double? accuracy;

  /// [label]: Etiket
  final String label;

  /// {@macro personnel_location_trail_point}
  const PersonnelLocationTrailPoint({
    required this.id,
    required this.salespersonCode,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.userId = '',
    this.accuracy,
    this.label = '',
  });

  /// Geçerli koordinat mı (0,0 hariç).
  bool get hasCoords =>
      latitude.abs() > 1e-9 || longitude.abs() > 1e-9;

  /// Map → model (gps_logs / PostgREST uyumlu).
  factory PersonnelLocationTrailPoint.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      final s = v?.toString() ?? '';
      return DateTime.tryParse(s) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return PersonnelLocationTrailPoint(
      id: (map['id'] ?? '').toString(),
      salespersonCode: (map['salesperson_code'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      recordedAt: parseDate(
        map['timestamp'] ?? map['recorded_at'] ?? map['updated_at'],
      ),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      label: (map['label'] ?? map['display_name'] ?? '').toString(),
    );
  }

  /// SQLite / REST map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salesperson_code': salespersonCode,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': recordedAt.toIso8601String(),
      'accuracy': accuracy,
      'label': label,
    };
  }

  /// {@template personnel_location_trail_merge}
  /// Aynı id için tek satır; kronolojik sıralama (eski → yeni).
  /// Geçersiz koordinatlar elenir.
  ///
  /// Parametreler:
  /// - [rows]: Ham noktalar
  ///
  /// Dönüş değeri:
  /// - [List]: Sıralı trail
  /// {@endtemplate}
  static List<PersonnelLocationTrailPoint> mergeChronological(
    List<PersonnelLocationTrailPoint> rows,
  ) {
    final byId = <String, PersonnelLocationTrailPoint>{};
    var anon = 0;
    for (final row in rows) {
      if (!row.hasCoords) continue;
      final key = row.id.trim().isEmpty
          ? '_anon_${anon++}_${row.recordedAt.millisecondsSinceEpoch}'
          : row.id.trim();
      final prev = byId[key];
      if (prev == null || row.recordedAt.isAfter(prev.recordedAt)) {
        byId[key] = row;
      }
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List<PersonnelLocationTrailPoint>.unmodifiable(list);
  }
}
