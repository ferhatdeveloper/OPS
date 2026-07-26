// Dosya Adı: postgrest_tenant_registry_probe_test.dart
// Açıklama: Merkez tenant_registry HTTP mock ile probe birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/tenant/postgrest_tenant_defaults.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_service.dart';
import 'package:exfin_ops/core/tenant/tenant_context.dart';
import 'package:exfin_ops/core/tenant/tenant_store.dart';

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
      expect(
        r.context?.remoteRestUrl,
        'https://pg.example.com/lovan',
      );
      expect(captured?.path, endsWith('/merkez/tenant_registry'));
      expect(captured?.queryParameters['code'], 'eq.lovan');
      expect(
        captured?.queryParameters['select'],
        'code,rest_base_url,display_name,is_active',
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
      expect(
        r.context?.remoteRestUrl,
        'https://api.retailex.app/lovan',
      );
    });

    test('boş dizi → SaaS slug', () async {
      final client = MockClient((_) async {
        return http.Response('[]', 200);
      });

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('aqua');

      expect(r.ok, isTrue);
      expect(
        r.context?.remoteRestUrl,
        'https://api.retailex.app/aqua',
      );
    });

    test('HTTP 500 → SaaS slug', () async {
      final client = MockClient((_) async {
        return http.Response('error', 500);
      });

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(
        r.context?.remoteRestUrl,
        'https://api.retailex.app/lovan',
      );
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
      expect(
        r.context?.remoteRestUrl,
        'https://api.retailex.app/lovan',
      );
    });

    test('aynı kod cache → registry çağrılmaz', () async {
      var probeHits = 0;
      final client = MockClient((_) async {
        probeHits++;
        return http.Response(
          '[{"code":"lovan","rest_base_url":"https://pg.example.com/new",'
          '"is_active":true}]',
          200,
        );
      });

      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://cached.example/lovan',
        ),
      );

      final r = await PostgrestTenantService(
        syncPostgres: false,
        httpClient: client,
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(r.context?.remoteRestUrl, 'https://cached.example/lovan');
      expect(probeHits, 0);
    });

    test('httpClient null → probe yok, SaaS', () async {
      final r = await PostgrestTenantService(
        syncPostgres: false,
      ).applyTenantCode('lovan');

      expect(r.ok, isTrue);
      expect(
        r.context?.remoteRestUrl,
        'https://api.retailex.app/lovan',
      );
    });
  });
}
