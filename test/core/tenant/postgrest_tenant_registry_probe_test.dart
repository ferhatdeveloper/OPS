// Dosya Adı: postgrest_tenant_registry_probe_test.dart
// Açıklama: Merkez tenant_registry HTTP mock ile probe ve Logo bootstrap testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:exfin_ops/core/tenant/merkez_tenant_registry_service.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_defaults.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_service.dart';
import 'package:exfin_ops/core/tenant/tenant_context.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_cache.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_store.dart';
import 'package:exfin_ops/core/tenant/tenant_store.dart';
import 'package:exfin_ops/modules/field_sales/companies/model/active_company_session.dart';
import 'package:exfin_ops/modules/field_sales/companies/viewmodel/active_company_store.dart';

const String _logoRow = '[{"code":"lovan",'
    '"rest_base_url":"https://pg.example.com/lovan",'
    '"display_name":"Lovan","is_active":true,'
    '"logo_rest_api_url":"http://logo.example:32001/api/v1",'
    '"logo_firm_nr":401,"logo_period_nr":1,'
    '"logo_db":"TIGER3","updated_at":"2026-07-29T08:00:00Z"}]';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TenantStore.resetMemory();
  });

  group('PostgrestTenantService registry probe (HTTP mock)', () {
    test('registry rest_base_url → özel URL uygular', () async {
      // Given
      Uri? captured;
      Map<String, String>? capturedHeaders;
      final client = MockClient((request) async {
        captured = request.url;
        capturedHeaders = request.headers;
        return http.Response(
          '[{"code":"lovan","rest_base_url":"https://pg.example.com/lovan",'
          '"display_name":"Lovan","is_active":true}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final svc = PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      );

      // When
      final r = await svc.applyTenantCode('lovan');

      // Then
      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://pg.example.com/lovan');
      expect(captured?.path, endsWith('/merkez/tenant_registry'));
      expect(captured?.queryParameters['code'], 'eq.lovan');
      expect(captured?.queryParameters['limit'], '1');
      expect(
        captured?.queryParameters['select'],
        MerkezTenantRegistryService.selectColumns,
      );
      expect(
        capturedHeaders?['Accept-Profile'],
        PostgrestTenantDefaults.defaultSchema,
      );
    });

    test('is_active false → SaaS slug kalır', () async {
      final client = MockClient((_) async {
        return http.Response(
          '[{"code":"lovan","rest_base_url":"https://pg.example.com/lovan",'
          '"is_active":false}]',
          200,
        );
      });

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.retailex.app/lovan');
    });

    test('boş dizi → SaaS slug', () async {
      final client = MockClient((_) async => http.Response('[]', 200));

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('aqua');

      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.retailex.app/aqua');
    });

    test('HTTP 500 → SaaS slug', () async {
      final client = MockClient((_) async => http.Response('error', 500));

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.retailex.app/lovan');
    });

    test('timeout → SaaS slug (probe atlanır)', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response(
          '[{"code":"lovan","rest_base_url":"https://pg.example.com/x",'
          '"is_active":true}]',
          200,
        );
      });

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
        registryTimeout: const Duration(milliseconds: 20),
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.retailex.app/lovan');
    });

    test('httpClient null → probe yok, SaaS', () async {
      final r = await PostgrestTenantService(
        syncPostgres: false,
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://api.retailex.app/lovan');
    });
  });

  group('PostgrestTenantService Logo registry bootstrap', () {
    test('registry Logo alanlarını cache ve Tiger storea seed eder', () async {
      final client = MockClient((_) async => http.Response(_logoRow, 200));

      final result = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(result.ok, isTrue);
      final cache = await const TenantLogoConfigStore().loadForTenant('lovan');
      expect(cache?.logoRestApiUrl, 'http://logo.example:32001/api/v1');
      expect(cache?.logoFirmNr, 401);
      expect(cache?.logoPeriodNr, 1);
      expect(cache?.logoDb, 'TIGER3');
      expect(cache?.registryUpdatedAt, DateTime.utc(2026, 7, 29, 8));

      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.normalizedBaseUrl, 'http://logo.example:32001/api/v1');
      expect(tiger.firmNr, 401);
      expect(tiger.periodNr, 1);
      expect(tiger.logoDb, 'TIGER3');
    });

    test('cached remote URL Logo registry fetchini atlatmaz', () async {
      var calls = 0;
      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://cached.example/lovan',
        ),
      );
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          '[{"code":"lovan","is_active":true,'
          '"logo_rest_api_url":"http://logo.example:32001/api/v1",'
          '"logo_firm_nr":401,"logo_period_nr":1}]',
          200,
        );
      });

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(calls, 1);
      // Registry rest_base_url yok → mevcut cached URL korunur.
      expect(r.context?.remoteRestUrl, 'https://cached.example/lovan');
      expect((await LogoTigerSettingsStore().loadRaw()).firmNr, 401);
    });

    test('registry rest_base_url cached URLden önceliklidir', () async {
      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://cached.example/lovan',
        ),
      );
      final client = MockClient((_) async => http.Response(_logoRow, 200));

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(r.context?.remoteRestUrl, 'https://pg.example.com/lovan');
    });

    test('taze Logo cache → registry çağrılmaz', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(_logoRow, 200);
      });
      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://cached.example/lovan',
        ),
      );
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://cachedlogo.example:32001/api/v1',
          logoFirmNr: 77,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
        now: () => DateTime.utc(2026, 7, 29, 9, 5),
      ).applyTenantCode('lovan');

      expect(calls, 0);
      expect(r.context?.remoteRestUrl, 'https://cached.example/lovan');
      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.normalizedBaseUrl, 'http://cachedlogo.example:32001/api/v1');
      expect(tiger.firmNr, 77);
    });

    test('TTL dolduğunda registry yeniden çağrılır', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(_logoRow, 200);
      });
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://cachedlogo.example:32001/api/v1',
          logoFirmNr: 77,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
        now: () => DateTime.utc(2026, 7, 29, 9, 30),
      ).applyTenantCode('lovan');

      expect(calls, 1);
      expect((await LogoTigerSettingsStore().loadRaw()).firmNr, 401);
    });

    test('yenileme hatasında son geçerli Logo cache korunur', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://cachedlogo.example:32001/api/v1',
          logoFirmNr: 77,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
        now: () => DateTime.utc(2026, 7, 29, 9, 30),
      ).applyTenantCode('lovan');

      final cache = await const TenantLogoConfigStore().loadForTenant('lovan');
      expect(cache?.logoFirmNr, 77);
      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.normalizedBaseUrl, 'http://cachedlogo.example:32001/api/v1');
      expect(tiger.firmNr, 77);
    });

    test('httpClient yokken mevcut Logo cache uygulanır', () async {
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://cachedlogo.example:32001/api/v1',
          logoFirmNr: 77,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      await PostgrestTenantService(
        syncPostgres: false,
        now: () => DateTime.utc(2027, 1, 1),
      ).applyTenantCode('lovan');

      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.normalizedBaseUrl, 'http://cachedlogo.example:32001/api/v1');
      expect(tiger.firmNr, 77);
    });

    test('başka tenantın Logo cachei aktif tenanta uygulanmaz', () async {
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://lovanlogo.example:32001/api/v1',
          logoFirmNr: 401,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      await PostgrestTenantService(
        syncPostgres: false,
        now: () => DateTime.utc(2026, 7, 29, 9, 5),
      ).applyTenantCode('aqua');

      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.baseUrl, isEmpty);
      expect(tiger.firmNr, 1);
      expect(await const TenantLogoConfigStore().loadForTenant('aqua'), isNull);
    });

    test('manuel Logo ayarı registry seed tarafından ezilmez', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(
          baseUrl: 'http://manual.example:32001/api/v1',
          apiKey: 'manual-secret',
          firmNr: 999,
        ),
      );
      final client = MockClient((_) async => http.Response(_logoRow, 200));

      await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      final tiger = await store.loadRaw();
      expect(tiger.normalizedBaseUrl, 'http://manual.example:32001/api/v1');
      expect(tiger.firmNr, 999);
      expect(tiger.apiKey, 'manual-secret');
      // Cache yine de yazılır; yalnızca seed atlanır.
      final cache = await const TenantLogoConfigStore().loadForTenant('lovan');
      expect(cache?.logoFirmNr, 401);
    });

    test('is_active false Logo storeu değiştirmez', () async {
      final client = MockClient(
        (_) async => http.Response(
          '[{"code":"lovan","is_active":false,'
          '"logo_rest_api_url":"http://logo.example:32001/api/v1",'
          '"logo_firm_nr":401}]',
          200,
        ),
      );

      await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.baseUrl, isEmpty);
      expect(tiger.firmNr, 1);
      expect(
        await const TenantLogoConfigStore().loadForTenant('lovan'),
        isNull,
      );
    });

    test('registry yanıtındaki secret benzeri kolonlar saklanmaz', () async {
      final client = MockClient(
        (_) async => http.Response(
          '[{"code":"lovan","is_active":true,'
          '"logo_rest_api_url":"http://logo.example:32001/api/v1",'
          '"api_key":"gizli-anahtar","password":"gizli-parola",'
          '"client_secret":"gizli-client"}]',
          200,
        ),
      );

      await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(TenantLogoConfigStore.prefsCache) ?? '';
      expect(raw, isNot(contains('gizli-anahtar')));
      expect(raw, isNot(contains('gizli-parola')));
      expect(raw, isNot(contains('gizli-client')));

      final tiger = await LogoTigerSettingsStore().loadRaw();
      expect(tiger.apiKey, isEmpty);
      expect(tiger.password, isEmpty);
      expect(tiger.clientSecret, isEmpty);
    });
  });

  group('PostgrestTenantService firma / dönem sınırları', () {
    test('registry seed aktif firma/dönem seçimini değiştirmez', () async {
      const companyStore = ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      );
      await companyStore.save(
        const ActiveCompanySession(
          companyId: 'c-12',
          companyName: 'Kullanıcı Firması',
          companyNo: '12',
          periodNo: '5',
        ),
      );
      final client = MockClient((_) async => http.Response(_logoRow, 200));

      await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');
      final session = await companyStore.load();

      // Registry yalnızca bootstrap varsayılanı verir.
      expect(session.companyNo, '12');
      expect(session.periodNo, '5');
      expect((await LogoTigerSettingsStore().loadRaw()).firmNr, 401);
    });

    test('offline restore aktif firma/dönem seçimini değiştirmez', () async {
      const companyStore = ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      );
      await companyStore.save(
        const ActiveCompanySession(
          companyId: 'c-12',
          companyName: 'Kullanıcı Firması',
          companyNo: '12',
          periodNo: '5',
        ),
      );
      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://api.retailex.app/lovan',
        ),
      );
      await const TenantLogoConfigStore().save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://logo.example:32001/api/v1',
          logoFirmNr: 401,
          logoPeriodNr: 1,
          fetchedAt: DateTime.utc(2026, 7, 29, 9),
        ),
      );

      await PostgrestTenantService(syncPostgres: false).restoreActiveContext();
      final session = await companyStore.load();

      expect(session.companyNo, '12');
      expect(session.periodNo, '5');
    });
  });
}
