// Dosya Adı: period_comparison_report.dart
// Açıklama: Dönem karşılaştırma dens ekranı (preset, metrik, grafik, AI)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/ai/widgets/report_ai_insight_banner.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import '../model/period_comparison_models.dart';
import '../viewmodel/period_comparison_provider.dart';
import '../widgets/period_comparison_chart.dart';
import '../widgets/period_comparison_pivot_table.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_theme.dart';

/// {@template period_comparison_report_screen}
/// Yönetici dönem karşılaştırma — SQLite A/B metrik + dens grafik.
///
/// Rota: `/field-sales/period-comparison`
///
/// Kullanım örneği:
/// ```dart
/// const PeriodComparisonReportScreen();
/// ```
/// {@endtemplate}
class PeriodComparisonReportScreen extends ConsumerWidget {
  /// {@macro period_comparison_report_screen}
  const PeriodComparisonReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final selection = ref.watch(periodCompareSelectionProvider);
    final async = ref.watch(periodComparisonResultProvider);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('advanced.period_comparison'),
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              fontSize: 11,
              items: [
                _chip(
                  l10n,
                  'advanced.preset_month_vs_last',
                  PeriodComparePreset.thisMonthVsLast,
                  selection,
                  ref,
                ),
                _chip(
                  l10n,
                  'advanced.preset_week_vs_last',
                  PeriodComparePreset.thisWeekVsLast,
                  selection,
                  ref,
                ),
                _chip(
                  l10n,
                  'advanced.preset_yoy',
                  PeriodComparePreset.yearOverYear,
                  selection,
                  ref,
                ),
                _chip(
                  l10n,
                  'advanced.preset_custom',
                  PeriodComparePreset.custom,
                  selection,
                  ref,
                ),
              ],
            ),
          ],
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(periodComparisonResultProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            children: [
              Text(
                l10n.translate('advanced.period_compare_error'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        data: (result) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(periodComparisonResultProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            children: [
              if (selection.preset == PeriodComparePreset.custom)
                _CustomRangePickers(
                  selection: selection,
                  onChanged: (s) =>
                      ref.read(periodCompareSelectionProvider.notifier).state =
                          s,
                ),
              _RangeCaption(result: result),
              const SizedBox(height: 8),
              ReportAiInsightBanner(
                reportTitle: l10n.translate('advanced.period_comparison'),
                rows: [
                  for (final r in result.rows)
                    r.toInsightMap(_metricTitle(l10n, r.kind)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('advanced.period_compare_chart'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              PeriodComparisonChart(rows: result.rows),
              const SizedBox(height: 10),
              Text(
                l10n.translate('advanced.period_compare_pivot'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              PeriodComparisonPivotTable(rows: result.rows),
              const SizedBox(height: 10),
              for (final row in result.rows) ...[
                _MetricCard(row: row),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  FieldSalesDensChipItem _chip(
    AppLocalization l10n,
    String key,
    PeriodComparePreset preset,
    PeriodCompareSelection selection,
    WidgetRef ref,
  ) {
    return FieldSalesDensChipItem(
      label: l10n.translate(key),
      selected: selection.preset == preset,
      onTap: () {
        final notifier = ref.read(periodCompareSelectionProvider.notifier);
        if (preset == PeriodComparePreset.custom) {
          final (a, b) = PeriodCompareRangeResolver.resolve(
            PeriodComparePreset.thisMonthVsLast,
          );
          notifier.state = PeriodCompareSelection(
            preset: PeriodComparePreset.custom,
            customA: selection.customA ?? a,
            customB: selection.customB ?? b,
          );
        } else {
          notifier.state = PeriodCompareSelection(preset: preset);
        }
      },
    );
  }

  String _metricTitle(AppLocalization l10n, PeriodMetricKind kind) {
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
}

/// {@template _range_caption}
/// Seçili A/B tarih aralığı dens satır.
/// {@endtemplate}
class _RangeCaption extends StatelessWidget {
  final PeriodComparisonResult result;

  const _RangeCaption({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.translate('advanced.previous_period')}: '
            '${result.rangeA.fromKey} – ${result.rangeA.toKey}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.translate('advanced.current_period')}: '
            '${result.rangeB.fromKey} – ${result.rangeB.toKey}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

/// {@template _custom_range_pickers}
/// Özel A/B tarih seçicileri (dens).
/// {@endtemplate}
class _CustomRangePickers extends StatelessWidget {
  final PeriodCompareSelection selection;
  final ValueChanged<PeriodCompareSelection> onChanged;

  const _CustomRangePickers({
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final a = selection.customA;
    final b = selection.customB;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateBtn(
                  context,
                  label: l10n.translate('advanced.period_a_from'),
                  value: a?.from,
                  onPick: (d) {
                    final cur = a ??
                        PeriodDateRange(
                          from: d,
                          to: d,
                        );
                    onChanged(
                      selection.copyWith(
                        customA: PeriodDateRange(from: d, to: cur.to),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _dateBtn(
                  context,
                  label: l10n.translate('advanced.period_a_to'),
                  value: a?.to,
                  onPick: (d) {
                    final cur = a ??
                        PeriodDateRange(
                          from: d,
                          to: d,
                        );
                    onChanged(
                      selection.copyWith(
                        customA: PeriodDateRange(from: cur.from, to: d),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _dateBtn(
                  context,
                  label: l10n.translate('advanced.period_b_from'),
                  value: b?.from,
                  onPick: (d) {
                    final cur = b ??
                        PeriodDateRange(
                          from: d,
                          to: d,
                        );
                    onChanged(
                      selection.copyWith(
                        customB: PeriodDateRange(from: d, to: cur.to),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _dateBtn(
                  context,
                  label: l10n.translate('advanced.period_b_to'),
                  value: b?.to,
                  onPick: (d) {
                    final cur = b ??
                        PeriodDateRange(
                          from: d,
                          to: d,
                        );
                    onChanged(
                      selection.copyWith(
                        customB: PeriodDateRange(from: cur.from, to: d),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBtn(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) {
    final text = value == null
        ? '—'
        : '${value.year}-'
            '${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2018),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FieldSalesDensAppBar.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// {@template _metric_card}
/// Tek metrik dens kart (fark / %).
/// {@endtemplate}
class _MetricCard extends StatelessWidget {
  final PeriodMetricRow row;

  const _MetricCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final diff = row.diff;
    final perc = row.pctChange;
    final isPositive = diff >= 0;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title(l10n),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('advanced.previous_period'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt(row.periodA),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade300,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.translate('advanced.current_period'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt(row.periodB),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('advanced.difference_growth'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}'
                        '${perc.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppLocalization l10n) {
    switch (row.kind) {
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

  String _fmt(double v) {
    switch (row.kind) {
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
