// Dosya Adı: personnel_live_location.dart
// Açıklama: Personel bazlı canlı konum satırı (SQLite / PostgREST / UI)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'live_location_quality.dart';

/// {@template personnel_live_location}
/// Plasiyer canlı konum dens satırı.
///
/// Kullanım örneği:
/// ```dart
/// final row = PersonnelLiveLocation(
///   userId: 'u1',
///   salespersonCode: 'PLS01',
///   displayName: 'Ali',
///   latitude: 41.0,
///   longitude: 29.0,
///   updatedAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class PersonnelLiveLocation {
  /// [userId]: Kullanıcı / plasiyer kimliği
  final String userId;

  /// [salespersonCode]: Plasiyer kodu
  final String salespersonCode;

  /// [displayName]: Görünen ad / etiket
  final String displayName;

  /// [latitude]: Enlem
  final double latitude;

  /// [longitude]: Boylam
  final double longitude;

  /// [updatedAt]: Son güncelleme
  final DateTime updatedAt;

  /// [accuracy]: Metre doğruluk (opsiyonel)
  final double? accuracy;

  /// [isSynced]: Sunucuya aktarıldı mı
  final bool isSynced;

  /// {@macro personnel_live_location}
  const PersonnelLiveLocation({
    required this.userId,
    required this.salespersonCode,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.accuracy,
    this.isSynced = false,
  });

  /// Dens alt satır lat/lng metni.
  String get coordinateText =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// {@template personnel_live_location_is_fresh}
  /// [maxAge] içinde güncellenmişse canlı sayılır.
  /// Varsayılan: gerçek zamanlı pencere (~90 sn).
  /// {@endtemplate}
  bool isFresh({
    DateTime? now,
    Duration maxAge = LiveLocationQuality.realtimeFreshMaxAge,
  }) {
    final n = now ?? DateTime.now();
    return n.difference(updatedAt) <= maxAge;
  }

  /// Senkron için doğruluk eşiğini geçer mi.
  bool hasAcceptableAccuracy({
    double maxAccuracyMeters =
        LiveLocationQuality.maxSyncAccuracyMeters,
  }) {
    return LiveLocationQuality.acceptsFix(
      accuracyMeters: accuracy,
      maxAccuracyMeters: maxAccuracyMeters,
    );
  }

  /// Son güncelleme yaşı.
  Duration age({DateTime? now}) =>
      LiveLocationQuality.ageOf(updatedAt, now: now);

  /// SQLite / PostgREST map.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'salesperson_code': salespersonCode,
      'display_name': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt.toIso8601String(),
      'accuracy': accuracy,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Map → model (gps_logs / live_location_snapshots uyumlu).
  factory PersonnelLiveLocation.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      final s = v?.toString() ?? '';
      return DateTime.tryParse(s) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    final syncedRaw = map['is_synced'];
    final synced = syncedRaw == true ||
        syncedRaw == 1 ||
        syncedRaw?.toString() == '1';

    return PersonnelLiveLocation(
      userId: (map['user_id'] ?? map['id'] ?? '').toString(),
      salespersonCode:
          (map['salesperson_code'] ?? '').toString(),
      displayName: (map['display_name'] ??
              map['label'] ??
              map['salesperson_code'] ??
              map['user_id'] ??
              '')
          .toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      updatedAt: parseDate(
        map['updated_at'] ?? map['last_update'] ?? map['timestamp'],
      ),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      isSynced: synced,
    );
  }

  /// {@template personnel_live_location_merge}
  /// Aynı [userId] için en güncel satırı tutar.
  /// {@endtemplate}
  static List<PersonnelLiveLocation> mergeLatestByUserId(
    List<PersonnelLiveLocation> rows,
  ) {
    final byId = <String, PersonnelLiveLocation>{};
    for (final row in rows) {
      final key = row.userId.trim().isEmpty
          ? row.salespersonCode
          : row.userId;
      if (key.isEmpty) continue;
      final prev = byId[key];
      if (prev == null || row.updatedAt.isAfter(prev.updatedAt)) {
        byId[key] = row;
      }
    }
    final list = byId.values.toList(growable: false);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }
}
