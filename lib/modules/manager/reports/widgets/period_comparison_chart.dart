// Dosya Adı: period_comparison_chart.dart
// Açıklama: Dönem karşılaştırma dens bar grafik (fl_chart)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../model/period_comparison_models.dart';

/// {@template period_comparison_chart}
/// Metrik × dönem A/B karşılaştırmalı bar grafik.
///
/// Kullanım örneği:
/// ```dart
/// PeriodComparisonChart(rows: result.rows)
/// ```
/// {@endtemplate}
class PeriodComparisonChart extends StatelessWidget {
  /// [rows]: Metrik satırları
  final List<PeriodMetricRow> rows;

  /// [primary]: Dens primary
  static const Color _primary = FieldSalesDensAppBar.primaryColor;

  /// [secondary]: Dönem B çubuğu
  static const Color _secondary = Color(0xFF6C8EAF);

  /// {@macro period_comparison_chart}
  const PeriodComparisonChart({Key? key, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.translate('advanced.period_compare_empty'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    final maxY = rows.fold<double>(0, (m, r) {
      final local = r.periodA > r.periodB ? r.periodA : r.periodB;
      return local > m ? local : m;
    });
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return Container(
      height: 200,
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
                        if (i < 0 || i >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _metricShort(l10n, rows[i].kind),
                            style: const TextStyle(fontSize: 9),
                          ),
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
                  for (var i = 0; i < rows.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: rows[i].periodA,
                          color: _primary.withOpacity(0.55),
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                        BarChartRodData(
                          toY: rows[i].periodB,
                          color: _secondary,
                          width: 8,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(l10n.translate('advanced.previous_period'), _primary),
              const SizedBox(width: 12),
              _legend(l10n.translate('advanced.current_period'), _secondary),
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
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  String _metricShort(AppLocalization l10n, PeriodMetricKind kind) {
    switch (kind) {
      case PeriodMetricKind.sales:
        return l10n.translate('advanced.metric_sales_short');
      case PeriodMetricKind.orderCount:
        return l10n.translate('advanced.metric_orders_short');
      case PeriodMetricKind.collection:
        return l10n.translate('advanced.metric_collection_short');
      case PeriodMetricKind.visit:
        return l10n.translate('advanced.metric_visits_short');
      case PeriodMetricKind.targetAchievement:
        return l10n.translate('advanced.metric_target_short');
    }
  }

  String _shortNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
