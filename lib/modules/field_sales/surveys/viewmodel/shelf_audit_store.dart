// Dosya Adı: shelf_audit_store.dart
// Açıklama: Raf denetimi SharedPreferences kalıcılık katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/shelf_audit_record.dart';

/// {@template shelf_audit_store}
/// Raf denetimi dens form kaydını SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = ShelfAuditStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class ShelfAuditStore {
  /// [prefsKey]: JSON kayıt anahtarı
  static const String prefsKey = 'shelf_audit_record_json';

  /// {@macro shelf_audit_store}
  const ShelfAuditStore();

  /// {@template shelf_audit_store_load}
  /// Yerel kaydı yükler; yoksa varsayılan.
  ///
  /// Dönüş değeri:
  /// - [ShelfAuditRecord]: Yüklenen kayıt
  /// {@endtemplate}
  Future<ShelfAuditRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const ShelfAuditRecord();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ShelfAuditRecord();
      return ShelfAuditRecord.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const ShelfAuditRecord();
    }
  }

  /// {@template shelf_audit_store_save}
  /// Kaydı SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek dens form
  /// {@endtemplate}
  Future<void> save(ShelfAuditRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(record.toJson()));
  }

  /// {@template shelf_audit_store_clear}
  /// Yerel kaydı siler.
  /// {@endtemplate}
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
