// Dosya Adı: geofence_settings_store.dart
// Açıklama: Geofence ayarları SharedPreferences load/save katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:shared_preferences/shared_preferences.dart';

import '../model/geofence_settings_record.dart';

/// {@template geofence_settings_store}
/// Geofence / sipariş / proximity ayarlarını SharedPreferences
/// ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = GeofenceSettingsStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class GeofenceSettingsStore {
  /// [prefsEnabled]: Check-in geofence aktif
  static const String prefsEnabled = 'geofence_settings_enabled';

  /// [prefsRadiusMeters]: Check-in yarıçap (metre)
  static const String prefsRadiusMeters = 'geofence_settings_radius_m';

  /// [prefsFailClosed]: GPS yoksa engelle
  static const String prefsFailClosed = 'geofence_settings_fail_closed';

  /// [prefsOrderRequireGeofence]: Sipariş GPS yarıçap zorunluluğu
  static const String prefsOrderRequireGeofence =
      'geofence_settings_order_require';

  /// [prefsProximityAlerts]: Yakın müşteri bildirimi
  static const String prefsProximityAlerts =
      'geofence_settings_proximity_alerts';

  /// [prefsProximityRadiusMeters]: Proximity yarıçapı (0 = check-in)
  static const String prefsProximityRadiusMeters =
      'geofence_settings_proximity_radius_m';

  /// {@macro geofence_settings_store}
  const GeofenceSettingsStore();

  /// {@template geofence_settings_store_load}
  /// Yerel kayıtlı ayarları yükler; yoksa varsayılan döner.
  /// {@endtemplate}
  Future<GeofenceSettingsRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final radius = prefs.getInt(prefsRadiusMeters);
    final enabled = prefs.getBool(prefsEnabled) ?? true;
    final proximityAlerts = prefs.containsKey(prefsProximityAlerts)
        ? (prefs.getBool(prefsProximityAlerts) ?? true)
        : enabled;
    return GeofenceSettingsRecord(
      enabled: enabled,
      radiusMeters: radius ?? GeofenceSettingsRecord.defaultRadiusMeters,
      failClosed: prefs.getBool(prefsFailClosed) ?? true,
      orderRequireGeofence:
          prefs.getBool(prefsOrderRequireGeofence) ?? false,
      proximityAlertsEnabled: proximityAlerts,
      proximityRadiusMeters:
          prefs.getInt(prefsProximityRadiusMeters) ?? 0,
    );
  }

  /// {@template geofence_settings_store_save}
  /// Ayarları SharedPreferences'a yazar.
  /// {@endtemplate}
  Future<void> save(GeofenceSettingsRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = record.radiusMeters.clamp(
      GeofenceSettingsRecord.minRadiusMeters,
      GeofenceSettingsRecord.maxRadiusMeters,
    );
    var prox = record.proximityRadiusMeters;
    if (prox > 0) {
      prox = prox.clamp(
        GeofenceSettingsRecord.minRadiusMeters,
        GeofenceSettingsRecord.maxRadiusMeters,
      );
    }
    await prefs.setBool(prefsEnabled, record.enabled);
    await prefs.setInt(prefsRadiusMeters, clamped);
    await prefs.setBool(prefsFailClosed, record.failClosed);
    await prefs.setBool(
      prefsOrderRequireGeofence,
      record.orderRequireGeofence,
    );
    await prefs.setBool(
      prefsProximityAlerts,
      record.proximityAlertsEnabled,
    );
    await prefs.setInt(prefsProximityRadiusMeters, prox);
  }
}
