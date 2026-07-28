// Dosya Adı: other_report_scope_test.dart
// Açıklama: Other rapor kapsamı + layout varsayılan smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/other/model/other_report_scope.dart';

void main() {
  group('OtherReportScope layouts', () {
    test('owned id’ler için varsayılan layout dolu', () {
      for (final id in OtherReportScope.allIds) {
        final layout = ReportLayoutDefaults.forReportId(id);
        expect(layout.reportId, id, reason: id);
        expect(layout.columns, isNotEmpty, reason: id);
        expect(layout.visibleColumns, isNotEmpty, reason: id);
      }
    });
  });
}
