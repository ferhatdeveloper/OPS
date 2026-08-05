// Dosya Adı: compare_line_chart.dart
// Açıklama: Matris çok serili çizgi grafik (fl_chart, dens)
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/compare_matrix_models.dart';

/// {@template compare_line_chart}
/// En fazla 5 satır × dönem sütunları çizgi grafik.
///
/// Kullanım örneği:
/// ```dart
/// CompareLineChart(result: result)
/// ```
/// {@endtemplate}
class CompareLineChart extends StatelessWidget {
  /// [result]: Matris
  final CompareMatrixResult result;

  static const List<Color> _palette = [
    Color(0xFF375A7F),
    Color(0xFF6C8EAF),
    Color(0xFFE67E22),
    Color(0xFF27AE60),
    Color(0xFF8E44AD),
  ];

  /// {@macro compare_line_chart}
  const CompareLineChart({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final cols = result.colKeys;
    final rows = result.rowKeys;
    if (rows.isEmpty || cols.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.translate('advanced.period_compare_empty'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    final showN = rows.length > 5 ? 5 : rows.length;
    var maxY = 0.0;
    for (var i = 0; i < showN; i++) {
      for (final c in cols) {
        final v = result.valueAt(rows[i], c);
        if (v > maxY) maxY = v;
      }
    }
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMax,
          lineTouchData: const LineTouchData(enabled: true),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
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
                  v.toStringAsFixed(0),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= cols.length) {
                    return const SizedBox.shrink();
                  }
                  final l = result.colLabels[i];
                  final short = l.length > 8 ? '${l.substring(0, 7)}…' : l;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(short, style: const TextStyle(fontSize: 8)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (var i = 0; i < showN; i++)
              LineChartBarData(
                isCurved: true,
                color: _palette[i % _palette.length],
                barWidth: 2,
                dotData: const FlDotData(show: true),
                spots: [
                  for (var j = 0; j < cols.length; j++)
                    FlSpot(
                      j.toDouble(),
                      result.valueAt(rows[i], cols[j]),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
