// Dosya Adı: admin_kpi_summary_screen.dart
// Açıklama: MBT Yönetici — plasiyer KPI özeti (SQLite + grafik + pivot + AI)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../ai/widgets/report_ai_insight_banner.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/admin_kpi_summary.dart';
import '../viewmodel/admin_kpi_provider.dart';

/// {@template admin_kpi_summary_screen}
/// Plasiyer KPI özet ekranı (MBT Yönetici parity).
///
/// Rota: `/field-sales/admin` — menü seed `fs_admin`.
/// Sayılar / tutarlar yerel SQLite dönem aggregate + grafik / pivot / AI.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, AdminKpiSummaryScreen.routeName);
/// ```
/// {@endtemplate}
class AdminKpiSummaryScreen extends ConsumerWidget {
  /// [routeName]: Named route — `/field-sales/admin`
  static const String routeName = '/field-sales/admin';

  /// [primary]: Mevcut field_sales vurgu rengi
  static const Color _primary = Color(0xFF375A7F);

  /// [accent]: Tahsilat trend çizgisi (mevcut palette tonu)
  static const Color _accent = Color(0xFF5B7A9D);

  const AdminKpiSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.admin_kpi');
    final period = ref.watch(adminKpiPeriodProvider);
    final asyncSummary = ref.watch(adminKpiSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
        useGradient: true,
      ),
      body: asyncSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminKpiSummaryProvider),
          child: _AdminKpiBody(
            summary: AdminKpiSummary.zero,
            period: period,
            onPeriodChanged: (p) =>
                ref.read(adminKpiPeriodProvider.notifier).state = p,
            hintKey: 'field_sales.admin_kpi_error_hint',
            reportTitle: title,
          ),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminKpiSummaryProvider),
          child: _AdminKpiBody(
            summary: summary,
            period: period,
            onPeriodChanged: (p) =>
                ref.read(adminKpiPeriodProvider.notifier).state = p,
            hintKey: 'field_sales.admin_kpi_live_hint',
            reportTitle: title,
          ),
        ),
      ),
    );
  }
}

/// {@template _admin_kpi_body}
/// Dönem şeridi + KPI / grafik / pivot / AI.
/// {@endtemplate}
class _AdminKpiBody extends StatelessWidget {
  /// [summary]: Gösterilecek KPI
  final AdminKpiSummary summary;

  /// [period]: Seçili dens dönem
  final AdminKpiPeriod period;

  /// [onPeriodChanged]: Dönem değişince
  final ValueChanged<AdminKpiPeriod> onPeriodChanged;

  /// [hintKey]: Alt açıklama l10n anahtarı
  final String hintKey;

  /// [reportTitle]: AI insight başlığı
  final String reportTitle;

