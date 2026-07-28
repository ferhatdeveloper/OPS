// Dosya Adı: whms_reports_screen.dart
// Açıklama: WHMS /whms/reports dens Emir KPI — SQLite + AI insight opt-in
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/ai/widgets/report_ai_insight_banner.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../contract/whms_route_map.dart';
import '../model/whms_order_type.dart';
import '../reports/model/whms_order_kpi_summary.dart';
import '../reports/viewmodel/whms_order_kpi_store.dart';

/// {@template whms_reports_screen}
/// Merkez depo Emir KPI dens dashboard.
/// Route: `/whms/reports`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsReportsScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsReportsScreen extends StatefulWidget {
  /// Named route — `/whms/reports`
  static const String routeName = WhmsRouteMap.whmsReports;

  /// [store]: Test / DI
  final WhmsOrderKpiStore? store;

  /// [initialSummary]: Widget test inject
  final WhmsOrderKpiSummary? initialSummary;

  /// {@macro whms_reports_screen}
  const WhmsReportsScreen({
    super.key,
    this.store,
    this.initialSummary,
  });

  @override
  State<WhmsReportsScreen> createState() => _WhmsReportsScreenState();
}

class _WhmsReportsScreenState extends State<WhmsReportsScreen> {
  late final WhmsOrderKpiStore _store =
      widget.store ?? const WhmsOrderKpiStore();

  WhmsOrderKpiSummary _summary = WhmsOrderKpiSummary.zero;
  bool _loading = true;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialSummary != null) {
      _summary = widget.initialSummary!;
      _loading = false;
    } else {
      _reload();
    }
  }

  /// {@template whms_reports_reload}
  /// SQLite KPI yenile.
  /// {@endtemplate}
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    try {
      final next = await _store.loadSummary();
      if (!mounted) return;
      setState(() {
        _summary = next;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = WhmsOrderKpiSummary.zero;
        _loading = false;
        _errorKey = 'whms.reports.error_hint';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.menu.sub_whms_reports');
    final onBody = FieldSalesDensTheme.title(context);
    final muted = FieldSalesDensTheme.muted(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
                children: [
                  Text(
                    l10n.translate('whms.reports.kpi_subtitle'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate(
                      _errorKey ?? 'whms.reports.kpi_live_hint',
                    ),
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  const SizedBox(height: 6),
                  ReportAiInsightBanner(
                    reportTitle: title,
                    rows: _summary.toInsightRows(),
                  ),
                  const SizedBox(height: 8),
                  _SectionTitle(
                    label: l10n.translate('whms.reports.section_orders'),
                    color: onBody,
                  ),
                  const SizedBox(height: 4),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_total'),
                    value: '${_summary.totalOrders}',
                  ),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_open'),
                    value: '${_summary.openOrders}',
                  ),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_completed'),
                    value: '${_summary.completedOrders}',
                  ),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_draft'),
                    value: '${_summary.draftOrders}',
                  ),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_in_progress'),
                    value: '${_summary.inProgressOrders}',
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle(
                    label: l10n.translate('whms.reports.section_types'),
                    color: onBody,
                  ),
                  const SizedBox(height: 4),
                  if (_summary.typeCounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.translate('whms.reports.types_empty'),
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    )
                  else
                    ..._summary.typeCounts.map((t) {
                      final typeLabel = l10n.translate(
                        WhmsOrderType.fromWire(t.typeWire).l10nKey,
                      );
                      return _MetricRow(
                        label: typeLabel,
                        value: '${t.count}',
                      );
                    }),
                  const SizedBox(height: 10),
                  _SectionTitle(
                    label: l10n.translate('whms.reports.section_count_var'),
                    color: onBody,
                  ),
                  const SizedBox(height: 4),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_count_rows'),
                    value: '${_summary.countResultRows}',
                  ),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_var_sum'),
                    value: _fmtQty(_summary.countVarianceSum),
                  ),
                  _MetricRow(
                    label: l10n.translate('whms.reports.metric_var_abs'),
                    value: _fmtQty(_summary.countVarianceAbsSum),
                  ),
                ],
              ),
            ),
    );
  }

  String _fmtQty(double v) {
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(2);
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionTitle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onBody = FieldSalesDensTheme.title(context);
    final muted = FieldSalesDensTheme.muted(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FieldSalesDensTheme.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onBody,
            ),
          ),
        ],
      ),
    );
  }
}
