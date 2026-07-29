// Dosya Adı: tenant_logo_config_source_test.dart
// Açıklama: Logo ayar kaynağı (elle / kiracı kaydı / eski prefs) çözümleme testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TenantLogoConfigSourceResolver buildResolver(LogoTigerSettingsStore store) {
    return TenantLogoConfigSourceResolver(tigerStore: store);
  }

  test('hiç ayar yoksa kaynak tanımsızdır', () async {
    final store = LogoTigerSettingsStore();
    expect(await buildResolver(store).resolve(), TenantLogoConfigSource.none);
  });

  test('elle kaydedilen ayar manuel kaynak olur', () async {
    final store = LogoTigerSettingsStore();
    await store.save(
      const LogoTigerConfig(baseUrl: 'http://logo.example:32001'),
    );

    expect(await buildResolver(store).resolve(), TenantLogoConfigSource.manual);
  });

  test('registry seed işaretli ayar kiracı kaydı kaynağı olur', () async {
    final store = LogoTigerSettingsStore();
    await store.save(
      const LogoTigerConfig(baseUrl: 'http://logo.example:32001'),
      markManualOverride: false,
    );
    await store.markRegistrySeed(
      tenantCode: 'lovan',
      updatedAt: DateTime.utc(2026, 7, 29, 8),
    );

    expect(
      await buildResolver(store).resolve(),
      TenantLogoConfigSource.tenantRegistry,
    );
  });

  test('elle kayıt registry seedinden önce gelir', () async {
    final store = LogoTigerSettingsStore();
    await store.markRegistrySeed(tenantCode: 'lovan');
    await store.save(
      const LogoTigerConfig(baseUrl: 'http://elle.example:32001'),
    );

    expect(await buildResolver(store).resolve(), TenantLogoConfigSource.manual);
  });

  test('işaretsiz eski prefs kaydı legacy sayılır', () async {
    SharedPreferences.setMockInitialValues({
      LogoTigerSettingsStore.keyBaseUrl: 'http://eski.example:32001',
    });

    expect(
      await buildResolver(LogoTigerSettingsStore()).resolve(),
      TenantLogoConfigSource.legacyPrefs,
    );
  });

  test('her kaynak için l10n etiket anahtarı tanımlı', () {
    for (final source in TenantLogoConfigSource.values) {
      expect(
        TenantLogoConfigSourceResolver.labelKey(source),
        startsWith('field_sales.logo_config_source_'),
        reason: '$source için etiket yok',
      );
    }
  });
}
