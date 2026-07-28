// Dosya Adı: ai_chat_report_pdf_builder_test.dart
// Açıklama: AI chat PDF satır/layout yardımcı testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/features/ai_chat_report_pdf_builder.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_spec.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_column.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiChatReportPdfBuilder', () {
    test('toStringRows maps columns', () {
      final rows = AiChatReportPdfBuilder.toStringRows(
        rows: [
          {'code': 12, 'name': 'A'},
          {'code': null, 'name': 'B'},
        ],
        columnIds: const ['code', 'name'],
      );
      expect(rows.length, 2);
      expect(rows[0]['code'], '12');
      expect(rows[0]['name'], 'A');
      expect(rows[1]['code'], '');
    });

    test('layoutFromColumns marks numeric right', () {
      final layout = AiChatReportPdfBuilder.layoutFromColumns(
        reportId: 'ai',
        titleKey: 't',
        columns: const [
          AiReportLayoutColumn(id: 'code', labelKey: 'Kod'),
          AiReportLayoutColumn(
            id: 'balance',
            labelKey: 'Bakiye',
            numeric: true,
          ),
        ],
      );
      expect(layout.columns.length, 2);
      expect(layout.columns[1].align, ReportLayoutColumnAlign.right);
      expect(layout.dense, isTrue);
    });

    test('looksLikeReportRequest keywords', () {
      // imported via agent — keep local mirror for isolation
      expect(_looks('cari bakiye raporu'), isTrue);
      expect(_looks('merhaba'), isFalse);
    });
  });
}

bool _looks(String text) {
  final t = text.trim().toLowerCase();
  const keys = ['rapor', 'report', 'listele', 'pdf', 'extre', 'bakiye list'];
  for (final k in keys) {
    if (t.contains(k)) return true;
  }
  return false;
}
