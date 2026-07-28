// Dosya Adı: report_layout_store.dart
// Açıklama: Rapor dizayn kalıcılık — SharedPreferences JSON (+ SQLite DDL)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/report_layout.dart';
import '../model/report_layout_available_fields.dart';
import '../model/report_layout_defaults.dart';
import '../model/report_saved_view.dart';

/// {@template report_layout_store}
/// Dizaynı rapor id başına saklar. Web + mobil: SharedPreferences.
/// SQLite tablo DDL [SqlQuerys.createReportLayoutsTable] — sync için hazır.
///
/// Kullanım örneği:
/// ```dart
/// final store = ReportLayoutStore();
/// final layout = await store.load('cari_extre');
/// await store.save(layout.toggleColumn('debit'));
/// ```
/// {@endtemplate}
class ReportLayoutStore {
  /// [prefsPrefix]: Anahtar öneki
  static const String prefsPrefix = 'report_layout_v1_';

  /// [savedViewsPrefix]: Adlı görünüm listesi öneki
  static const String savedViewsPrefix = 'report_saved_views_v1_';

  /// [prefsFactory]: Test inject
  final Future<SharedPreferences> Function()? prefsFactory;

  /// [_memory]: Test / web-offline bellek katmanı (opsiyonel override)
  final Map<String, String>? _memory;

  /// {@macro report_layout_store}
  ReportLayoutStore({
    this.prefsFactory,
    Map<String, String>? memory,
  }) : _memory = memory;

  Future<SharedPreferences> _prefs() async {
    if (prefsFactory != null) return prefsFactory!();
    return SharedPreferences.getInstance();
  }

  String _key(String reportId) => '$prefsPrefix$reportId';

  String _savedViewsKey(String reportId) => '$savedViewsPrefix$reportId';

  /// {@template report_layout_store_load}
  /// Kayıtlı dizaynı yükler; yoksa varsayılan.
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [ReportLayout]: Layout
  /// {@endtemplate}
  Future<ReportLayout> load(String reportId) async {
    final mem = _memory;
    if (mem != null) {
      final raw = mem[_key(reportId)];
      if (raw == null || raw.isEmpty) {
        return ReportLayoutDefaults.forReportId(reportId);
      }
      return ReportLayoutAvailableFields.mergeInto(_decode(raw, reportId));
    }
    final prefs = await _prefs();
    final raw = prefs.getString(_key(reportId));
    if (raw == null || raw.isEmpty) {
      return ReportLayoutDefaults.forReportId(reportId);
    }
    return ReportLayoutAvailableFields.mergeInto(_decode(raw, reportId));
  }

  /// {@template report_layout_store_save}
  /// Dizaynı kaydeder.
  ///
  /// Parametreler:
  /// - [layout]: Kaydedilecek layout
  /// {@endtemplate}
  Future<void> save(ReportLayout layout) async {
    final encoded = jsonEncode(layout.toJson());
    final mem = _memory;
    if (mem != null) {
      mem[_key(layout.reportId)] = encoded;
      return;
    }
    final prefs = await _prefs();
    await prefs.setString(_key(layout.reportId), encoded);
  }

  /// {@template report_layout_store_reset}
  /// Varsayılana döner (kayıt silinir).
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [ReportLayout]: Varsayılan
  /// {@endtemplate}
  Future<ReportLayout> reset(String reportId) async {
    final mem = _memory;
    if (mem != null) {
      mem.remove(_key(reportId));
    } else {
      final prefs = await _prefs();
      await prefs.remove(_key(reportId));
    }
    return ReportLayoutDefaults.forReportId(reportId);
  }

  /// {@template report_layout_store_list_saved_views}
  /// Rapora kayıtlı adlı dizayn / pivot görünümlerini listeler.
  /// {@endtemplate}
  Future<List<ReportSavedView>> listSavedViews(String reportId) async {
    final raw = await _readRaw(_savedViewsKey(reportId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ReportSavedView>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final view = ReportSavedView.fromJson(item);
          if (view != null) out.add(view);
        } else if (item is Map) {
          final view =
              ReportSavedView.fromJson(Map<String, dynamic>.from(item));
          if (view != null) out.add(view);
        }
      }
      out.sort((a, b) => a.name.compareTo(b.name));
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// {@template report_layout_store_upsert_saved_view}
  /// Adlı görünüm ekler veya günceller (aynı id).
  /// {@endtemplate}
  Future<void> upsertSavedView({
    required String reportId,
    required ReportSavedView view,
  }) async {
    final list = await listSavedViews(reportId);
    final next = [
      ...list.where((v) => v.id != view.id),
      view,
    ]..sort((a, b) => a.name.compareTo(b.name));
    await _writeRaw(
      _savedViewsKey(reportId),
      jsonEncode(next.map((v) => v.toJson()).toList()),
    );
  }

  /// {@template report_layout_store_delete_saved_view}
  /// Adlı görünümü siler.
  /// {@endtemplate}
  Future<void> deleteSavedView({
    required String reportId,
    required String viewId,
  }) async {
    final list = await listSavedViews(reportId);
    final next = list.where((v) => v.id != viewId).toList(growable: false);
    await _writeRaw(
      _savedViewsKey(reportId),
      jsonEncode(next.map((v) => v.toJson()).toList()),
    );
  }

  Future<String?> _readRaw(String key) async {
    final mem = _memory;
    if (mem != null) return mem[key];
    final prefs = await _prefs();
    return prefs.getString(key);
  }

  Future<void> _writeRaw(String key, String value) async {
    final mem = _memory;
    if (mem != null) {
      mem[key] = value;
      return;
    }
    final prefs = await _prefs();
    await prefs.setString(key, value);
  }

  ReportLayout _decode(String raw, String reportId) {
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        final layout = ReportLayout.fromJson(map);
        if (layout.reportId.isEmpty) {
          return layout.copyWith(reportId: reportId);
        }
        return layout;
      }
      if (map is Map) {
        final layout =
            ReportLayout.fromJson(Map<String, dynamic>.from(map));
        if (layout.reportId.isEmpty) {
          return layout.copyWith(reportId: reportId);
        }
        return layout;
      }
    } catch (_) {
      // bozuk kayıt → varsayılan
    }
    return ReportLayoutDefaults.forReportId(reportId);
  }
}
