// Dosya Adı: geofence_settings_record.dart
// Açıklama: Geofence ayarları (yarıçap, aktif, fail-closed) veri modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template geofence_settings_record}
/// SharedPreferences'taki geofence / check-in yarıçap ayarları.
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

  /// [radiusMeters]: İzin verilen mesafe (metre)
  final int radiusMeters;

  /// [failClosed]: GPS yoksa check-in engellensin mi
  final bool failClosed;

  /// {@macro geofence_settings_record}
  const GeofenceSettingsRecord({
    this.enabled = true,
    this.radiusMeters = defaultRadiusMeters,
    this.failClosed = true,
  });

  /// {@template geofence_settings_record_defaults}
  /// Varsayılan ayarlar (100 m, açık, fail-closed).
  /// {@endtemplate}
  factory GeofenceSettingsRecord.defaults() {
    return const GeofenceSettingsRecord();
  }

  /// {@template geofence_settings_record_validate_radius}
  /// Yarıçap aralık dışındaysa l10n hata anahtarı döner.
  ///
  /// Parametreler:
  /// - [radiusMeters]: Kontrol edilecek yarıçap
  ///
  /// Dönüş değeri:
  /// - [String?]: Hata anahtarı veya null
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
  }) {
    return GeofenceSettingsRecord(
      enabled: enabled ?? this.enabled,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      failClosed: failClosed ?? this.failClosed,
    );
  }
}
