// Dosya Adı: competitor_survey_store.dart
// Açıklama: Rakip anket SharedPreferences kalıcılık katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/competitor_survey_record.dart';

/// {@template competitor_survey_store}
/// Rakip anket dens form kaydını SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = CompetitorSurveyStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class CompetitorSurveyStore {
  /// [prefsKey]: JSON kayıt anahtarı
  static const String prefsKey = 'competitor_survey_record_json';

  /// {@macro competitor_survey_store}
  const CompetitorSurveyStore();

  /// {@template competitor_survey_store_load}
  /// Yerel kaydı yükler; yoksa varsayılan.
  ///
  /// Dönüş değeri:
  /// - [CompetitorSurveyRecord]: Yüklenen kayıt
  /// {@endtemplate}
  Future<CompetitorSurveyRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const CompetitorSurveyRecord();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const CompetitorSurveyRecord();
      return CompetitorSurveyRecord.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const CompetitorSurveyRecord();
    }
  }

  /// {@template competitor_survey_store_save}
  /// Kaydı SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek dens form
  /// {@endtemplate}
  Future<void> save(CompetitorSurveyRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(record.toJson()));
  }

  /// {@template competitor_survey_store_clear}
  /// Yerel kaydı siler.
  /// {@endtemplate}
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
