// Dosya Adı: report_pivot_preference_store.dart
// Açıklama: Pivot varsayılan görünüm — rapor id başına SharedPreferences
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// {@template report_pivot_preference}
/// Kaydedilmiş pivot satır / sütun / ölçü alan seçimi.
///
/// Kullanım örneği:
/// ```dart
/// const pref = ReportPivotPreference(
///   rowFieldId: 'code',
///   valueFieldId: 'amount',
/// );
/// ```
/// {@endtemplate}
class ReportPivotPreference {
  /// [rowFieldId]: Satır boyutu
  final String? rowFieldId;

  /// [columnFieldId]: Sütun boyutu (null = tek ölçü)
  final String? columnFieldId;

  /// [valueFieldId]: Ölçü alanı
  final String? valueFieldId;

  /// {@macro report_pivot_preference}
  const ReportPivotPreference({
    this.rowFieldId,
    this.columnFieldId,
    this.valueFieldId,
  });

  /// JSON → tercih.
  factory ReportPivotPreference.fromJson(Map<String, dynamic> json) {
    return ReportPivotPreference(
      rowFieldId: json['row_field_id']?.toString(),
      columnFieldId: json['column_field_id']?.toString(),
      valueFieldId: json['value_field_id']?.toString(),
    );
  }

  /// Tercih → JSON.
  Map<String, dynamic> toJson() => {
        if (rowFieldId != null) 'row_field_id': rowFieldId,
        if (columnFieldId != null) 'column_field_id': columnFieldId,
        if (valueFieldId != null) 'value_field_id': valueFieldId,
      };

  /// Boş mu?
  bool get isEmpty =>
      (rowFieldId == null || rowFieldId!.isEmpty) &&
      (columnFieldId == null || columnFieldId!.isEmpty) &&
      (valueFieldId == null || valueFieldId!.isEmpty);
}

/// {@template report_pivot_preference_store}
/// Pivot varsayılanını rapor id başına saklar.
///
/// Kullanım örneği:
/// ```dart
/// final store = ReportPivotPreferenceStore();
/// await store.save('cari_extre', pref);
/// final loaded = await store.load('cari_extre');
/// ```
/// {@endtemplate}
class ReportPivotPreferenceStore {
  /// [prefsPrefix]: Anahtar öneki
  static const String prefsPrefix = 'report_pivot_v1_';

  /// [prefsFactory]: Test inject
  final Future<SharedPreferences> Function()? prefsFactory;

  /// [_memory]: Test bellek katmanı
  final Map<String, String>? _memory;

  /// {@macro report_pivot_preference_store}
  ReportPivotPreferenceStore({
    this.prefsFactory,
    Map<String, String>? memory,
  }) : _memory = memory;

  Future<SharedPreferences> _prefs() async {
    if (prefsFactory != null) return prefsFactory!();
    return SharedPreferences.getInstance();
  }

  String _key(String reportId) => '$prefsPrefix$reportId';

  /// {@template report_pivot_preference_store_load}
  /// Kayıtlı pivot görünümünü yükler; yoksa null.
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [ReportPivotPreference]: Tercih veya null
  /// {@endtemplate}
  Future<ReportPivotPreference?> load(String reportId) async {
    final mem = _memory;
    if (mem != null) {
      final raw = mem[_key(reportId)];
      if (raw == null || raw.isEmpty) return null;
      return _decode(raw);
    }
    final prefs = await _prefs();
    final raw = prefs.getString(_key(reportId));
    if (raw == null || raw.isEmpty) return null;
    return _decode(raw);
  }

  /// {@template report_pivot_preference_store_save}
  /// Pivot görünümünü rapor id için kaydeder.
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  /// - [pref]: Alan seçimi
  /// {@endtemplate}
  Future<void> save(String reportId, ReportPivotPreference pref) async {
    final encoded = jsonEncode(pref.toJson());
    final mem = _memory;
    if (mem != null) {
      mem[_key(reportId)] = encoded;
      return;
    }
    final prefs = await _prefs();
    await prefs.setString(_key(reportId), encoded);
  }

  /// {@template report_pivot_preference_store_clear}
  /// Kayıtlı pivot görünümünü siler.
  /// {@endtemplate}
  Future<void> clear(String reportId) async {
    final mem = _memory;
    if (mem != null) {
      mem.remove(_key(reportId));
      return;
    }
    final prefs = await _prefs();
    await prefs.remove(_key(reportId));
  }

  ReportPivotPreference? _decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        final pref = ReportPivotPreference.fromJson(map);
        return pref.isEmpty ? null : pref;
      }
      if (map is Map) {
        final pref = ReportPivotPreference.fromJson(
          Map<String, dynamic>.from(map),
        );
        return pref.isEmpty ? null : pref;
      }
    } catch (_) {
      // bozuk → yok
    }
    return null;
  }
}
