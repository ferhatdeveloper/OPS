// Dosya Adı: appearance_settings_store.dart
// Açıklama: Görünüm ayarları SharedPreferences kalıcılık katmanı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:shared_preferences/shared_preferences.dart';

import '../model/appearance_settings_record.dart';

/// {@template appearance_settings_store}
/// Font büyüklüğü + tema rengini SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = AppearanceSettingsStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class AppearanceSettingsStore {
  /// [prefsFontSize]: Font büyüklüğü anahtarı
  static const String prefsFontSize = 'appearance_font_size';

  /// [prefsPrimaryColor]: Primary renk ARGB anahtarı
  static const String prefsPrimaryColor = 'appearance_primary_color';

  /// [prefsFactory]: Test için SharedPreferences fabrikası
  final Future<SharedPreferences> Function()? prefsFactory;

  /// {@macro appearance_settings_store}
  const AppearanceSettingsStore({this.prefsFactory});

  Future<SharedPreferences> _prefs() async {
    if (prefsFactory != null) return prefsFactory!();
    return SharedPreferences.getInstance();
  }

  /// {@template appearance_settings_store_load}
  /// Yerel kayıtlı görünüm ayarlarını yükler; yoksa varsayılan döner.
  ///
  /// Dönüş değeri:
  /// - [AppearanceSettingsRecord]: Yüklenen veya varsayılan kayıt
  /// {@endtemplate}
  Future<AppearanceSettingsRecord> load() async {
    final prefs = await _prefs();
    final rawFont = prefs.getDouble(prefsFontSize);
    final rawColor = prefs.getInt(prefsPrimaryColor);
    return AppearanceSettingsRecord(
      fontSize: AppearanceSettingsRecord.clampFontSize(
        rawFont ?? AppearanceSettingsRecord.defaultFontSize,
      ),
      primaryColorValue:
          rawColor ?? AppearanceSettingsRecord.defaultPrimaryColorValue,
    );
  }

  /// {@template appearance_settings_store_save}
  /// Görünüm ayarlarını SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek ayarlar
  /// {@endtemplate}
  Future<void> save(AppearanceSettingsRecord record) async {
    final prefs = await _prefs();
    final clamped = AppearanceSettingsRecord.clampFontSize(record.fontSize);
    await prefs.setDouble(prefsFontSize, clamped);
    await prefs.setInt(prefsPrimaryColor, record.primaryColorValue);
  }
}
