// Dosya Adı: report_language_preference_store.dart
// Açıklama: Varsayılan rapor dili SharedPreferences kalıcılığı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:shared_preferences/shared_preferences.dart';

import '../model/report_locale_resolver.dart';

/// {@template report_language_preference_store}
/// Uygulama geneli varsayılan rapor dilini okur / yazar.
/// Boş kayıt → uygulama diline düşülür (resolver).
///
/// Kullanım örneği:
/// ```dart
/// const store = ReportLanguagePreferenceStore();
/// await store.save('en');
/// final code = await store.load();
/// ```
/// {@endtemplate}
class ReportLanguagePreferenceStore {
  /// [prefsKey]: SharedPreferences anahtarı
  static const String prefsKey = 'report_default_locale';

  /// [prefsFactory]: Test için SharedPreferences fabrikası
  final Future<SharedPreferences> Function()? prefsFactory;

  /// {@macro report_language_preference_store}
  const ReportLanguagePreferenceStore({this.prefsFactory});

  Future<SharedPreferences> _prefs() async {
    if (prefsFactory != null) return prefsFactory!();
    return SharedPreferences.getInstance();
  }

  /// {@template report_language_preference_store_load}
  /// Kayıtlı varsayılan rapor dilini yükler; yoksa null.
  ///
  /// Dönüş değeri:
  /// - [String?]: Dil kodu veya null (uygulama dili kullanılır)
  /// {@endtemplate}
  Future<String?> load() async {
    final prefs = await _prefs();
    return ReportLocaleResolver.normalize(prefs.getString(prefsKey));
  }

  /// {@template report_language_preference_store_save}
  /// Varsayılan rapor dilini kaydeder.
  ///
  /// Parametreler:
  /// - [languageCode]: Dil kodu; null/boş → tercihi siler
  /// {@endtemplate}
  Future<void> save(String? languageCode) async {
    final prefs = await _prefs();
    final normalized = ReportLocaleResolver.normalize(languageCode);
    if (normalized == null) {
      await prefs.remove(prefsKey);
      return;
    }
    await prefs.setString(prefsKey, normalized);
  }
}
