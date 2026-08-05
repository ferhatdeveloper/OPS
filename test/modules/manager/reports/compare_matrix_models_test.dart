// Dosya Adı: compare_matrix_models_test.dart
// Açıklama: Esnek matris model unit testleri
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/modules/manager/reports/model/compare_matrix_models.dart';
import 'package:exfin_ops/modules/manager/reports/model/period_comparison_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('periodOverview maps to none × period with 2 slots', () {
    final s = ComparisonWizardState.fromTemplate(
      CompareTemplate.periodOverview,
      anchor: DateTime(2026, 8, 4),
    );
    expect(s.rowAxis, CompareAxis.none);
    expect(s.columnAxis, CompareAxis.period);
    expect(s.periods.length, 2);
    expect(s.isAxesValid, isTrue);
  });

  test('companyPeriod maps company × period', () {
    final s = ComparisonWizardState.fromTemplate(
      CompareTemplate.companyPeriod,
    );
    expect(s.rowAxis, CompareAxis.company);
    expect(s.columnAxis, CompareAxis.period);
    expect(s.isAxesValid, isTrue);
  });

  test('productPeriod maps product × period', () {
    final s = ComparisonWizardState.fromTemplate(
      CompareTemplate.productPeriod,
    );
    expect(s.rowAxis, CompareAxis.product);
    expect(s.columnAxis, CompareAxis.period);
  });

  test('regionPeriod / brandCategory / salesmanPeriod eksenleri', () {
    expect(
      ComparisonWizardState.fromTemplate(CompareTemplate.regionPeriod)
          .rowAxis,
      CompareAxis.region,
    );
    expect(
      ComparisonWizardState.fromTemplate(CompareTemplate.brandCategory)
          .rowAxis,
      CompareAxis.brand,
    );
    expect(
      ComparisonWizardState.fromTemplate(CompareTemplate.salesmanPeriod)
          .rowAxis,
      CompareAxis.salesman,
    );
  });

  test('periods clamp to max 6', () {
    final base = ComparisonWizardState.fromTemplate(
      CompareTemplate.productPeriod,
    );
    final many = List.generate(
      8,
      (i) => ComparePeriodSlot(
        id: '$i',
        label: 'P$i',
        range: PeriodDateRange(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 1, 31),
        ),
      ),
    );
    final next = base.copyWith(periods: many);
    expect(next.periods.length, ComparisonWizardState.maxPeriods);
  });

  test('same row and column axis is invalid', () {
    final s = ComparisonWizardState.fromTemplate(CompareTemplate.custom)
        .copyWith(
      rowAxis: CompareAxis.product,
      columnAxis: CompareAxis.product,
    );
    expect(s.isAxesValid, isFalse);
  });

  test('toJson / fromJson round-trip korunur', () {
    final original = ComparisonWizardState.fromTemplate(
      CompareTemplate.companyPeriod,
      anchor: DateTime(2026, 8, 5),
    ).copyWith(companyIds: const ['001', '012'], topN: 20);
    final restored = ComparisonWizardState.fromJson(original.toJson());
    expect(restored, isNotNull);
    expect(restored!.template, CompareTemplate.companyPeriod);
    expect(restored.rowAxis, CompareAxis.company);
    expect(restored.companyIds, ['001', '012']);
    expect(restored.topN, 20);
    expect(restored.periods.length, original.periods.length);
  });

  test('valueAt returns cell value', () {
    final q = ComparisonWizardState.fromTemplate(
      CompareTemplate.periodOverview,
    );
    final r = CompareMatrixResult(
      query: q,
      rowKeys: const ['a'],
      rowLabels: const ['A'],
      colKeys: const ['c1', 'c2'],
      colLabels: const ['C1', 'C2'],
      cells: const [
        CompareMatrixCell(rowKey: 'a', colKey: 'c1', value: 10),
        CompareMatrixCell(rowKey: 'a', colKey: 'c2', value: 20),
      ],
    );
    expect(r.valueAt('a', 'c2'), 20);
    expect(r.valueAt('missing', 'c1'), 0);
  });

  test('wizard and matrix JSON round-trip', () {
    final q = ComparisonWizardState.fromTemplate(
      CompareTemplate.companyPeriod,
      anchor: DateTime(2026, 8, 5),
    ).copyWith(companyIds: const ['001', '002'], step: 3, topN: 10);
    final restored = ComparisonWizardState.fromJson(q.toJson());
    expect(restored, isNotNull);
    expect(restored!.template, CompareTemplate.companyPeriod);
    expect(restored.companyIds, ['001', '002']);
    expect(restored.periods.length, 2);
    expect(restored.topN, 10);

    final matrix = CompareMatrixResult(
      query: q,
      rowKeys: const ['001'],
      rowLabels: const ['F1'],
      colKeys: const ['a', 'b'],
      colLabels: const ['A', 'B'],
      cells: const [
        CompareMatrixCell(rowKey: '001', colKey: 'a', value: 5),
      ],
    );
    final m2 = CompareMatrixResult.fromJson(matrix.toJson());
    expect(m2, isNotNull);
    expect(m2!.valueAt('001', 'a'), 5);
    expect(m2.query.companyIds, ['001', '002']);
  });
}
