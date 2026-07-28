// Dosya Adı: report_empty_smoke_test.dart
// Açıklama: OPS smoke — rapor pivot boş satır etiketi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/reports/engine/report_pivot_aggregator.dart';

void main() {
  test('ReportPivotAggregator empty label stable', () {
    expect(ReportPivotAggregator.emptyLabel, '(boş)');
  });
}
