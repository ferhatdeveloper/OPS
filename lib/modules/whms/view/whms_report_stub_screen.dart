// Dosya Adı: whms_report_stub_screen.dart
// Açıklama: WHMS dens rapor stub (emir performans / sayım fark)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../reports/model/whms_order_kpi_summary.dart';
import '../reports/viewmodel/whms_order_kpi_store.dart';

/// {@template whms_report_stub_screen}
/// KPI store’dan özet gösteren dens rapor stub.
/// {@endtemplate}
class WhmsReportStubScreen extends StatefulWidget {
  /// Named route
  final String routeName;

  /// Başlık l10n
  final String titleKey;

  /// Açıklama l10n
  final String hintKey;

  /// `order_perf` | `count_var`
  final String kind;

  /// Store inject
  final WhmsOrderKpiStore? store;

  /// {@macro whms_report_stub_screen}
  const WhmsReportStubScreen({
    super.key,
    required this.routeName,
    required this.titleKey,
    required this.hintKey,
    required this.kind,
    this.store,
  });

  @override
  State<WhmsReportStubScreen> createState() => _WhmsReportStubScreenState();
}

class _WhmsReportStubScreenState extends State<WhmsReportStubScreen> {
  late final WhmsOrderKpiStore _store =
      widget.store ?? const WhmsOrderKpiStore();
  WhmsOrderKpiSummary _summary = WhmsOrderKpiSummary.zero;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate(widget.titleKey),
        showCalculatorHome: false,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
          children: [
            Text(
              l10n.translate(widget.hintKey),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              if (widget.kind == 'order_perf') ...[
                _metric(
                  isDark,
                  l10n.translate('whms.reports.metric_total'),
                  '${_summary.totalOrders}',
                ),
                _metric(
                  isDark,
                  l10n.translate('whms.reports.metric_completed'),
                  '${_summary.completedOrders}',
                ),
                _metric(
                  isDark,
                  l10n.translate('whms.reports.metric_open'),
                  '${_summary.openOrders}',
                ),
              ] else ...[
                _metric(
                  isDark,
                  l10n.translate('whms.reports.metric_count_rows'),
                  '${_summary.countResultRows}',
                ),
                _metric(
                  isDark,
                  l10n.translate('whms.reports.metric_var_sum'),
                  _summary.countVarianceSum.toStringAsFixed(2),
                ),
                _metric(
                  isDark,
                  l10n.translate('whms.reports.metric_var_abs'),
                  _summary.countVarianceAbsSum.toStringAsFixed(2),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
