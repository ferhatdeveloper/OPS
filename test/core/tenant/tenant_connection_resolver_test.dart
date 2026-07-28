// Dosya Adı: tenant_connection_resolver_test.dart
// Açıklama: Kiracı kodu → PostgREST URL çözümleme birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_defaults.dart';
import 'package:exfin_ops/core/tenant/tenant_connection_resolver.dart';

void main() {
  group('TenantConnectionResolver', () {
    test('kiracı kodu SaaS PostgREST URL üretir', () {
      final r = TenantConnectionResolver.resolveFromInput('lovan');
      expect(r.tenantCode, 'lovan');
      expect(r.remoteRestUrl, 'https://api.retailex.app/lovan');
      expect(r.schema, PostgrestTenantDefaults.defaultSchema);
      expect(r.source, 'saas_slug');
    });

    test('rewriteRestUrlForSaasOrigin proxy’ye taşır', () {
      final rewritten = TenantConnectionResolver.rewriteRestUrlForSaasOrigin(
        'https://api.retailex.app/lovan',
        saasOrigin: 'http://127.0.0.1:8799',
      );
      expect(rewritten, 'http://127.0.0.1:8799/lovan');
      final same = TenantConnectionResolver.rewriteRestUrlForSaasOrigin(
        'https://api.retailex.app/lovan',
        saasOrigin: 'https://api.retailex.app',
      );
      expect(same, 'https://api.retailex.app/lovan');
    });

    test('doğrudan URL path slug kod olur', () {
      final r = TenantConnectionResolver.resolveFromInput(
        'https://api.retailex.app/aqua/',
      );
      expect(r.tenantCode, 'aqua');
      expect(r.remoteRestUrl, 'https://api.retailex.app/aqua');
      expect(r.source, 'direct_url');
    });

    test('merkez URL reddedilir', () {
      expect(
        () => TenantConnectionResolver.parseTenantConnectionLine(
          'https://api.retailex.app/merkez',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('boş giriş FormatException', () {
      expect(
        () => TenantConnectionResolver.parseTenantConnectionLine('  '),
        throwsA(isA<FormatException>()),
      );
    });

    test('resolveEffectiveRemoteRestUrl kök + kod birleştirir', () {
      final url = TenantConnectionResolver.resolveEffectiveRemoteRestUrl(
        'https://api.retailex.app',
        'lovan',
      );
      expect(url, 'https://api.retailex.app/lovan');
    });

    test('buildMerkezRestBaseUrl merkez path ekler', () {
      expect(
        TenantConnectionResolver.buildMerkezRestBaseUrl(),
        'https://api.retailex.app/merkez',
      );
    });
  });
}
