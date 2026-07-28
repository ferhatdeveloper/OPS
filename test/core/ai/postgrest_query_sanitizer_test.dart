// Dosya Adı: postgrest_query_sanitizer_test.dart
// Açıklama: PostgREST query spec sanitize + SQL reddi unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/features/ai_report_proposal_service.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_runner.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_sanitizer.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostgrestQuerySanitizer', () {
    final sanitizer = PostgrestQuerySanitizer();

    test('izinli tablo/kolon geçer', () {
      final r = sanitizer.sanitize(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name', 'balance', 'hacker'],
          filters: [
            PostgrestQueryFilter(
              column: 'is_active',
              op: PostgrestFilterOp.eq,
              value: '1',
            ),
          ],
          order: 'name.asc',
          limit: 50,
        ),
      );
      expect(r.ok, isTrue);
      expect(r.spec!.select, ['code', 'name', 'balance']);
      expect(r.spec!.select.contains('hacker'), isFalse);
      expect(r.spec!.order, 'name.asc');
      expect(r.spec!.limit, 50);
    });

    test('izin dışı tablo reddedilir', () {
      final r = sanitizer.sanitize(
        const PostgrestQuerySpec(
          table: 'users_secrets',
          select: ['password'],
        ),
      );
      expect(r.ok, isFalse);
      expect(r.errorKey, 'field_sales.ai_reports.err_table');
    });

    test('SQL kokusu değerde filtreden düşer', () {
      final r = sanitizer.sanitize(
        const PostgrestQuerySpec(
          table: 'products',
          select: ['code', 'name'],
          filters: [
            PostgrestQueryFilter(
              column: 'name',
              op: PostgrestFilterOp.eq,
              value: "'; DROP TABLE products;--",
            ),
          ],
        ),
      );
      expect(r.ok, isTrue);
      expect(r.spec!.filters, isEmpty);
    });

    test('rpc whitelist boşken reddedilir', () {
      final r = sanitizer.sanitize(
        const PostgrestQuerySpec(
          table: 'dangerous_rpc',
          select: [],
          isRpc: true,
        ),
      );
      expect(r.ok, isFalse);
      expect(r.errorKey, 'field_sales.ai_reports.err_rpc');
    });

    test('limit clamp max 500', () {
      final r = sanitizer.sanitize(
        const PostgrestQuerySpec(
          table: 'orders',
          select: ['id', 'total_amount'],
          limit: 9999,
        ),
      );
      expect(r.ok, isTrue);
      expect(r.spec!.limit, 500);
    });
  });

  group('PostgrestQueryRunner.buildQueryMap', () {
    test('select+filter+order+limit', () {
      final runner = PostgrestQueryRunner();
      final map = runner.buildQueryMap(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name'],
          filters: [
            PostgrestQueryFilter(
              column: 'is_active',
              op: PostgrestFilterOp.eq,
              value: '1',
            ),
          ],
          order: 'code.asc',
          limit: 10,
        ),
      );
      expect(map['select'], 'code,name');
      expect(map['is_active'], 'eq.1');
      expect(map['order'], 'code.asc');
      expect(map['limit'], '10');
    });

    test('buildPath rex firm öneki', () {
      final runner = PostgrestQueryRunner();
      expect(
        runner.buildPath(
          const PostgrestQuerySpec(table: 'customers', select: ['code']),
        ),
        '/rex_001_customers',
      );
    });
  });

  group('AiReportProposalService.tryParseProposalJson', () {
    test('JSON fence parse', () {
      const raw = '''
```json
{"title":"Cari","query":{"table":"customers","select":["code","name"]},"columns":[{"id":"code","labelKey":"code"}]}
```
''';
      final p = AiReportProposalService.tryParseProposalJson(raw);
      expect(p, isNotNull);
      expect(p!.query.table, 'customers');
      expect(p.query.select, ['code', 'name']);
    });

    test('ham SQL benzeri metin reddedilir', () {
      const raw = 'SELECT * FROM customers WHERE 1=1';
      expect(AiReportProposalService.tryParseProposalJson(raw), isNull);
    });
  });
}
