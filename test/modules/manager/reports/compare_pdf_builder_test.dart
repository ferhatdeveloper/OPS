// Dosya Adı: compare_pdf_builder_test.dart
// Açıklama: Matris PDF builder unit test
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:exfin_ops/modules/manager/reports/model/compare_matrix_models.dart';
import 'package:exfin_ops/modules/manager/reports/model/period_comparison_models.dart';
import 'package:exfin_ops/modules/manager/reports/service/compare_pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build returns non-empty PDF bytes', () async {
    final q = ComparisonWizardState.fromTemplate(
      CompareTemplate.productPeriod,
      anchor: DateTime(2026, 8, 4),
    );
    final result = CompareMatrixResult(
      query: q,
      rowKeys: const ['p1'],
      rowLabels: const ['Urun'],
      colKeys: q.periods.map((p) => p.id).toList(),
      colLabels: q.periods.map((p) => p.label).toList(),
      cells: [
        CompareMatrixCell(
          rowKey: 'p1',
          colKey: q.periods[0].id,
          value: 10,
        ),
        CompareMatrixCell(
          rowKey: 'p1',
          colKey: q.periods[1].id,
          value: 20,
        ),
      ],
      summaryMetrics: const [
        PeriodMetricRow(
          kind: PeriodMetricKind.sales,
          periodA: 10,
          periodB: 20,
        ),
      ],
    );

    const labels = ComparePdfLabels(
      generatedAt: 'Generated',
      template: 'Template',
      templateName: 'Product',
      rowAxis: 'Row',
      rowAxisName: 'Product',
      colAxis: 'Col',
      colAxisName: 'Period',
      periods: 'Periods',
      summary: 'Summary',
      matrix: 'Matrix',
      empty: 'Empty',
      metric: 'Metric',
      previous: 'Prev',
      current: 'Curr',
      diffPct: '%',
    );

    final bytes = await const ComparePdfBuilder().build(
      result: result,
      title: 'Test',
      labels: labels,
    );
    expect(bytes, isNotEmpty);
    // PDF magic
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
