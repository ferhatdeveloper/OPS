// Dosya Adı: report_pivot_aggregator_test.dart
// Açıklama: Pivot toplama + sayı parse + alan tahmini birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/report_pivot_aggregator.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_column.dart';

void main() {
  group('ReportPivotAggregator.parseNumber', () {
    test('TR format 1.234,56', () {
      expect(ReportPivotAggregator.parseNumber('1.234,56'), 1234.56);
    });

    test('EN format 1,234.56', () {
      expect(ReportPivotAggregator.parseNumber('1,234.56'), 1234.56);
    });

    test('basit ondalık ve boş', () {
      expect(ReportPivotAggregator.parseNumber('42'), 42);
      expect(ReportPivotAggregator.parseNumber('12,5'), 12.5);
      expect(ReportPivotAggregator.parseNumber(''), isNull);
      expect(ReportPivotAggregator.parseNumber(null), isNull);
      expect(ReportPivotAggregator.parseNumber('abc'), isNull);
    });

    test('para birimi sembolü temizlenir', () {
      expect(ReportPivotAggregator.parseNumber('₺ 1.000,00'), 1000);
    });
  });

  group('ReportPivotAggregator.aggregate', () {
    test('satır+sütun sum', () {
      final pivot = ReportPivotAggregator.aggregate(
        rows: const [
          {'code': 'A', 'type': 'Nakit', 'amount': '10'},
          {'code': 'A', 'type': 'Nakit', 'amount': '5'},
          {'code': 'A', 'type': 'Çek', 'amount': '3'},
          {'code': 'B', 'type': 'Nakit', 'amount': '7'},
        ],
        rowFieldId: 'code',
        columnFieldId: 'type',
        valueFieldId: 'amount',
      );

      expect(pivot.cell('A', 'Nakit'), 15);
      expect(pivot.cell('A', 'Çek'), 3);
      expect(pivot.cell('B', 'Nakit'), 7);
      expect(pivot.rowTotals['A'], 18);
      expect(pivot.columnTotals['Nakit'], 22);
      expect(pivot.grandTotal, 25);
      expect(pivot.rowKeys, ['A', 'B']);
      expect(pivot.columnKeys, ['Nakit', 'Çek']);
    });

    test('sütun boyutu yoksa tek ölçü', () {
      final pivot = ReportPivotAggregator.aggregate(
        rows: const [
          {'code': 'X', 'amount': '2'},
          {'code': 'X', 'amount': '3'},
          {'code': 'Y', 'amount': '4'},
        ],
        rowFieldId: 'code',
        columnFieldId: null,
        valueFieldId: 'amount',
      );

      expect(pivot.columnKeys, [ReportPivotAggregator.singleMeasureKey]);
      expect(pivot.cell('X', ReportPivotAggregator.singleMeasureKey), 5);
      expect(pivot.grandTotal, 9);
    });

    test('boş etiket ve sayısal olmayan değer', () {
      final pivot = ReportPivotAggregator.aggregate(
        rows: const [
          {'code': '', 'amount': '10'},
          {'code': 'A', 'amount': 'x'},
        ],
        rowFieldId: 'code',
        valueFieldId: 'amount',
      );

      expect(pivot.rowKeys.first, ReportPivotAggregator.emptyLabel);
      expect(
        pivot.cell(ReportPivotAggregator.emptyLabel,
            ReportPivotAggregator.singleMeasureKey),
        10,
      );
      expect(pivot.cell('A', ReportPivotAggregator.singleMeasureKey), 0);
    });
  });

  group('ReportPivotAggregator.guessFields', () {
    test('includeInTotals ölçü ve ilk metin satır', () {
      const layout = ReportLayout(
        reportId: 't',
        titleKey: 't',
        columns: [
          ReportLayoutColumn(id: 'code', titleKey: 'c'),
          ReportLayoutColumn(id: 'name', titleKey: 'n'),
          ReportLayoutColumn(
            id: 'amount',
            titleKey: 'a',
            align: ReportLayoutColumnAlign.right,
            includeInTotals: true,
          ),
        ],
      );
      final g = ReportPivotAggregator.guessFields(layout);
      expect(g.rowFieldId, 'code');
      expect(g.columnFieldId, 'name');
      expect(g.valueFieldId, 'amount');
    });
  });
}