  const _AdminKpiBody({
    required this.summary,
    required this.period,
    required this.onPeriodChanged,
    required this.hintKey,
    required this.reportTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final activity = <_KpiRow>[
      _KpiRow(
        labelKey: 'field_sales.visit',
        value: '${summary.visitCount}',
        icon: Icons.location_on_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.order',
        value: '${summary.orderCount}',
        icon: Icons.shopping_cart_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.invoice',
        value: '${summary.invoiceCount}',
        icon: Icons.receipt_long_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.collection',
        value: '${summary.collectionCount}',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.admin_kpi_waybill_count',
        value: '${summary.waybillCount}',
        icon: Icons.local_shipping_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.admin_kpi_sales_amount',
        value: _formatAmount(summary.salesAmount),
        icon: Icons.trending_up,
      ),
      _KpiRow(
        labelKey: 'field_sales.admin_kpi_order_amount',
        value: _formatAmount(summary.orderAmount),
        icon: Icons.shopping_bag_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.admin_kpi_active_salespersons',
        value: '${summary.activeSalespersonCount}',
        icon: Icons.badge_outlined,
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
      children: [
        Text(
          l10n.translate('field_sales.admin_kpi_subtitle'),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        _PeriodStrip(
          period: period,
          onChanged: onPeriodChanged,
        ),
        const SizedBox(height: 6),
        ReportAiInsightBanner(
          reportTitle: reportTitle,
          rows: summary.toInsightRows(),
        ),
        const SizedBox(height: 8),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_activity'),
        ),
        const SizedBox(height: 4),
        _KpiGrid(rows: activity),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_distribution'),
        ),
        const SizedBox(height: 4),
        _ActivityBarChart(summary: summary),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_finance'),
        ),
        const SizedBox(height: 4),
        _MetricList(
          rows: [
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_cash_collected'),
              value: _formatAmount(summary.cashCollected),
              icon: Icons.payments_outlined,
            ),
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_check_collected'),
              value: _formatAmount(summary.checkCollected),
              icon: Icons.note_outlined,
            ),
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_bank_snapshot'),
              value: _formatAmount(summary.bankSnapshot),
              icon: Icons.account_balance_outlined,
            ),
            _MetricLine(
              label:
                  l10n.translate('field_sales.admin_kpi_collection_amount'),
              value: _formatAmount(summary.collectionAmount),
              icon: Icons.attach_money,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_target'),
        ),
        const SizedBox(height: 4),
        _MetricList(
          rows: [
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_target_amount'),
              value: _formatAmount(summary.targetAmount),
              icon: Icons.flag_outlined,
            ),
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_target_achieved'),
              value: _formatAmount(summary.targetAchieved),
              icon: Icons.check_circle_outline,
            ),
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_target_pct'),
              value: '%${summary.targetPct.toStringAsFixed(1)}',
              icon: Icons.percent,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_risk'),
        ),
        const SizedBox(height: 4),
        _MetricList(
          rows: [
            _MetricLine(
              label:
                  l10n.translate('field_sales.admin_kpi_open_receivables'),
              value: _formatAmount(summary.openReceivables),
              icon: Icons.people_outline,
            ),
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_debtor_count'),
              value: '${summary.debtorCount}',
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_transfer'),
        ),
        const SizedBox(height: 4),
        _MetricList(
          rows: [
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_pending_total'),
              value: '${summary.pendingTransferTotal}',
              icon: Icons.sync_problem_outlined,
            ),
            _MetricLine(
              label: l10n.translate('field_sales.admin_kpi_pending_orders'),
              value: '${summary.pendingOrderCount}',
              icon: Icons.shopping_cart_outlined,
            ),
            _MetricLine(
              label:
                  l10n.translate('field_sales.admin_kpi_pending_invoices'),
              value: '${summary.pendingInvoiceCount}',
              icon: Icons.receipt_long_outlined,
            ),
            _MetricLine(
              label:
                  l10n.translate('field_sales.admin_kpi_pending_waybills'),
              value: '${summary.pendingWaybillCount}',
              icon: Icons.local_shipping_outlined,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_trend'),
        ),
        const SizedBox(height: 4),
        _DualTrendChart(
          sales: summary.sparklineSales,
          collections: summary.sparklineCollections,
        ),
        const SizedBox(height: 10),
        _SectionTitle(
          label: l10n.translate('field_sales.admin_kpi_section_pivot'),
        ),
        const SizedBox(height: 4),
        _PivotTable(rows: summary.pivotRows),
        const SizedBox(height: 10),
        Text(
          l10n.translate(hintKey),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// {@template _admin_kpi_body_format_amount}
  /// Dens tutar gösterimi (`1.234,56`).
  /// {@endtemplate}
  static String _formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }
}

/// {@template _period_strip}
/// Bugün / Hafta / Ay dens dönem şeridi.
/// {@endtemplate}
class _PeriodStrip extends StatelessWidget {
  /// [period]: Seçili dönem
  final AdminKpiPeriod period;

  /// [onChanged]: Değişim
  final ValueChanged<AdminKpiPeriod> onChanged;

  const _PeriodStrip({
    required this.period,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const primary = AdminKpiSummaryScreen._primary;
    final entries = <(AdminKpiPeriod, String)>[
      (AdminKpiPeriod.today, 'field_sales.period_today'),
      (AdminKpiPeriod.week, 'field_sales.period_this_week'),
      (AdminKpiPeriod.month, 'field_sales.period_this_month'),
    ];
    return FieldSalesDensChipRow(
      primary: primary,
      fontSize: 11,
      items: [
        for (final entry in entries)
          FieldSalesDensChipItem(
            label: l10n.translate(entry.$2),
            selected: period == entry.$1,
            onTap: () => onChanged(entry.$1),
          ),
      ],
    );
  }
}

/// {@template _section_title}
/// Dens bölüm başlığı.
/// {@endtemplate}
class _SectionTitle extends StatelessWidget {
  /// [label]: Başlık metni
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AdminKpiSummaryScreen._primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// {@template _kpi_grid}
/// 2 sütun dens KPI kart ızgarası.
/// {@endtemplate}
class _KpiGrid extends StatelessWidget {
  /// [rows]: Kart satırları
  final List<_KpiRow> rows;

  const _KpiGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final kpi = rows[index];
        return _FlatKpiCard(
          label: l10n.translate(kpi.labelKey),
          value: kpi.value,
          icon: kpi.icon,
        );
      },
    );
  }
}

/// {@template _metric_list}
/// Dens satır metrik listesi (finans / risk / transfer).
/// {@endtemplate}
class _MetricList extends StatelessWidget {
  /// [rows]: Metrik satırları
  final List<_MetricLine> rows;

  const _MetricList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    rows[i].icon,
                    size: 16,
                    color: AdminKpiSummaryScreen._primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: const TextStyle(
                      color: AdminKpiSummaryScreen._primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// {@template _metric_line}
/// Tek dens metrik satırı.
/// {@endtemplate}
class _MetricLine {
  /// [label]: Etiket
  final String label;

  /// [value]: Değer metni
  final String value;

  /// [icon]: Sol ikon
  final IconData icon;

  const _MetricLine({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// {@template _activity_bar_chart}
/// Dönem aktivite dağılımı (ziyaret / sipariş / fatura / tahsilat / irsaliye).
/// {@endtemplate}
class _ActivityBarChart extends StatelessWidget {
  /// [summary]: KPI kaynağı
  final AdminKpiSummary summary;

  const _ActivityBarChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final values = <double>[
      summary.visitCount.toDouble(),
      summary.orderCount.toDouble(),
      summary.invoiceCount.toDouble(),
      summary.collectionCount.toDouble(),
      summary.waybillCount.toDouble(),
    ];
    final labels = <String>[
      l10n.translate('field_sales.visit'),
      l10n.translate('field_sales.order'),
      l10n.translate('field_sales.invoice'),
      l10n.translate('field_sales.collection'),
      l10n.translate('field_sales.admin_kpi_waybill_count'),
    ];
    final maxY = values.fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
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
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  final short = labels[i].length > 6
                      ? '${labels[i].substring(0, 5)}…'
                      : labels[i];
                  return Text(
                    short,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                    color: AdminKpiSummaryScreen._primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// {@template _dual_trend_chart}
/// Son 7 gün satış + tahsilat çift çizgi grafik.
/// {@endtemplate}
class _DualTrendChart extends StatelessWidget {
  /// [sales]: Günlük satış
  final List<double> sales;

  /// [collections]: Günlük tahsilat
  final List<double> collections;

  const _DualTrendChart({
    required this.sales,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final salesSeries =
        sales.isEmpty ? List<double>.filled(7, 0) : sales;
    final colSeries = collections.isEmpty
        ? List<double>.filled(salesSeries.length, 0)
        : collections;
    final len = salesSeries.length;
    var maxY = 0.0;
    for (final v in salesSeries) {
      if (v > maxY) maxY = v;
    }
    for (final v in colSeries) {
      if (v > maxY) maxY = v;
    }

    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _LegendDot(
                color: AdminKpiSummaryScreen._primary,
                label: l10n.translate('field_sales.admin_kpi_sales_amount'),
              ),
              const SizedBox(width: 10),
              _LegendDot(
                color: AdminKpiSummaryScreen._accent,
                label: l10n.translate(
                  'field_sales.admin_kpi_collection_amount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (len - 1).toDouble().clamp(1, 6),
                minY: 0,
                maxY: maxY <= 0 ? 1 : maxY * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < len; i++)
                        FlSpot(i.toDouble(), salesSeries[i]),
                    ],
                    isCurved: true,
                    color: AdminKpiSummaryScreen._primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AdminKpiSummaryScreen._primary.withOpacity(0.10),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < colSeries.length; i++)
                        FlSpot(i.toDouble(), colSeries[i]),
                    ],
                    isCurved: true,
                    color: AdminKpiSummaryScreen._accent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template _legend_dot}
/// Trend grafik efsane noktası.
/// {@endtemplate}
class _LegendDot extends StatelessWidget {
  /// [color]: Nokta rengi
  final Color color;

  /// [label]: Etiket
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// {@template _pivot_table}
/// Plasiyer × metrik dens pivot tablo.
/// {@endtemplate}
class _PivotTable extends StatelessWidget {
  /// [rows]: Pivot satırları
  final List<AdminKpiPivotRow> rows;

  const _PivotTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          l10n.translate('field_sales.admin_kpi_pivot_empty'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    final headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade700,
    );
    const valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AdminKpiSummaryScreen._primary,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.translate('field_sales.gps_salesperson'),
                    style: headerStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.translate('field_sales.visit'),
                    textAlign: TextAlign.end,
                    style: headerStyle,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.translate(
                      'field_sales.admin_kpi_collection_amount',
                    ),
                    textAlign: TextAlign.end,
                    style: headerStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.translate('field_sales.admin_kpi_target_pct_short'),
                    textAlign: TextAlign.end,
                    style: headerStyle,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          for (var i = 0; i < rows.length && i < 20; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].salespersonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${rows[i].visitCount}',
                      textAlign: TextAlign.end,
                      style: valueStyle,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _AdminKpiBody._formatAmount(rows[i].collectionAmount),
                      textAlign: TextAlign.end,
                      style: valueStyle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '%${rows[i].targetPct.toStringAsFixed(0)}',
                      textAlign: TextAlign.end,
                      style: valueStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// {@template _kpi_row}
/// Tek KPI satırı (etiket anahtarı + değer + ikon).
/// {@endtemplate}
class _KpiRow {
  /// [labelKey]: l10n anahtarı
  final String labelKey;

  /// [value]: Gösterilecek sayı metni
  final String value;

  /// [icon]: Kart ikonu
  final IconData icon;

  const _KpiRow({
    required this.labelKey,
    required this.value,
    required this.icon,
  });
}

/// {@template _flat_kpi_card}
/// MBT tarzı düz / yoğun KPI kartı (mevcut field_sales token’ları).
/// {@endtemplate}
class _FlatKpiCard extends StatelessWidget {
  /// [label]: Kart başlığı
  final String label;

  /// [value]: Sayı metni
  final String value;

  /// [icon]: Sol üst ikon
  final IconData icon;

  const _FlatKpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF375A7F)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF375A7F),
              fontSize: value.length > 8 ? 16 : 22,
              fontWeight: FontWeight.bold,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}
