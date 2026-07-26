// Dosya Adı: day_status_store.dart
// Açıklama: MBT gün başla/bitir SharedPreferences kalıcılık katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:shared_preferences/shared_preferences.dart';

import '../model/day_status_record.dart';

/// {@template day_status_store}
/// Gün durumu kaydını SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// final store = DayStatusStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class DayStatusStore {
  /// [prefsPlate]: Plaka anahtarı
  static const String prefsPlate = 'day_status_plate';

  /// [prefsStartKm]: Başlangıç KM anahtarı
  static const String prefsStartKm = 'day_status_start_km';

  /// [prefsEndKm]: Bitiş KM anahtarı
  static const String prefsEndKm = 'day_status_end_km';

  /// [prefsCompleted]: Tamamlandı anahtarı
  static const String prefsCompleted = 'day_status_completed';

  /// [prefsIsDayStarted]: Mesai açık anahtarı
  static const String prefsIsDayStarted = 'day_status_is_started';

  /// [prefsStartTime]: Başlangıç zamanı (ISO-8601)
  static const String prefsStartTime = 'day_status_start_time';

  /// [prefsEndTime]: Bitiş zamanı (ISO-8601)
  static const String prefsEndTime = 'day_status_end_time';

  /// {@macro day_status_store}
  const DayStatusStore();

  /// {@template day_status_store_load}
  /// Yerel kaydı yükler; yoksa varsayılan döner.
  ///
  /// Dönüş değeri:
  /// - [DayStatusRecord]: Yüklenen kayıt
  /// {@endtemplate}
  Future<DayStatusRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DayStatusRecord(
      plate: prefs.getString(prefsPlate) ?? '',
      startKm: prefs.getInt(prefsStartKm),
      endKm: prefs.getInt(prefsEndKm),
      completed: prefs.getBool(prefsCompleted) ?? false,
      isDayStarted: prefs.getBool(prefsIsDayStarted) ?? false,
      startTime: _parseTime(prefs.getString(prefsStartTime)),
      endTime: _parseTime(prefs.getString(prefsEndTime)),
    );
  }

  /// {@template day_status_store_is_day_open}
  /// Mesai açık mı (satış gate).
  ///
  /// Dönüş değeri:
  /// - [bool]: true ise sipariş/fatura/irsaliye/tahsilat açılabilir
  /// {@endtemplate}
  Future<bool> isDayOpen() async {
    final record = await load();
    return record.isDayOpen;
  }

  /// {@template day_status_store_save}
  /// Kaydı SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek gün durumu
  /// {@endtemplate}
  Future<void> save(DayStatusRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsPlate, record.plate);
    if (record.startKm != null) {
      await prefs.setInt(prefsStartKm, record.startKm!);
    } else {
      await prefs.remove(prefsStartKm);
    }
    if (record.endKm != null) {
      await prefs.setInt(prefsEndKm, record.endKm!);
    } else {
      await prefs.remove(prefsEndKm);
    }
    await prefs.setBool(prefsCompleted, record.completed);
    await prefs.setBool(prefsIsDayStarted, record.isDayStarted);
    if (record.startTime != null) {
      await prefs.setString(
        prefsStartTime,
        record.startTime!.toIso8601String(),
      );
    } else {
      await prefs.remove(prefsStartTime);
    }
    if (record.endTime != null) {
      await prefs.setString(
        prefsEndTime,
        record.endTime!.toIso8601String(),
      );
    } else {
      await prefs.remove(prefsEndTime);
    }
  }

  /// {@template day_status_store_parse_time}
  /// ISO-8601 zaman dizesini DateTime'a çevirir.
  /// {@endtemplate}
  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
