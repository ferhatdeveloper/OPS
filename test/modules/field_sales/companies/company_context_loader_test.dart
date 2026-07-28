// Dosya Adı: company_context_loader_test.dart
// Açıklama: Firma listesi REST önceliği — demo satır yok
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/core/tenant/postgrest_http_client.dart';
import 'package:exfin_ops/core/tenant/postgrest_master_sync.dart';
import 'package:exfin_ops/modules/field_sales/companies/viewmodel/company_context_loader.dart';
import 'package:exfin_ops/service/postgres_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CompanyContextLoader', () {
    setUp(() {
      PostgresService.instance.setActiveTenantContext(
        tenantCode: 'lovan',
        remoteRestUrl: 'https://api.retailex.app/lovan',
      );
    });

    test('REST firms dönünce demo/stub firma yok', () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/firms')) {
          return http.Response(
            '['
            '{"id":"firm-uuid","firm_nr":"3","name":"Tenant Firma",'
            '"is_active":true,"default":true}'
            ']',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/periods')) {
          return http.Response(
            '['
            '{"id":"p1","firm_id":"firm-uuid","nr":1,'
            '"beg_date":"2026-01-01","end_date":"2026-12-31",'
            '"is_active":true,"default":true}'
            ']',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      final loader = CompanyContextLoader(
        restReady: true,
        persistSqlite: false,
        syncFactory: () => PostgrestMasterSync(
          client: PostgrestHttpClient(httpClient: mock),
        ),
        sqliteFallback: () async => (
          firms: [
            const CompanyContextFirm(
              companyId: 'mbt_001',
              name: 'MBT',
              companyNo: '001',
            ),
          ],
          periods: <CompanyContextPeriod>[],
        ),
      );

      final data = await loader.loadFirmsAndPeriods();

      expect(data.fromRest, isTrue);
      expect(data.firms, hasLength(1));
      expect(data.firms.first.name, 'Tenant Firma');
      expect(data.firms.first.companyNo, '003');
      expect(data.firms.any((f) => f.name == 'MBT'), isFalse);
      expect(data.firms.any((f) => f.companyId == 'mbt_001'), isFalse);
      expect(
        data.firms.any((f) => f.name.contains('EXFIN-ERP Demo')),
        isFalse,
      );
      expect(data.periods, hasLength(1));
      expect(data.periods.first.periodNo, '01');
    });

    test('REST aktif ama firms boşsa SQLite demo satırları elenir', () async {
      final mock = MockClient((_) async {
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final loader = CompanyContextLoader(
        restReady: true,
        persistSqlite: false,
        syncFactory: () => PostgrestMasterSync(
          client: PostgrestHttpClient(httpClient: mock),
        ),
        sqliteFallback: () async => (
          firms: [
            const CompanyContextFirm(
              companyId: 'mbt_001',
              name: 'MBT',
              companyNo: '001',
            ),
            const CompanyContextFirm(
              companyId: 'u1',
              name: 'EXFIN-ERP Demo Firma',
              companyNo: '001',
            ),
            const CompanyContextFirm(
              companyId: 'real',
              name: 'Önceden Senkron',
              companyNo: '005',
            ),
          ],
          periods: <CompanyContextPeriod>[],
        ),
      );

      final data = await loader.loadFirmsAndPeriods();

      expect(data.fromRest, isFalse);
      expect(data.firms, hasLength(1));
      expect(data.firms.first.name, 'Önceden Senkron');
      expect(data.firms.any((f) => f.name == 'MBT'), isFalse);
      expect(
        data.firms.any((f) => f.name.contains('EXFIN-ERP Demo')),
        isFalse,
      );
    });

    test('isDemoCompanySeed bilinen mockları işaretler', () {
      expect(
        CompanyContextLoader.isDemoCompanySeed(
          id: 'mbt_001',
          name: 'MBT',
        ),
        isTrue,
      );
      expect(
        CompanyContextLoader.isDemoCompanySeed(
          id: 'x',
          name: 'EXFIN-ERP Demo Firma',
        ),
        isTrue,
      );
      expect(
        CompanyContextLoader.isDemoCompanySeed(
          id: 'uuid',
          name: 'Gerçek Firma',
        ),
        isFalse,
      );
    });
  });
}
