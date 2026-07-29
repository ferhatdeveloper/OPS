// Dosya Adı: tenant_registry_row_test.dart
// Açıklama: Merkez tenant_registry satır modeli birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/core/tenant/tenant_registry_row.dart';

void main() {
  group('TenantRegistryRow.fromJson', () {
    test('tam merkez satırını tipli modele çevirir', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'lovan',
        'rest_base_url': 'https://pg.example.com/lovan',
        'display_name': 'Lovan',
        'is_active': true,
        'logo_rest_api_url': 'http://logo.example/api/v1',
        'logo_firm_nr': 401,
        'logo_period_nr': 1,
        'logo_db': 'TIGER3',
        'updated_at': '2026-07-29T08:00:00Z',
      });

      expect(row.code, 'lovan');
      expect(row.restBaseUrl, 'https://pg.example.com/lovan');
      expect(row.displayName, 'Lovan');
      expect(row.isActive, isTrue);
      expect(row.logoRestApiUrl, 'http://logo.example/api/v1');
      expect(row.logoFirmNr, 401);
      expect(row.logoPeriodNr, 1);
      expect(row.logoDb, 'TIGER3');
      expect(row.updatedAt, DateTime.utc(2026, 7, 29, 8));
    });

    test('nullable Logo alanlarını kabul eder', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'aqua',
        'rest_base_url': null,
        'display_name': null,
        'is_active': true,
        'logo_rest_api_url': null,
        'logo_firm_nr': null,
        'logo_period_nr': null,
        'logo_db': null,
        'updated_at': null,
      });

      expect(row.restBaseUrl, isNull);
      expect(row.displayName, isNull);
      expect(row.logoRestApiUrl, isNull);
      expect(row.logoFirmNr, isNull);
      expect(row.logoPeriodNr, isNull);
      expect(row.logoDb, isNull);
      expect(row.updatedAt, isNull);
    });

    test('sayısal string firma ve dönemi kabul eder', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'aqua',
        'is_active': true,
        'logo_firm_nr': '401',
        'logo_period_nr': '01',
      });

      expect(row.logoFirmNr, 401);
      expect(row.logoPeriodNr, 1);
    });

    test('pozitif olmayan firma / dönem değerlerini yok sayar', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'aqua',
        'is_active': true,
        'logo_firm_nr': 0,
        'logo_period_nr': -3,
      });

      expect(row.logoFirmNr, isNull);
      expect(row.logoPeriodNr, isNull);
    });

    test('geçersiz updated_at değerini null yapar', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'aqua',
        'is_active': true,
        'updated_at': 'not-a-date',
      });

      expect(row.updatedAt, isNull);
    });

    test('is_active alanı yoksa aktif kabul etmez', () {
      final row = TenantRegistryRow.fromJson({'code': 'aqua'});

      expect(row.isActive, isFalse);
    });

    test('boşluklu metin alanlarını trim eder', () {
      final row = TenantRegistryRow.fromJson({
        'code': '  lovan  ',
        'is_active': true,
        'logo_db': '  TIGER3  ',
        'logo_rest_api_url': '  http://logo.example/api/v1  ',
      });

      expect(row.code, 'lovan');
      expect(row.logoDb, 'TIGER3');
      expect(row.logoRestApiUrl, 'http://logo.example/api/v1');
    });

    test('code boşsa FormatException fırlatır', () {
      expect(
        () => TenantRegistryRow.fromJson({'code': '', 'is_active': true}),
        throwsFormatException,
      );
    });

    test('code yoksa FormatException fırlatır', () {
      expect(
        () => TenantRegistryRow.fromJson({'is_active': true}),
        throwsFormatException,
      );
    });

    test('secret benzeri ekstra kolonları modele taşımaz', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'lovan',
        'is_active': true,
        'api_key': 'gizli-anahtar',
        'password': 'gizli-parola',
        'client_secret': 'gizli-client',
      });

      expect(row.toString(), isNot(contains('gizli-anahtar')));
      expect(row.toString(), isNot(contains('gizli-parola')));
      expect(row.toString(), isNot(contains('gizli-client')));
    });
  });
}
