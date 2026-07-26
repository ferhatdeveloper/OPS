// Dosya Adı: geofence_settings_store.dart
// Açıklama: Geofence ayarları SharedPreferences load/save katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:shared_preferences/shared_preferences.dart';

import '../model/geofence_settings_record.dart';

/// {@template geofence_settings_store}
/// Geofence yarıçap / aktif / fail-closed ayarlarını SharedPreferences
/// ile okur / yazar. [GpsService.isWithinVisitRange] bu store'u kullanır.
///
/// Kullanım örneği:
/// ```dart
/// const store = GeofenceSettingsStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class GeofenceSettingsStore {
  /// [prefsEnabled]: Geofence aktif anahtarı
  static const String prefsEnabled = 'geofence_settings_enabled';

  /// [prefsRadiusMeters]: Yarıçap (metre) anahtarı
  static const String prefsRadiusMeters = 'geofence_settings_radius_m';

  /// [prefsFailClosed]: GPS yoksa engelle anahtarı
  static const String prefsFailClosed = 'geofence_settings_fail_closed';

  /// {@macro geofence_settings_store}
  const GeofenceSettingsStore();

  /// {@template geofence_settings_store_load}
  /// Yerel kayıtlı ayarları yükler; yoksa varsayılan döner.
  ///
  /// Dönüş değeri:
  /// - [GeofenceSettingsRecord]: Yüklenen veya varsayılan kayıt
  /// {@endtemplate}
  Future<GeofenceSettingsRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final radius = prefs.getInt(prefsRadiusMeters);
    return GeofenceSettingsRecord(
      enabled: prefs.getBool(prefsEnabled) ?? true,
      radiusMeters: radius ?? GeofenceSettingsRecord.defaultRadiusMeters,
      failClosed: prefs.getBool(prefsFailClosed) ?? true,
    );
  }

  /// {@template geofence_settings_store_save}
  /// Ayarları SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek ayarlar
  /// {@endtemplate}
  Future<void> save(GeofenceSettingsRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = record.radiusMeters.clamp(
      GeofenceSettingsRecord.minRadiusMeters,
      GeofenceSettingsRecord.maxRadiusMeters,
    );
    await prefs.setBool(prefsEnabled, record.enabled);
    await prefs.setInt(prefsRadiusMeters, clamped);
    await prefs.setBool(prefsFailClosed, record.failClosed);
  }
}
