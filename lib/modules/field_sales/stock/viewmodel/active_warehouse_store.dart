// Dosya Adı: active_warehouse_store.dart
// Açıklama: Aktif ambar SharedPreferences + bellek oturumu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/active_warehouse_session.dart';

/// {@template active_warehouse_store}
/// Login’de seçilen ambarı prefs’e yazar.
///
/// Kullanım örneği:
/// ```dart
/// await const ActiveWarehouseStore().save(
///   const ActiveWarehouseSession(code: 'ARC', name: 'Araç Depo'),
/// );
/// ```
/// {@endtemplate}
class ActiveWarehouseStore {
  static const String prefsCode = 'fs_active_warehouse_code';
  static const String prefsName = 'fs_active_warehouse_name';
  static const String prefsType = 'fs_active_warehouse_type';

  static ActiveWarehouseSession? _current;

  static ActiveWarehouseSession? get current => _current;

  /// [revision]: Kaydet/yükle sonrası chip yenileme sinyali
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void _notify() {
    revision.value = revision.value + 1;
  }

  const ActiveWarehouseStore();

  Future<ActiveWarehouseSession> load() async {
    final prefs = await SharedPreferences.getInstance();
    final session = ActiveWarehouseSession(
      code: prefs.getString(prefsCode) ?? '',
      name: prefs.getString(prefsName) ?? '',
      type: prefs.getString(prefsType) ?? '',
    );
    _current = session.isEmpty ? null : session;
    return session;
  }

  Future<void> save(ActiveWarehouseSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsCode, session.code.trim());
    await prefs.setString(prefsName, session.name.trim());
    await prefs.setString(prefsType, session.type.trim());
    _current = session.isEmpty ? null : session;
    _notify();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsCode);
    await prefs.remove(prefsName);
    await prefs.remove(prefsType);
    _current = null;
    _notify();
  }

  static void resetMemory() {
    _current = null;
    revision.value = 0;
  }
}
