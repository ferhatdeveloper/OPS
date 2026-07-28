// Dosya Adı: postgrest_fetch_firms_test.dart
// Açıklama: /firms mock HTTP — demo firma üretilmemeli
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/core/tenant/postgrest_http_client.dart';
import 'package:exfin_ops/core/tenant/postgrest_master_sync.dart';
import 'package:exfin_ops/service/postgres_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PostgrestMasterSync.fetchFirms', () {
    setUp(() {
      PostgresService.instance.setActiveTenantContext(
        tenantCode: 'lovan',
        remoteRestUrl: 'https://api.retailex.app/lovan',
      );
    });

    test('API satırları gelir; EXFIN-ERP Demo / MBT üretilmez', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/lovan/firms');
        return http.Response(
          '['
          '{"id":"uuid-real","firm_nr":"2","name":"Lovan Gıda",'
          '"is_active":true,"default":true}'
          ']',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sync = PostgrestMasterSync(
        client: PostgrestHttpClient(httpClient: mock),
      );
      final firms = await sync.fetchFirms();

      expect(firms, hasLength(1));
      expect(firms.first.name, 'Lovan Gıda');
      expect(firms.first.firmNr, '002');
      expect(
        firms.any((f) => f.name.contains('EXFIN-ERP Demo')),
        isFalse,
      );
      expect(firms.any((f) => f.name == 'MBT'), isFalse);
      expect(firms.any((f) => f.id == 'mbt_001'), isFalse);
    });

    test('preferFirmNr yalnızca /firms boşken sentetik ekler', () async {
      final mock = MockClient((request) async {
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sync = PostgrestMasterSync(
        client: PostgrestHttpClient(httpClient: mock),
      );
      final firms = await sync.fetchFirms(preferFirmNr: '7');

      expect(firms, hasLength(1));
      expect(firms.first.firmNr, '007');
      expect(firms.first.name, 'Firma 007');
      expect(firms.first.id, 'firm_007');
    });

    test('API doluyken preferFirmNr demo adı eklemez', () async {
      final mock = MockClient((request) async {
        return http.Response(
          '['
          '{"id":"a","firm_nr":"1","name":"Ana Firma",'
          '"is_active":true,"default":false}'
          ']',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sync = PostgrestMasterSync(
        client: PostgrestHttpClient(httpClient: mock),
      );
      final firms = await sync.fetchFirms(preferFirmNr: '1');

      expect(firms, hasLength(1));
      expect(firms.first.name, 'Ana Firma');
      expect(
        firms.any((f) => f.name.contains('Demo')),
        isFalse,
      );
    });
  });
}
