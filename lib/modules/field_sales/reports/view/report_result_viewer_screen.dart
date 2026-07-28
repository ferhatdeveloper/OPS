// Dosya Adı: report_result_viewer_screen.dart
// Açıklama: Ortak MBT rapor sonuç kabuğu — Liste / Grafik / Pivot dens sekmeler
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../ai/widgets/report_ai_insight_banner.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../engine/mbt_report_action_service.dart';
import '../model/mbt_report_catalog.dart';
import '../model/mbt_report_category.dart';
import '../model/report_chart_kind.dart';
import '../model/report_layout.dart';
import '../model/report_layout_defaults.dart';
import '../viewmodel/report_layout_store.dart';
import 'report_result_chart_pane.dart';
import 'report_result_list_pane.dart';
import 'report_result_pivot_pane.dart';

/// {@template report_result_tab}
/// Sonuç kabuğu sekmesi.
/// {@endtemplate}
enum ReportResultTab {
  /// Dens liste (+ PDF AppBar)
  list,

  /// fl_chart grafik
  chart,

  /// Pivot tablo
  pivot,
}

/// {@template report_result_viewer_screen}
/// Tüm MBT raporları için ortak Görüntüle kabuğu.
///
/// Parametreler → sarı Görüntüle sonrası Liste | Grafik | Pivot.
/// Aynı [ReportLayout] + query satırlarından üretilir.
///
/// Kullanım örneği:
/// ```dart
/// ReportResultViewerScreen(
///   reportId: 'cari_extre',
///   title: 'Cari Extre',
///   category: MbtReportCategory.cari,
///   snapshot: snapshot,
///   rows: rows,
/// );
/// ```
/// {@endtemplate}
class ReportResultViewerScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/report-result';

  /// [reportId]: Katalog id
  final String reportId;

  /// [title]: AppBar / PDF başlık
  final String title;

  /// [category]: Grafik türü için aile
  final MbtReportCategory category;

  /// [snapshot]: Parametre anlık görüntüsü
  final MbtReportParamSnapshot snapshot;

  /// [rows]: Layout sütun id → değer
  final List<Map<String, String>> rows;

  /// [layout]: Test inject
  final ReportLayout? layout;

  /// [actionService]: PDF inject
  final MbtReportActionService? actionService;

  /// [layoutStore]: SharedPreferences layout
  final ReportLayoutStore? layoutStore;

  /// [initialTab]: Başlangıç sekmesi
  final ReportResultTab initialTab;

  /// {@macro report_result_viewer_screen}
  const ReportResultViewerScreen({
    Key? key,
    required this.reportId,
    required this.title,
    required this.category,
    required this.snapshot,
    required this.rows,
    this.layout,
    this.actionService,
    this.layoutStore,
    this.initialTab = ReportResultTab.list,
  }) : super(key: key);

  @override
  State<ReportResultViewerScreen> createState() =>
      _ReportResultViewerScreenState();
}

class _ReportResultViewerScreenState extends State<ReportResultViewerScreen> {
  late final ReportLayoutStore _store =
      widget.layoutStore ?? ReportLayoutStore();
  ReportLayout? _layout;
  bool _busy = false;
  late ReportResultTab _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    if (widget.layout != null) {
      setState(() => _layout = widget.layout);
      return;
    }
    final loaded = await _store.load(widget.reportId);
    if (!mounted) return;
    setState(() => _layout = loaded);
  }

  Future<void> _openPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final l10n = AppLocalization.of(context);
      final report = MbtReportCatalog.byId(widget.reportId);
      if (report == null) return;
      final actions = widget.actionService ??
          MbtReportActionService(
            layoutStore: _store,
            resolveTitle: l10n.translate,
          );
      await actions.viewPdf(
        report: report,
        title: widget.title,
        snapshot: widget.snapshot,
        layout: _layout,
        rows: widget.rows,
        languageCode: l10n.locale.languageCode,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final resolved =
        _layout ?? ReportLayoutDefaults.forReportId(widget.reportId);
    final chartKind = ReportChartKindX.forCategory(widget.category);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: widget.title,
        backgroundColor: FieldSalesDensAppBar.primaryColor,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.picture_as_pdf,
            onPressed: _busy ? null : _openPdf,
            tooltip: l10n.translate('field_sales.mbt_reports.action_view_pdf'),
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          backgroundColor: FieldSalesDensTheme.surface(context),
          children: [
            FieldSalesDensChipRow(
              fontSize: 11,
              items: [
                FieldSalesDensChipItem(
                  label: l10n.translate(
                    'field_sales.mbt_reports.tab_list',
                  ),
                  selected: _tab == ReportResultTab.list,
                  onTap: () => setState(() => _tab = ReportResultTab.list),
                ),
                FieldSalesDensChipItem(
                  label: l10n.translate(
                    'field_sales.mbt_reports.tab_chart',
                  ),
                  selected: _tab == ReportResultTab.chart,
                  onTap: () => setState(() => _tab = ReportResultTab.chart),
                ),
                FieldSalesDensChipItem(
                  label: l10n.translate(
                    'field_sales.mbt_reports.tab_pivot',
                  ),
                  selected: _tab == ReportResultTab.pivot,
                  onTap: () => setState(() => _tab = ReportResultTab.pivot),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          ReportAiInsightBanner(
            reportTitle: widget.title,
            rows: widget.rows,
          ),
          Expanded(
            child: switch (_tab) {
              ReportResultTab.list => ReportResultListPane(
                  layout: resolved,
                  rows: widget.rows,
                ),
              ReportResultTab.chart => ReportResultChartPane(
                  layout: resolved,
                  rows: widget.rows,
                  kind: chartKind,
                ),
              ReportResultTab.pivot => ReportResultPivotPane(
                  reportId: widget.reportId,
                  layout: resolved,
                  rows: widget.rows,
                ),
            },
          ),
        ],
      ),
    );
  }
}
