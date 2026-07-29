// Dosya Adı: logo_tenant_config_seeder.dart
// Açıklama: Tenant registry Logo cache'ini Tiger ayarlarına uygulayan seeder
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/foundation.dart';

import '../tenant/tenant_logo_config_cache.dart';
import 'logo_tiger_settings_store.dart';
import 'logo_tiger_urls.dart';

/// {@template logo_tenant_config_seeder}
/// Merkez registry'den gelen Logo başlangıç değerlerini
/// [LogoTigerSettingsStore] ile birleştirir.
///
/// Politika:
/// 1. Kullanıcının açık manuel override'ı varsa seed uygulanmaz.
/// 2. Logo URL boş veya çözümlenemiyorsa seed uygulanmaz.
/// 3. Firma / dönem yalnızca pozitif değer geldiğinde güncellenir.
/// 4. Boş `logo_db` mevcut değeri silmez.
/// 5. `apiKey`, `username`, `password`, `clientId`, `clientSecret` ve access
///    token alanlarına dokunulmaz.
/// 6. Aynı kiracı için yalnızca daha yeni `updated_at` seed'i yeniler.
///
/// Kullanım örneği:
/// ```dart
/// final applied = await LogoTenantConfigSeeder(
///   tigerStore: LogoTigerSettingsStore(),
/// ).apply(cache);
/// ```
/// {@endtemplate}
class LogoTenantConfigSeeder {
  /// [tigerStore]: Logo Tiger ayar deposu
  final LogoTigerSettingsStore tigerStore;

  /// {@macro logo_tenant_config_seeder}
  const LogoTenantConfigSeeder({required this.tigerStore});

  /// {@template logo_tenant_config_seeder_apply}
  /// Cache'i Tiger ayarlarına uygular.
  ///
  /// Parametreler:
  /// - [cache]: Aktif kiracıya ait Logo registry cache kaydı
  /// - [force]: Kullanıcı açıkça "kiracı kaydından çek" dediğinde `true`;
  ///   manuel override ve tazelik kontrolü atlanır. Secret alanlar yine
  ///   korunur.
  ///
  /// Dönüş değeri:
  /// - [bool]: Ayarlar güncellendiyse `true`, atlandıysa `false`
  /// {@endtemplate}
  Future<bool> apply(TenantLogoConfigCache cache, {bool force = false}) async {
    if (!force && await tigerStore.hasManualOverride()) {
      debugPrint('LogoTenantConfigSeeder: manuel override korundu');
      return false;
    }

    final normalizedUrl = _normalizeOrEmpty(cache.logoRestApiUrl);
    if (normalizedUrl.isEmpty) {
      debugPrint('LogoTenantConfigSeeder: registry Logo URL uygulanamadı');
      return false;
    }

    if (!force && !await _isNewerThanLastSeed(cache)) {
      debugPrint('LogoTenantConfigSeeder: registry seed güncel, atlandı');
      return false;
    }

    final current = await tigerStore.loadRaw();
    final logoDb = cache.logoDb?.trim();
    final next = current.copyWith(
      baseUrl: normalizedUrl,
      firmNr: cache.logoFirmNr ?? current.firmNr,
      periodNr: cache.logoPeriodNr ?? current.periodNr,
      logoDb: (logoDb != null && logoDb.isNotEmpty) ? logoDb : current.logoDb,
    );

    await tigerStore.save(next, markManualOverride: false);
    await tigerStore.markRegistrySeed(
      tenantCode: cache.tenantCode,
      updatedAt: cache.registryUpdatedAt,
    );
    debugPrint('LogoTenantConfigSeeder: registry seed uygulandı');
    return true;
  }

  /// {@template logo_tenant_config_seeder_is_newer}
  /// Cache, son registry seed'inden daha yeni mi?
  ///
  /// Farklı kiracı her zaman uygulanabilir. `updated_at` yoksa yalnızca daha
  /// önce aynı kiracı için registry seed'i yokken uygulanır.
  /// {@endtemplate}
  Future<bool> _isNewerThanLastSeed(TenantLogoConfigCache cache) async {
    final mark = await tigerStore.lastRegistrySeed();
    if (mark.tenantCode == null || mark.tenantCode != cache.tenantCode) {
      return true;
    }
    final incoming = cache.registryUpdatedAt;
    if (incoming == null) return false;
    final previous = mark.updatedAt;
    if (previous == null) return true;
    return incoming.isAfter(previous);
  }

  /// [_normalizeOrEmpty]: Kullanılabilir Logo tabanı üretir; aksi halde boş.
  static String _normalizeOrEmpty(String? rawUrl) {
    final raw = rawUrl?.trim() ?? '';
    if (raw.isEmpty) return '';
    final normalized = LogoTigerUrls.normalizeBaseUrl(raw);
    if (normalized.isEmpty) return '';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.trim().isEmpty) return '';
    return normalized;
  }
}
