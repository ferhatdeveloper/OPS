// Dosya Adı: comparison_wizard_provider_test.dart
// Açıklama: Karşılaştırma sihirbazı notifier unit test
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/modules/manager/reports/model/compare_matrix_models.dart';
import 'package:exfin_ops/modules/manager/reports/viewmodel/comparison_wizard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyTemplate productPeriod sets axes', () {
    final n = ComparisonWizardNotifier();
    n.applyTemplate(CompareTemplate.productPeriod);
    expect(n.state.rowAxis, CompareAxis.product);
    expect(n.state.columnAxis, CompareAxis.period);
    expect(n.state.step, 0);
  });

  test('applyTemplate companyPeriod sets company × period', () {
    final n = ComparisonWizardNotifier();
    n.applyTemplate(CompareTemplate.companyPeriod);
    expect(n.state.rowAxis, CompareAxis.company);
    expect(n.state.columnAxis, CompareAxis.period);
    expect(n.state.template, CompareTemplate.companyPeriod);
  });

  test('nextStep blocked when axes invalid on step 1', () {
    final n = ComparisonWizardNotifier();
    n.applyTemplate(CompareTemplate.custom);
    n.nextStep(); // -> 1
    n.setAxes(rowAxis: CompareAxis.product, columnAxis: CompareAxis.product);
    final ok = n.nextStep();
    expect(ok, isFalse);
    expect(n.state.step, 1);
  });

  test('nextStep advances when valid', () {
    final n = ComparisonWizardNotifier();
    n.applyTemplate(CompareTemplate.productPeriod);
    expect(n.nextStep(), isTrue); // 0->1
    expect(n.nextStep(), isTrue); // 1->2
    expect(n.nextStep(), isTrue); // 2->3
    expect(n.state.step, 3);
  });

  test('addPeriod respects max 6', () {
    final n = ComparisonWizardNotifier();
    final base = n.state.periods.first;
    for (var i = 0; i < 10; i++) {
      n.addPeriod(
        ComparePeriodSlot(
          id: 'x$i',
          label: 'X$i',
          range: base.range,
        ),
      );
    }
    expect(n.state.periods.length, ComparisonWizardState.maxPeriods);
  });
}
