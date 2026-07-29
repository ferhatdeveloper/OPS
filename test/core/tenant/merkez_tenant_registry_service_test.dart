// Dosya Adı: merkez_tenant_registry_service_test.dart
// Açıklama: Merkez tenant_registry HTTP servisi birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:exfin_ops/core/tenant/merkez_tenant_registry_service.dart';
import 'package:exfin_ops/core/tenant/postgrest_tenant_defaults.dart';

const String _origin = 'https://api.retailex.app';

const String _fullRow = '[{"code":"lovan",'
    '"rest_base_url":"https://pg.example.com/lovan",'
    '"display_name":"Lovan","is_active":true,'
    '"logo_rest_api_url":"http://logo.example/api/v1",'
    '"logo_firm_nr":401,"logo_period_nr":1,'
    '"logo_db":"TIGER3","updated_at":"2026-07-29T08:00:00Z"}]';

void main() {
  group('MerkezTenantRegistryService.fetch', () {
    test('kiracı koduyla kesin kolonları ve limit 1 ister', () async {
      late http.BaseRequest captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(_fullRow, 200);
      });

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(captured.url.path, '/merkez/tenant_registry');
      expect(captured.url.queryParameters['code'], 'eq.lovan');
      expect(captured.url.queryParameters['limit'], '1');
      expect(
        captured.url.queryParameters['select'],
        MerkezTenantRegistryService.selectColumns,
      );
      expect(captured.headers['Accept'], 'application/json');
      expect(
        captured.headers['Accept-Profile'],
        PostgrestTenantDefaults.defaultSchema,
      );
      expect(row?.code, 'lovan');
      expect(row?.restBaseUrl, 'https://pg.example.com/lovan');
      expect(row?.logoRestApiUrl, 'http://logo.example/api/v1');
      expect(row?.logoFirmNr, 401);
      expect(row?.logoPeriodNr, 1);
      expect(row?.logoDb, 'TIGER3');
      expect(row?.updatedAt, DateTime.utc(2026, 7, 29, 8));
    });

    test('select kolonları tam olarak tasarımdaki listedir', () {
      expect(
        MerkezTenantRegistryService.selectColumns,
        'code,rest_base_url,display_name,is_active,'
        'logo_rest_api_url,logo_firm_nr,logo_period_nr,logo_db,updated_at',
      );
    });

    test('kiracı kodunu normalize eder ve URI encode ile gönderir', () async {
      late http.BaseRequest captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      });

      await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: '  LOVAN&limit=99  ',
        saasOrigin: _origin,
      );

      expect(captured.url.queryParameters['code'], 'eq.lovan&limit=99');
      expect(captured.url.queryParameters['limit'], '1');
      expect(captured.url.query, contains('eq.lovan%26limit%3D99'));
    });

    test('boş kiracı kodunda HTTP isteği yapmaz', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(_fullRow, 200);
      });

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: '   ',
        saasOrigin: _origin,
      );

      expect(row, isNull);
      expect(calls, 0);
    });

    test('inactive satırı uygulanabilir sonuç olarak döndürmez', () async {
      final client = MockClient(
        (_) async => http.Response('[{"code":"lovan","is_active":false}]', 200),
      );

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('boş dizi → null', () async {
      final client = MockClient((_) async => http.Response('[]', 200));

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('HTTP 500 → null (hata fırlatmaz)', () async {
      final client = MockClient((_) async => http.Response('error', 500));

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('HTTP 404 → null', () async {
      final client = MockClient((_) async => http.Response('[]', 404));

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('malformed JSON → null', () async {
      final client = MockClient(
        (_) async => http.Response('{ bozuk json', 200),
      );

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('dizi olmayan JSON gövdesi → null', () async {
      final client = MockClient(
        (_) async => http.Response('{"code":"lovan","is_active":true}', 200),
      );

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('code kolonu boş satır → null', () async {
      final client = MockClient(
        (_) async => http.Response('[{"code":"","is_active":true}]', 200),
      );

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('timeout → null', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response(_fullRow, 200);
      });

      final row = await MerkezTenantRegistryService(
        client: client,
        timeout: const Duration(milliseconds: 20),
      ).fetch(tenantCode: 'lovan', saasOrigin: _origin);

      expect(row, isNull);
    });

    test('ağ hatası → null', () async {
      final client = MockClient((_) async {
        throw const SocketExceptionStub();
      });

      final row = await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: _origin,
      );

      expect(row, isNull);
    });

    test('SaaS kökü override edildiğinde merkez yolu o köke bağlanır',
        () async {
      late http.BaseRequest captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      });

      await MerkezTenantRegistryService(client: client).fetch(
        tenantCode: 'lovan',
        saasOrigin: 'http://127.0.0.1:8799',
      );

      expect(captured.url.origin, 'http://127.0.0.1:8799');
      expect(captured.url.path, '/merkez/tenant_registry');
    });
  });
}

/// {@template socket_exception_stub}
/// Ağ hatası simülasyonu (dart:io bağımlılığı olmadan).
/// {@endtemplate}
class SocketExceptionStub implements Exception {
  /// {@macro socket_exception_stub}
  const SocketExceptionStub();

  @override
  String toString() => 'SocketExceptionStub';
}
