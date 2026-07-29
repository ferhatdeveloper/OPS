// Dosya Adı: tenant_logo_config_fetcher_test.dart
// Açıklama: "Kiracı kodundan çek" aksiyonunun servis katmanı testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/tenant/tenant_logo_config_cache.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_fetcher.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_store.dart';
import 'package:exfin_ops/core/tenant/tenant_store.dart';

const String _row = '[{"code":"lovan",'
    '"rest_base_url":"https://pg.example.com/lovan",'
    '"display_name":"Lovan","is_active":true,'
    '"logo_rest_api_url":"http://logo.example:32001/api/v1",'
    '"logo_firm_nr":401,"logo_period_nr":2,'
    '"logo_db":"TIGER3","updated_at":"2026-07-29T08:00:00Z"}]';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      TenantStore.prefsTenantCode: 'LOVAN',
    });
    TenantStore.resetMemory();
  });

  TenantLogoConfigFetcher buildFetcher(http.Client client) {
    return TenantLogoConfigFetcher(
      client: client,
      now: () => DateTime.utc(2026, 7, 29, 9),
    );
  }

  test('kiracı kodu yoksa hata anahtarı döner ve istek atılmaz', () async {
    SharedPreferences.setMockInitialValues({});
    TenantStore.resetMemory();
    var calls = 0;
    final fetcher = buildFetcher(
      MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      }),
    );

    final outcome = await fetcher.fetchForActiveTenant();

    expect(calls, 0);
    expect(outcome.ok, isFalse);
    expect(outcome.errorKey, 'field_sales.logo_registry_no_tenant');
  });

  test('aktif kiracı kodu normalize edilerek sorgulanır', () async {
    late Uri requested;
    final fetcher = buildFetcher(
      MockClient((request) async {
        requested = request.url;
        return http.Response(_row, 200);
      }),
    );

    final outcome = await fetcher.fetchForActiveTenant();

    expect(requested.queryParameters['code'], 'eq.lovan');
    expect(outcome.ok, isTrue);
    expect(outcome.cache!.tenantCode, 'lovan');
    expect(outcome.cache!.logoFirmNr, 401);
    expect(outcome.cache!.logoPeriodNr, 2);
    expect(outcome.cache!.logoDb, 'TIGER3');
    expect(outcome.fromCache, isFalse);
  });

  test('başarılı çekim yerel cache olarak kalıcılaşır', () async {
    final fetcher = buildFetcher(MockClient((_) async => http.Response(_row, 200)));

    await fetcher.fetchForActiveTenant();

    final stored = await const TenantLogoConfigStore().loadForTenant('lovan');
    expect(stored, isNotNull);
    expect(stored!.logoRestApiUrl, 'http://logo.example:32001/api/v1');
  });

  test('cache kaydı hiçbir secret alan taşımaz', () async {
    final fetcher = buildFetcher(MockClient((_) async => http.Response(_row, 200)));

    final outcome = await fetcher.fetchForActiveTenant();

    expect(
      outcome.cache!.toJson().keys.toSet(),
      {
        'tenant_code',
        'logo_rest_api_url',
        'logo_firm_nr',
        'logo_period_nr',
        'logo_db',
        'updated_at',
        'fetched_at',
      },
    );
  });

  test('merkez ulaşılamazsa son yerel cache kullanılır', () async {
    await const TenantLogoConfigStore().save(
      TenantLogoConfigCache(
        tenantCode: 'lovan',
        logoRestApiUrl: 'http://eski.example:32001/api/v1',
        logoFirmNr: 9,
        logoPeriodNr: 1,
        fetchedAt: DateTime.utc(2026, 7, 28),
      ),
    );
    final fetcher = buildFetcher(
      MockClient((_) async => http.Response('sunucu hatası', 500)),
    );

    final outcome = await fetcher.fetchForActiveTenant();

    expect(outcome.ok, isTrue);
    expect(outcome.fromCache, isTrue);
    expect(outcome.cache!.logoFirmNr, 9);
  });

  test('merkez de cache de yoksa bulunamadı hatası döner', () async {
    final fetcher = buildFetcher(MockClient((_) async => http.Response('[]', 200)));

    final outcome = await fetcher.fetchForActiveTenant();

    expect(outcome.ok, isFalse);
    expect(outcome.errorKey, 'field_sales.logo_registry_not_found');
  });

  test('Logo alanı boş satır bulunamadı sayılır', () async {
    final fetcher = buildFetcher(
      MockClient(
        (_) async => http.Response(
          '[{"code":"lovan","is_active":true,'
          '"rest_base_url":"https://pg.example.com/lovan"}]',
          200,
        ),
      ),
    );

    final outcome = await fetcher.fetchForActiveTenant();

    expect(outcome.ok, isFalse);
    expect(outcome.errorKey, 'field_sales.logo_registry_not_found');
  });

  test('açık kiracı kodu parametresi prefs değerini geçersiz kılar', () async {
    late Uri requested;
    final fetcher = buildFetcher(
      MockClient((request) async {
        requested = request.url;
        return http.Response(_row, 200);
      }),
    );

    await fetcher.fetchForActiveTenant(tenantCode: ' Baska ');

    expect(requested.queryParameters['code'], 'eq.baska');
  });
}
