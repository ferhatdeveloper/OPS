// Dosya Adı: compare_grouped_bar_chart.dart
// Açıklama: Matris gruplu bar grafik (fl_chart, dens)
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/compare_matrix_models.dart';

/// {@template compare_grouped_bar_chart}
/// Satır grupları × dönem sütunları bar grafik.
///
/// Kullanım örneği:
/// ```dart
/// CompareGroupedBarChart(result: result)
/// ```
/// {@endtemplate}
class CompareGroupedBarChart extends StatelessWidget {
  /// [result]: Matris
  final CompareMatrixResult result;

  static const List<Color> _palette = [
    Color(0xFF375A7F),
    Color(0xFF6C8EAF),
    Color(0xFF4A90A4),
    Color(0xFF8FA9C4),
    Color(0xFF2C3E50),
    Color(0xFF5D7A99),
  ];

  /// {@macro compare_grouped_bar_chart}
  const CompareGroupedBarChart({Key? key, required this.result})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final rows = result.rowKeys;
    final cols = result.colKeys;
    if (rows.isEmpty || cols.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.translate('advanced.period_compare_empty'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    // En fazla 8 satır göster (okunabilirlik)
    final showN = rows.length > 8 ? 8 : rows.length;
    var maxY = 0.0;
    for (var i = 0; i < showN; i++) {
      for (final c in cols) {
        final v = result.valueAt(rows[i], c);
        if (v > maxY) maxY = v;
      }
    }
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        _shortNum(v),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= showN) {
                          return const SizedBox.shrink();
                        }
                        final label = result.rowLabels[i];
                        final short = label.length > 8
                            ? '${label.substring(0, 7)}…'
                            : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(short, style: const TextStyle(fontSize: 8)),
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
                barGroups: [
                  for (var i = 0; i < showN; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 1,
                      barRods: [
                        for (var j = 0; j < cols.length; j++)
                          BarChartRodData(
                            toY: result.valueAt(rows[i], cols[j]),
                            color: _palette[j % _palette.length],
                            width: cols.length > 4 ? 5 : 8,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              for (var j = 0; j < cols.length; j++)
                _legend(
                  result.colLabels[j],
                  _palette[j % _palette.length],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 3),
        Text(
          label.length > 12 ? '${label.substring(0, 11)}…' : label,
          style: const TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  String _shortNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
