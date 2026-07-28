// Dosya Adı: report_chart_series_builder.dart
// Açıklama: Layout + satırlardan grafik seri noktaları (fl_chart)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../model/report_chart_kind.dart';
import '../model/report_layout.dart';
import '../model/report_layout_column.dart';
import 'report_pivot_aggregator.dart';

/// {@template report_chart_point}
/// Tek grafik noktası (etiket + değer).
/// {@endtemplate}
class ReportChartPoint {
  /// [label]: Kategori / dönem etiketi
  final String label;

  /// [value]: Sayısal değer
  final double value;

  /// {@macro report_chart_point}
  const ReportChartPoint({
    required this.label,
    required this.value,
  });
}

/// {@template report_chart_series}
/// Grafik sekmesi için hazır seri.
/// {@endtemplate}
class ReportChartSeries {
  /// [kind]: bar / line / pie
  final ReportChartKind kind;

  /// [labelFieldId]: Etiket sütunu
  final String? labelFieldId;

  /// [valueFieldId]: Değer sütunu
  final String? valueFieldId;

  /// [points]: Toplanmış noktalar (max [maxPoints])
  final List<ReportChartPoint> points;

  /// {@macro report_chart_series}
  const ReportChartSeries({
    required this.kind,
    this.labelFieldId,
    this.valueFieldId,
    required this.points,
  });

  /// [isEmpty]: Nokta yok
  bool get isEmpty => points.isEmpty;
}

/// {@template report_chart_series_builder}
/// Rapor satırlarından dens grafik serisi üretir.
///
/// Kullanım örneği:
/// ```dart
/// final series = ReportChartSeriesBuilder.build(
///   layout: layout,
///   rows: rows,
///   kind: ReportChartKind.bar,
/// );
/// ```
/// {@endtemplate}
class ReportChartSeriesBuilder {
  /// Grafikte gösterilecek max kategori (dens okunabilirlik)
  static const int maxPoints = 12;

  /// {@macro report_chart_series_builder}
  const ReportChartSeriesBuilder._();

  /// {@template report_chart_series_builder_build}
  /// Etiket/değer sütunlarını seçer, etikete göre sum toplar.
  ///
  /// Parametreler:
  /// - [layout]: Sütun şeması
  /// - [rows]: Veri
  /// - [kind]: Grafik türü
  /// - [maxPoints]: Üst sınır (varsayılan 12)
  ///
  /// Dönüş değeri:
  /// - [ReportChartSeries]: Seri
  /// {@endtemplate}
  static ReportChartSeries build({
    required ReportLayout layout,
    required List<Map<String, String>> rows,
    required ReportChartKind kind,
    int maxPoints = ReportChartSeriesBuilder.maxPoints,
  }) {
    final cols = layout.visibleColumns;
    if (cols.isEmpty || rows.isEmpty) {
      return ReportChartSeries(kind: kind, points: const []);
    }

    final valueCol = _pickValueColumn(cols);
    final labelCol = _pickLabelColumn(cols, valueCol.id);

    final sums = <String, double>{};
    final order = <String>[];
    for (final row in rows) {
      final label = (row[labelCol.id] ?? '').trim();
      final key = label.isEmpty ? ReportPivotAggregator.emptyLabel : label;
      final v = ReportPivotAggregator.parseNumber(row[valueCol.id]) ?? 0;
      if (!sums.containsKey(key)) order.add(key);
      sums[key] = (sums[key] ?? 0) + v;
    }

    var points = order
        .map((k) => ReportChartPoint(label: k, value: sums[k] ?? 0))
        .toList(growable: false);

    // En büyük |değer| önce — pasta/bar okunabilirliği
    final sorted = List<ReportChartPoint>.from(points)
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    if (sorted.length > maxPoints) {
      final head = sorted.take(maxPoints - 1).toList();
      final rest = sorted.skip(maxPoints - 1);
      final other = rest.fold<double>(0, (s, p) => s + p.value);
      points = [
        ...head,
        ReportChartPoint(label: '…', value: other),
      ];
    } else {
      points = sorted;
    }

    return ReportChartSeries(
      kind: kind,
      labelFieldId: labelCol.id,
      valueFieldId: valueCol.id,
      points: points,
    );
  }

  static ReportLayoutColumn _pickValueColumn(
    List<ReportLayoutColumn> cols,
  ) {
    for (final c in cols) {
      if (c.includeInTotals) return c;
    }
    for (final c in cols) {
      if (c.align == ReportLayoutColumnAlign.right) return c;
    }
    return cols.last;
  }

  static ReportLayoutColumn _pickLabelColumn(
    List<ReportLayoutColumn> cols,
    String valueId,
  ) {
    for (final c in cols) {
      if (c.id != valueId && c.align != ReportLayoutColumnAlign.right) {
        return c;
      }
    }
    for (final c in cols) {
      if (c.id != valueId) return c;
    }
    return cols.first;
  }
}
