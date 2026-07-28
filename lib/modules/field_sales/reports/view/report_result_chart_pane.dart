// Dosya Adı: report_result_chart_pane.dart
// Açıklama: Rapor sonuç dens Grafik sekmesi (fl_chart)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../engine/report_chart_series_builder.dart';
import '../model/report_chart_kind.dart';
import '../model/report_layout.dart';
import 'report_dens_empty_state.dart';

/// {@template report_result_chart_pane}
/// Layout + satırlardan bar / line / pie dens grafik.
///
/// Kullanım örneği:
/// ```dart
/// ReportResultChartPane(
///   layout: layout,
///   rows: rows,
///   kind: ReportChartKind.bar,
/// )
/// ```
/// {@endtemplate}
class ReportResultChartPane extends StatelessWidget {
  /// [layout]: Sütun şeması
  final ReportLayout layout;

  /// [rows]: Veri
  final List<Map<String, String>> rows;

  /// [kind]: Grafik türü
  final ReportChartKind kind;

  /// {@macro report_result_chart_pane}
  const ReportResultChartPane({
    Key? key,
    required this.layout,
    required this.rows,
    required this.kind,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final series = ReportChartSeriesBuilder.build(
      layout: layout,
      rows: rows,
      kind: kind,
    );

    if (series.isEmpty) {
      return const ReportDensEmptyState(
        messageKey: 'field_sales.mbt_reports.chart_empty',
        icon: Icons.bar_chart_outlined,
      );
    }

    final labelTitle = series.labelFieldId == null
        ? ''
        : l10n.translate(
            layout.columns
                .firstWhere(
                  (c) => c.id == series.labelFieldId,
                  orElse: () => layout.columns.first,
                )
                .titleKey,
          );
    final valueTitle = series.valueFieldId == null
        ? ''
        : l10n.translate(
            layout.columns
                .firstWhere(
                  (c) => c.id == series.valueFieldId,
                  orElse: () => layout.columns.first,
                )
                .titleKey,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        if (labelTitle.isNotEmpty || valueTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              [
                if (labelTitle.isNotEmpty) labelTitle,
                if (valueTitle.isNotEmpty) valueTitle,
              ].join(' · '),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _buildChart(series),
        ),
      ],
    );
  }

  Widget _buildChart(ReportChartSeries series) {
    switch (series.kind) {
      case ReportChartKind.pie:
        return _pie(series);
      case ReportChartKind.line:
        return _line(series);
      case ReportChartKind.bar:
        return _bar(series);
    }
  }

  Widget _bar(ReportChartSeries series) {
    final primary = FieldSalesDensAppBar.primaryColor;
    final maxY = series.points
        .map((p) => p.value.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= series.points.length) {
                  return const SizedBox.shrink();
                }
                final label = series.points[i].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label.length > 8 ? '${label.substring(0, 8)}…' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < series.points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series.points[i].value.abs().clamp(0, double.infinity),
                  color: primary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(ReportChartSeries series) {
    final primary = FieldSalesDensAppBar.primaryColor;
    final spots = <FlSpot>[
      for (var i = 0; i < series.points.length; i++)
        FlSpot(i.toDouble(), series.points[i].value),
    ];
    final maxY = series.points
        .map((p) => p.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final minY = series.points
        .map((p) => p.value)
        .fold<double>(0, (a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY > 0 ? 0 : minY * 1.1,
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        lineTouchData: const LineTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= series.points.length) {
                  return const SizedBox.shrink();
                }
                final label = series.points[i].label;
                return Text(
                  label.length > 6 ? '${label.substring(0, 6)}…' : label,
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pie(ReportChartSeries series) {
    const colors = [
      FieldSalesDensAppBar.primaryColor,
      FieldSalesDensAppBar.accentColor,
      Color(0xFF6C757D),
      Color(0xFF29B6F6),
      Color(0xFFFDD835),
      Color(0xFF66BB6A),
    ];
    final total = series.points.fold<double>(0, (s, p) => s + p.value.abs());
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                for (var i = 0; i < series.points.length; i++)
                  PieChartSectionData(
                    value: series.points[i].value.abs().clamp(0.01, double.infinity),
                    color: colors[i % colors.length],
                    title: '',
                    radius: 36,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: series.points.length,
            itemBuilder: (context, i) {
              final p = series.points[i];
              final pct = (p.value.abs() / total * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${p.label} ($pct%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
