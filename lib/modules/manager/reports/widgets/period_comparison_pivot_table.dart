// Dosya Adı: period_comparison_pivot_table.dart
// Açıklama: Dönem karşılaştırma dens pivot özet tablo (metrik × dönem)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/period_comparison_models.dart';

/// {@template period_comparison_pivot_table}
/// Metrik × dönem A/B + fark / % dens tablo.
///
/// Kullanım örneği:
/// ```dart
/// PeriodComparisonPivotTable(rows: result.rows)
/// ```
/// {@endtemplate}
class PeriodComparisonPivotTable extends StatelessWidget {
  /// [rows]: Metrik satırları
  final List<PeriodMetricRow> rows;

  /// {@macro period_comparison_pivot_table}
  const PeriodComparisonPivotTable({
    Key? key,
    required this.rows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _header(l10n),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
            _row(l10n, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _header(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              l10n.translate('advanced.metric'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('advanced.previous_period'),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('advanced.current_period'),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('advanced.diff_pct'),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppLocalization l10n, PeriodMetricRow row) {
    final isUp = row.diff >= 0;
    final color = isUp ? Colors.green.shade700 : Colors.red.shade700;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _metricLabel(l10n, row.kind),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmt(row.kind, row.periodA),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmt(row.kind, row.periodB),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isUp ? '+' : ''}${row.pctChange.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _metricLabel(AppLocalization l10n, PeriodMetricKind kind) {
    switch (kind) {
      case PeriodMetricKind.sales:
        return l10n.translate('advanced.metric_sales');
      case PeriodMetricKind.orderCount:
        return l10n.translate('advanced.metric_orders');
      case PeriodMetricKind.collection:
        return l10n.translate('advanced.metric_collection');
      case PeriodMetricKind.visit:
        return l10n.translate('advanced.metric_visits');
      case PeriodMetricKind.targetAchievement:
        return l10n.translate('advanced.metric_target');
    }
  }

  String _fmt(PeriodMetricKind kind, double v) {
    switch (kind) {
      case PeriodMetricKind.orderCount:
      case PeriodMetricKind.visit:
        return v.toStringAsFixed(0);
      case PeriodMetricKind.targetAchievement:
        return '${v.toStringAsFixed(1)}%';
      case PeriodMetricKind.sales:
      case PeriodMetricKind.collection:
        return v.toStringAsFixed(0);
    }
  }
}
