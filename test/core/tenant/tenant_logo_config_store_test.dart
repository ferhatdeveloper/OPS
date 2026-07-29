// Dosya Adı: tenant_logo_config_store_test.dart
// Açıklama: Tenant'a bağlı Logo registry cache birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/tenant/tenant_logo_config_cache.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_store.dart';
import 'package:exfin_ops/core/tenant/tenant_registry_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TenantLogoConfigCache', () {
    test('registry satırından cache üretir ve kodu normalize eder', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'LOVAN',
        'is_active': true,
        'logo_rest_api_url': 'http://logo.example/api/v1',
        'logo_firm_nr': 401,
        'logo_period_nr': 2,
        'logo_db': 'TIGER3',
        'updated_at': '2026-07-29T08:00:00Z',
      });

      final cache = TenantLogoConfigCache.fromRegistry(
        row,
        fetchedAt: DateTime.utc(2026, 7, 29, 9),
      );

      expect(cache.tenantCode, 'lovan');
      expect(cache.logoRestApiUrl, 'http://logo.example/api/v1');
      expect(cache.logoFirmNr, 401);
      expect(cache.logoPeriodNr, 2);
      expect(cache.logoDb, 'TIGER3');
      expect(cache.registryUpdatedAt, DateTime.utc(2026, 7, 29, 8));
      expect(cache.fetchedAt, DateTime.utc(2026, 7, 29, 9));
    });

    test('JSON round-trip alan kaybı yaşatmaz', () {
      final cache = TenantLogoConfigCache(
        tenantCode: 'lovan',
        logoRestApiUrl: 'http://logo.example/api/v1',
        logoFirmNr: 401,
        logoPeriodNr: 2,
        logoDb: 'TIGER3',
        registryUpdatedAt: DateTime.utc(2026, 7, 29, 8),
        fetchedAt: DateTime.utc(2026, 7, 29, 9),
      );

      final restored = TenantLogoConfigCache.fromJson(
        jsonDecode(jsonEncode(cache.toJson())) as Map<String, dynamic>,
      );

      expect(restored.tenantCode, cache.tenantCode);
      expect(restored.logoRestApiUrl, cache.logoRestApiUrl);
      expect(restored.logoFirmNr, cache.logoFirmNr);
      expect(restored.logoPeriodNr, cache.logoPeriodNr);
      expect(restored.logoDb, cache.logoDb);
      expect(restored.registryUpdatedAt, cache.registryUpdatedAt);
      expect(restored.fetchedAt, cache.fetchedAt);
    });

    test('fetched_at yoksa FormatException fırlatır', () {
      expect(
        () => TenantLogoConfigCache.fromJson({'tenant_code': 'lovan'}),
        throwsFormatException,
      );
    });

    test('sayısal string firma/dönem değerlerini güvenle okur', () {
      final restored = TenantLogoConfigCache.fromJson({
        'tenant_code': 'lovan',
        'logo_firm_nr': '401',
        'logo_period_nr': '2',
        'fetched_at': '2026-07-29T09:00:00Z',
      });

      expect(restored.logoFirmNr, 401);
      expect(restored.logoPeriodNr, 2);
    });

    test('isFresh TTL süresine göre tazelik hesaplar', () {
      final cache = TenantLogoConfigCache(
        tenantCode: 'lovan',
        fetchedAt: DateTime.utc(2026, 7, 29, 9),
      );

      expect(
        cache.isFresh(
          now: DateTime.utc(2026, 7, 29, 9, 10),
          ttl: const Duration(minutes: 15),
        ),
        isTrue,
      );
      expect(
        cache.isFresh(
          now: DateTime.utc(2026, 7, 29, 9, 20),
          ttl: const Duration(minutes: 15),
        ),
        isFalse,
      );
    });

    test('gelecek tarihli fetchedAt tazelik hesabını bozmaz', () {
      final cache = TenantLogoConfigCache(
        tenantCode: 'lovan',
        fetchedAt: DateTime.utc(2026, 7, 29, 12),
      );

      expect(
        cache.isFresh(
          now: DateTime.utc(2026, 7, 29, 9),
          ttl: const Duration(minutes: 15),
        ),
        isFalse,
      );
    });

    test('hasLogoConfig yalnızca URL doluyken true döner', () {
      final withUrl = TenantLogoConfigCache(
        tenantCode: 'lovan',
        logoRestApiUrl: 'http://logo.example/api/v1',
        fetchedAt: DateTime.utc(2026, 7, 29),
      );
      final withoutUrl = TenantLogoConfigCache(
        tenantCode: 'lovan',
        fetchedAt: DateTime.utc(2026, 7, 29),
      );

      expect(withUrl.hasLogoConfig, isTrue);
      expect(withoutUrl.hasLogoConfig, isFalse);
    });
  });

  group('TenantLogoConfigStore', () {
    test('Logo cache tüm kesin registry alanlarını round-trip eder', () async {
      const store = TenantLogoConfigStore();
      final cache = TenantLogoConfigCache(
        tenantCode: 'lovan',
        logoRestApiUrl: 'http://logo.example/api/v1',
        logoFirmNr: 401,
        logoPeriodNr: 1,
        logoDb: 'TIGER3',
        registryUpdatedAt: DateTime.utc(2026, 7, 29, 8),
        fetchedAt: DateTime.utc(2026, 7, 29, 9),
      );

      await store.save(cache);
      final loaded = await store.loadForTenant('LOVAN');

      expect(loaded?.logoRestApiUrl, 'http://logo.example/api/v1');
      expect(loaded?.logoFirmNr, 401);
      expect(loaded?.logoPeriodNr, 1);
      expect(loaded?.logoDb, 'TIGER3');
      expect(loaded?.registryUpdatedAt, cache.registryUpdatedAt);
      expect(loaded?.fetchedAt, cache.fetchedAt);
    });

    test('başka tenant cache kaydını okuyamaz', () async {
      const store = TenantLogoConfigStore();
      await store.save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          fetchedAt: DateTime.utc(2026, 7, 29),
        ),
      );

      expect(await store.loadForTenant('aqua'), isNull);
    });

    test('kayıt yoksa null döner', () async {
      const store = TenantLogoConfigStore();

      expect(await store.loadForTenant('lovan'), isNull);
    });

    test('boş kiracı kodunda null döner', () async {
      const store = TenantLogoConfigStore();
      await store.save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          fetchedAt: DateTime.utc(2026, 7, 29),
        ),
      );

      expect(await store.loadForTenant('  '), isNull);
    });

    test('bozuk JSON okumada hata fırlatmaz', () async {
      SharedPreferences.setMockInitialValues({
        TenantLogoConfigStore.prefsCache: '{ bozuk',
      });

      expect(
        await const TenantLogoConfigStore().loadForTenant('lovan'),
        isNull,
      );
    });

    test('eksik fetched_at içeren kayıt null döner', () async {
      SharedPreferences.setMockInitialValues({
        TenantLogoConfigStore.prefsCache: jsonEncode({
          'tenant_code': 'lovan',
          'logo_firm_nr': 401,
        }),
      });

      expect(
        await const TenantLogoConfigStore().loadForTenant('lovan'),
        isNull,
      );
    });

    test('yeni kayıt önceki tenant cachein üzerine yazar', () async {
      const store = TenantLogoConfigStore();
      await store.save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoFirmNr: 401,
          fetchedAt: DateTime.utc(2026, 7, 29),
        ),
      );
      await store.save(
        TenantLogoConfigCache(
          tenantCode: 'aqua',
          logoFirmNr: 7,
          fetchedAt: DateTime.utc(2026, 7, 29),
        ),
      );

      expect(await store.loadForTenant('lovan'), isNull);
      expect((await store.loadForTenant('aqua'))?.logoFirmNr, 7);
    });

    test('clear kaydı siler', () async {
      const store = TenantLogoConfigStore();
      await store.save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          fetchedAt: DateTime.utc(2026, 7, 29),
        ),
      );

      await store.clear();

      expect(await store.loadForTenant('lovan'), isNull);
    });

    test('kaydedilen JSON secret alan taşımaz', () async {
      const store = TenantLogoConfigStore();
      await store.save(
        TenantLogoConfigCache(
          tenantCode: 'lovan',
          logoRestApiUrl: 'http://logo.example/api/v1',
          logoFirmNr: 401,
          fetchedAt: DateTime.utc(2026, 7, 29),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(TenantLogoConfigStore.prefsCache) ?? '';

      expect(raw, isNot(contains('api_key')));
      expect(raw, isNot(contains('password')));
      expect(raw, isNot(contains('client_secret')));
      expect(raw, isNot(contains('access_token')));
    });
  });
}
