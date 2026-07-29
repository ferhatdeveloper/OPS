// Dosya Adı: tenant_logo_config_store.dart
// Açıklama: Tenant Logo registry cache'inin tek anahtarlı prefs kalıcılığı
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'tenant_logo_config_cache.dart';

/// {@template tenant_logo_config_store}
/// [TenantLogoConfigCache] kaydını tek bir JSON prefs anahtarında tutar.
///
/// Tek anahtar kullanımı kısmi yazımı (yarım kaydedilmiş alanlar) engeller.
/// Okuma her zaman aktif kiracı koduyla filtrelenir; farklı kiracının kaydı
/// `null` döner.
///
/// Kullanım örneği:
/// ```dart
/// const store = TenantLogoConfigStore();
/// await store.save(cache);
/// final loaded = await store.loadForTenant('lovan');
/// ```
/// {@endtemplate}
class TenantLogoConfigStore {
  /// [prefsCache]: Tenant Logo cache JSON anahtarı
  static const String prefsCache = 'ops_tenant_logo_registry_cache_v1';

  /// {@macro tenant_logo_config_store}
  const TenantLogoConfigStore();

  /// {@template tenant_logo_config_store_save}
  /// Cache kaydını atomik olarak yazar (önceki kiracı kaydını değiştirir).
  /// {@endtemplate}
  Future<void> save(TenantLogoConfigCache cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsCache, jsonEncode(cache.toJson()));
  }

  /// {@template tenant_logo_config_store_load}
  /// Yalnızca verilen kiracıya ait cache kaydını döndürür.
  ///
  /// Parametreler:
  /// - [tenantCode]: Aktif kiracı kodu
  ///
  /// Dönüş değeri:
  /// - [TenantLogoConfigCache]: Eşleşen kayıt; yoksa / bozuksa `null`
  /// {@endtemplate}
  Future<TenantLogoConfigCache?> loadForTenant(String tenantCode) async {
    final code = tenantCode.trim().toLowerCase();
    if (code.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsCache);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final cache = TenantLogoConfigCache.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return cache.tenantCode == code ? cache : null;
    } on Object {
      return null;
    }
  }

  /// Cache kaydını siler.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsCache);
  }
}
