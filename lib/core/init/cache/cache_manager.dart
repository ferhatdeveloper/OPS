import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Önbellek işlemleri için kullanılan servis sınıfı.
/// PRD'de belirtildiği üzere verilerin yerel olarak saklanması için kullanılır.
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  SharedPreferences? _preferences;

  // Singleton pattern
  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // String değer kaydetme
  Future<void> setStringValue(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  // String değer okuma
  String? getStringValue(String key) {
    return _preferences?.getString(key);
  }

  // Bool değer kaydetme
  Future<void> setBoolValue(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  // Bool değer okuma
  bool? getBoolValue(String key) {
    return _preferences?.getBool(key);
  }

  // Int değer kaydetme
  Future<void> setIntValue(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  // Int değer okuma
  int? getIntValue(String key) {
    return _preferences?.getInt(key);
  }

  // Double değer kaydetme
  Future<void> setDoubleValue(String key, double value) async {
    await _preferences?.setDouble(key, value);
  }

  // Double değer okuma
  double? getDoubleValue(String key) {
    return _preferences?.getDouble(key);
  }

  // Object kaydetme (JSON olarak)
  Future<void> setObject(String key, Object value) async {
    final String jsonData = jsonEncode(value);
    await _preferences?.setString(key, jsonData);
  }

  // Object okuma (JSON'dan)
  T? getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final String? jsonData = _preferences?.getString(key);
    if (jsonData == null) return null;

    final Map<String, dynamic> map = jsonDecode(jsonData);
    return fromJson(map);
  }

  // Bir anahtarı silme
  Future<void> removeValue(String key) async {
    await _preferences?.remove(key);
  }

  // Tüm önbelleği temizleme
  Future<void> clearCache() async {
    await _preferences?.clear();
  }

  // Bir anahtarın varlığını kontrol etme
  bool containsKey(String key) {
    return _preferences?.containsKey(key) ?? false;
  }
}
