// Dosya Adı: geofence_settings_record.dart
// Açıklama: Geofence ayarları (yarıçap, sipariş, proximity) veri modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template geofence_settings_record}
/// SharedPreferences'taki geofence / check-in / proximity ayarları.
///
/// Kullanım örneği:
/// ```dart
/// const record = GeofenceSettingsRecord(
///   enabled: true,
///   radiusMeters: 100,
///   failClosed: true,
/// );
/// ```
/// {@endtemplate}
class GeofenceSettingsRecord {
  /// [defaultRadiusMeters]: Varsayılan yarıçap (metre)
  static const int defaultRadiusMeters = 100;

  /// [minRadiusMeters]: Minimum izin verilen yarıçap
  static const int minRadiusMeters = 10;

  /// [maxRadiusMeters]: Maksimum izin verilen yarıçap
  static const int maxRadiusMeters = 5000;

  /// [enabled]: Check-in geofence kontrolü açık mı
  final bool enabled;

  /// [radiusMeters]: Check-in / sipariş yarıçapı (metre)
  final int radiusMeters;

  /// [failClosed]: GPS yoksa check-in / sipariş engellensin mi
  final bool failClosed;

  /// [orderRequireGeofence]: Siparişte müşteri GPS yarıçapı zorunlu mu
  final bool orderRequireGeofence;

  /// [proximityAlertsEnabled]: Yakın müşteri bildirim / diyalog
  final bool proximityAlertsEnabled;

  /// [proximityRadiusMeters]: Proximity yarıçapı; 0 → [radiusMeters]
  final int proximityRadiusMeters;

  /// {@macro geofence_settings_record}
  const GeofenceSettingsRecord({
    this.enabled = true,
    this.radiusMeters = defaultRadiusMeters,
    this.failClosed = true,
    this.orderRequireGeofence = false,
    this.proximityAlertsEnabled = true,
    this.proximityRadiusMeters = 0,
  });

  /// {@template geofence_settings_record_defaults}
  /// Varsayılan ayarlar (100 m, açık, fail-closed).
  /// {@endtemplate}
  factory GeofenceSettingsRecord.defaults() {
    return const GeofenceSettingsRecord();
  }

  /// Proximity için etkili yarıçap (0 ise check-in yarıçapı).
  int get effectiveProximityRadiusMeters {
    if (proximityRadiusMeters > 0) return proximityRadiusMeters;
    return radiusMeters;
  }

  /// {@template geofence_settings_record_validate_radius}
  /// Yarıçap aralık dışındaysa l10n hata anahtarı döner.
  /// {@endtemplate}
  static String? validateRadius(int? radiusMeters) {
    if (radiusMeters == null) {
      return 'field_sales.geofence_radius_required';
    }
    if (radiusMeters < minRadiusMeters ||
        radiusMeters > maxRadiusMeters) {
      return 'field_sales.geofence_radius_invalid';
    }
    return null;
  }

  /// {@template geofence_settings_record_copy_with}
  /// İmmutable kopya üretir.
  /// {@endtemplate}
  GeofenceSettingsRecord copyWith({
    bool? enabled,
    int? radiusMeters,
    bool? failClosed,
    bool? orderRequireGeofence,
    bool? proximityAlertsEnabled,
    int? proximityRadiusMeters,
  }) {
    return GeofenceSettingsRecord(
      enabled: enabled ?? this.enabled,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      failClosed: failClosed ?? this.failClosed,
      orderRequireGeofence:
          orderRequireGeofence ?? this.orderRequireGeofence,
      proximityAlertsEnabled:
          proximityAlertsEnabled ?? this.proximityAlertsEnabled,
      proximityRadiusMeters:
          proximityRadiusMeters ?? this.proximityRadiusMeters,
    );
  }
}
