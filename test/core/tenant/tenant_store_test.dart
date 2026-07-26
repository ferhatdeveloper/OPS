// Dosya Adı: tenant_store_test.dart
// Açıklama: Kiracı bağlamı SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/core/tenant/tenant_context.dart';
import 'package:exfin_ops/core/tenant/tenant_store.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_defaults.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TenantStore.resetMemory();
  });

  group('TenantStore', () {
    test('boş prefs yüklenince empty döner', () async {
      const store = TenantStore();
      final ctx = await store.load();
      expect(ctx.isEmpty, isTrue);
      expect(TenantStore.current, isNull);
    });

    test('kaydet ve yükle kiracı alanlarını korur', () async {
      const store = TenantStore();
      final ctx = TenantContext(
        tenantCode: 'lovan',
        remoteRestUrl: 'https://api.retailex.app/lovan',
        schema: 'public',
        displayName: 'Lovan',
      );

      await store.save(ctx);
      expect(TenantStore.current?.tenantCode, 'lovan');

      TenantStore.resetMemory();
      final loaded = await store.load();
      expect(loaded.tenantCode, 'lovan');
      expect(loaded.remoteRestUrl, 'https://api.retailex.app/lovan');
      expect(loaded.schema, 'public');
      expect(loaded.displayName, 'Lovan');
      expect(TenantStore.current?.tenantCode, 'lovan');
    });

    test('clear prefs ve belleği sıfırlar', () async {
      const store = TenantStore();
      await store.save(
        const TenantContext(
          tenantCode: 'aqua',
          remoteRestUrl: 'https://api.retailex.app/aqua',
        ),
      );
      await store.clear();
      expect(TenantStore.current, isNull);
      final loaded = await store.load();
      expect(loaded.isEmpty, isTrue);
    });
    test('SaaS origin override kaydedilir ve yüklenir', () async {
      const store = TenantStore();
      expect(await store.hasSaasOriginOverride(), isFalse);
      expect(
        await store.loadSaasOrigin(),
        PostgrestTenantDefaults.saasOrigin,
      );

      await store.saveSaasOrigin('https://api.staging.example/');
      expect(await store.hasSaasOriginOverride(), isTrue);
      expect(await store.loadSaasOriginOverride(), 'https://api.staging.example');
      expect(await store.loadSaasOrigin(), 'https://api.staging.example');

      await store.saveSaasOrigin('');
      expect(await store.hasSaasOriginOverride(), isFalse);
      expect(
        await store.loadSaasOrigin(),
        PostgrestTenantDefaults.saasOrigin,
      );
    });

    test('origin değişince kayıtlı remoteRestUrl temizlenir', () async {
      const store = TenantStore();
      await store.save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://api.retailex.app/lovan',
        ),
      );
      await store.saveSaasOrigin('https://api.dev.example');
      final loaded = await store.load();
      expect(loaded.tenantCode, 'lovan');
      expect(loaded.remoteRestUrl, isEmpty);
      expect(TenantStore.current, isNull);
    });
  });

  group('PostgrestTenantService', () {
    test('kod → SaaS URL uygular (Postgres sync kapalı)', () async {
      final svc = PostgrestTenantService(syncPostgres: false);
      final r = await svc.applyTenantCode('lovan');
      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.retailex.app/lovan');
      expect(r.usedOfflineCache, isFalse);

      final loaded = await const TenantStore().load();
      expect(loaded.tenantCode, 'lovan');
    });

    test('override origin ile URL üretir', () async {
      const store = TenantStore();
      await store.saveSaasOrigin('https://api.dev.example');
      final svc = PostgrestTenantService(syncPostgres: false, store: store);
      final r = await svc.applyTenantCode('aqua');
      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.dev.example/aqua');
    });

    test('boş giriş + kayıt yok → tenant_required', () async {
      final svc = PostgrestTenantService(syncPostgres: false);
      final r = await svc.applyTenantCode('');
      expect(r.ok, isFalse);
      expect(r.errorKey, 'auth.tenant_required');
    });

    test('boş giriş + kayıtlı kiracı → offline last', () async {
      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://api.retailex.app/lovan',
        ),
      );
      final svc = PostgrestTenantService(syncPostgres: false);
      final r = await svc.applyTenantCode('');
      expect(r.ok, isTrue);
      expect(r.usedOfflineCache, isTrue);
      expect(r.context?.tenantCode, 'lovan');
    });
  });
}
