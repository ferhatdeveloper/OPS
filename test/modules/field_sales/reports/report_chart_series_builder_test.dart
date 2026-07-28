// Dosya Adı: report_chart_series_builder_test.dart
// Açıklama: Grafik seri toplama + kategori türü birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/report_chart_series_builder.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_category.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_chart_kind.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_column.dart';

void main() {
  group('ReportChartKindX.forCategory', () {
    test('ailelere göre tür', () {
      expect(
        ReportChartKindX.forCategory(MbtReportCategory.cari),
        ReportChartKind.bar,
      );
      expect(
        ReportChartKindX.forCategory(MbtReportCategory.fatura),
        ReportChartKind.line,
      );
      expect(
        ReportChartKindX.forCategory(MbtReportCategory.yonetici),
        ReportChartKind.pie,
      );
    });
  });

  group('ReportChartSeriesBuilder', () {
    test('etikete göre sum ve sıralama', () {
      const layout = ReportLayout(
        reportId: 't',
        titleKey: 't',
        columns: [
          ReportLayoutColumn(id: 'code', titleKey: 'c'),
          ReportLayoutColumn(
            id: 'amount',
            titleKey: 'a',
            includeInTotals: true,
            align: ReportLayoutColumnAlign.right,
          ),
        ],
      );
      final series = ReportChartSeriesBuilder.build(
        layout: layout,
        rows: const [
          {'code': 'B', 'amount': '5'},
          {'code': 'A', 'amount': '10'},
          {'code': 'A', 'amount': '2'},
        ],
        kind: ReportChartKind.bar,
      );
      expect(series.points.first.label, 'A');
      expect(series.points.first.value, 12);
      expect(series.points[1].label, 'B');
      expect(series.points[1].value, 5);
    });
  });
}
