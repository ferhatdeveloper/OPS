// Dosya Adı: tenant_logo_config_source.dart
// Açıklama: Etkin Logo ayarının hangi kaynaktan geldiğini çözümler
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import '../logo/logo_tiger_settings_store.dart';

/// {@template tenant_logo_config_source}
/// Etkin Logo bağlantı ayarının kaynağı.
/// {@endtemplate}
enum TenantLogoConfigSource {
  /// Hiç ayar yok
  none,

  /// Kullanıcı elle girip kaydetti (manual override)
  manual,

  /// Merkez `tenant_registry` kaydından seed edildi
  tenantRegistry,

  /// İşaretsiz eski prefs kaydı (sürüm öncesi)
  legacyPrefs,
}

/// {@template tenant_logo_config_source_resolver}
/// Ayar kaynağını [LogoTigerSettingsStore] işaretlerinden çözümler.
///
/// Öncelik: elle kayıt > registry seed > işaretsiz eski kayıt > yok.
///
/// Kullanım örneği:
/// ```dart
/// final source = await TenantLogoConfigSourceResolver(
///   tigerStore: LogoTigerSettingsStore(),
/// ).resolve();
/// ```
/// {@endtemplate}
class TenantLogoConfigSourceResolver {
  /// [tigerStore]: Logo Tiger ayar deposu
  final LogoTigerSettingsStore tigerStore;

  /// {@macro tenant_logo_config_source_resolver}
  const TenantLogoConfigSourceResolver({required this.tigerStore});

  /// {@template tenant_logo_config_source_resolver_resolve}
  /// Etkin ayar kaynağını döndürür.
  ///
  /// Dönüş değeri:
  /// - [TenantLogoConfigSource]: Çözümlenen kaynak
  /// {@endtemplate}
  Future<TenantLogoConfigSource> resolve() async {
    if (await tigerStore.hasManualOverride()) {
      return TenantLogoConfigSource.manual;
    }

    final seed = await tigerStore.lastRegistrySeed();
    if (seed.tenantCode != null) {
      return TenantLogoConfigSource.tenantRegistry;
    }

    final config = await tigerStore.loadRaw();
    if (config.baseUrl.trim().isNotEmpty) {
      return TenantLogoConfigSource.legacyPrefs;
    }
    return TenantLogoConfigSource.none;
  }

  /// {@template tenant_logo_config_source_resolver_label_key}
  /// Kaynağın kullanıcıya gösterilecek l10n anahtarı.
  ///
  /// Parametreler:
  /// - [source]: Çözümlenen kaynak
  ///
  /// Dönüş değeri:
  /// - [String]: `field_sales.logo_config_source_*` anahtarı
  /// {@endtemplate}
  static String labelKey(TenantLogoConfigSource source) {
    switch (source) {
      case TenantLogoConfigSource.manual:
        return 'field_sales.logo_config_source_manual';
      case TenantLogoConfigSource.tenantRegistry:
        return 'field_sales.logo_config_source_registry';
      case TenantLogoConfigSource.legacyPrefs:
        return 'field_sales.logo_config_source_legacy';
      case TenantLogoConfigSource.none:
        return 'field_sales.logo_config_source_none';
    }
  }
}
