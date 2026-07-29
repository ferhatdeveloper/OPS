// Dosya Adı: postgrest_tenant_logo_restore_test.dart
// Açıklama: Offline restore akışında tenant Logo cache seed testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_service.dart';
import 'package:exfin_ops/core/tenant/tenant_context.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_cache.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_store.dart';
import 'package:exfin_ops/core/tenant/tenant_store.dart';

/// [_saveTenant]: Aktif kiracı bağlamını prefs'e yazar.
Future<void> _saveTenant(String code) {
  return const TenantStore().save(
    TenantContext(
      tenantCode: code,
      remoteRestUrl: 'https://api.retailex.app/$code',
    ),
  );
}

/// [_saveLogoCache]: Kiracıya ait Logo registry cache kaydı yazar.
Future<void> _saveLogoCache({
  required String tenantCode,
  String url = 'http://cachedlogo.example:32001/api/v1',
  int? firmNr = 77,
  int? periodNr = 3,
  String? logoDb = 'TIGER3',
}) {
  return const TenantLogoConfigStore().save(
    TenantLogoConfigCache(
      tenantCode: tenantCode,
      logoRestApiUrl: url,
      logoFirmNr: firmNr,
      logoPeriodNr: periodNr,
      logoDb: logoDb,
      registryUpdatedAt: DateTime.utc(2026, 7, 29, 8),
      fetchedAt: DateTime.utc(2026, 7, 29, 9),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TenantStore.resetMemory();
  });

  group('PostgrestTenantService.restoreActiveContext Logo restore', () {
    test('ağ olmadan tenant Logo cachei yeniden uygulanır', () async {
      await _saveTenant('lovan');
      await _saveLogoCache(tenantCode: 'lovan');

      final ctx = await PostgrestTenantService(
        syncPostgres: false,
      ).restoreActiveContext();
      final tiger = await LogoTigerSettingsStore().loadRaw();

      expect(ctx?.tenantCode, 'lovan');
      expect(tiger.normalizedBaseUrl, 'http://cachedlogo.example:32001/api/v1');
      expect(tiger.firmNr, 77);
      expect(tiger.periodNr, 3);
      expect(tiger.logoDb, 'TIGER3');
    });

    test('restore secret alanları korur', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(
          baseUrl: '',
          apiKey: 'api-secret',
          username: 'logo-user',
          password: 'password-secret',
          clientId: 'client-id',
          clientSecret: 'client-secret',
        ),
        markManualOverride: false,
      );
      await _saveTenant('lovan');
      await _saveLogoCache(tenantCode: 'lovan');

      await PostgrestTenantService(syncPostgres: false).restoreActiveContext();
      final tiger = await store.loadRaw();

      expect(tiger.apiKey, 'api-secret');
      expect(tiger.username, 'logo-user');
      expect(tiger.password, 'password-secret');
      expect(tiger.clientId, 'client-id');
      expect(tiger.clientSecret, 'client-secret');
    });

    test('manuel Logo ayarı restore tarafından ezilmez', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(
          baseUrl: 'http://manual.example:32001/api/v1',
          firmNr: 999,
        ),
      );
      await _saveTenant('lovan');
      await _saveLogoCache(tenantCode: 'lovan');

      await PostgrestTenantService(syncPostgres: false).restoreActiveContext();
      final tiger = await store.loadRaw();

      expect(tiger.normalizedBaseUrl, 'http://manual.example:32001/api/v1');
      expect(tiger.firmNr, 999);
    });

    test('başka tenantın cachei restore sırasında uygulanmaz', () async {
      await _saveTenant('aqua');
      await _saveLogoCache(tenantCode: 'lovan');

      await PostgrestTenantService(syncPostgres: false).restoreActiveContext();
      final tiger = await LogoTigerSettingsStore().loadRaw();

      expect(tiger.baseUrl, isEmpty);
      expect(tiger.firmNr, 1);
    });

    test('kayıtlı kiracı yoksa restore null döner ve Logo değişmez', () async {
      await _saveLogoCache(tenantCode: 'lovan');

      final ctx = await PostgrestTenantService(
        syncPostgres: false,
      ).restoreActiveContext();
      final tiger = await LogoTigerSettingsStore().loadRaw();

      expect(ctx, isNull);
      expect(tiger.baseUrl, isEmpty);
    });

    test('Logo cache yoksa restore Logo ayarlarını bozmaz', () async {
      await _saveTenant('lovan');

      await PostgrestTenantService(syncPostgres: false).restoreActiveContext();
      final tiger = await LogoTigerSettingsStore().loadRaw();

      expect(tiger.baseUrl, isEmpty);
      expect(tiger.firmNr, 1);
    });

    test('URL taşımayan cache Logo ayarlarını bozmaz', () async {
      await _saveTenant('lovan');
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoFirmNr: 77,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      await PostgrestTenantService(syncPostgres: false).restoreActiveContext();
      final tiger = await LogoTigerSettingsStore().loadRaw();

      expect(tiger.baseUrl, isEmpty);
      expect(tiger.firmNr, 1);
    });
  });
}
