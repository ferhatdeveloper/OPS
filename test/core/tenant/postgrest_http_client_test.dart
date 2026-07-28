// Dosya Adı: postgrest_http_client_test.dart
// Açıklama: PostgREST HTTP istemci mock testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/core/tenant/postgrest_http_client.dart';
import 'package:exfin_ops/service/postgres_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PostgrestHttpClient', () {
    setUp(() {
      PostgresService.instance.setActiveTenantContext(
        tenantCode: 'lovan',
        remoteRestUrl: 'https://api.retailex.app/lovan',
      );
    });

    test('getRows JSON dizi çözer', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/lovan/users');
        expect(request.headers['Accept-Profile'], 'public');
        return http.Response(
          '[{"username":"admin","is_active":true}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = PostgrestHttpClient(httpClient: mock);
      final rows = await client.getRows(
        '/users',
        query: {'username': 'eq.admin'},
      );
      expect(rows, hasLength(1));
      expect(rows.first['username'], 'admin');
    });

    test('HTTP hata PostgrestHttpException', () async {
      final mock = MockClient(
        (request) async => http.Response(
          '{"message":"boom"}',
          500,
          headers: {'content-type': 'application/json'},
        ),
      );
      final client = PostgrestHttpClient(httpClient: mock);
      expect(
        () => client.getRows('/users'),
        throwsA(isA<PostgrestHttpException>()),
      );
    });
  });
}
