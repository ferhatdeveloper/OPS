// Dosya Adı: report_parameters_screen.dart
// Açıklama: MBT rapor Parametreler dens — preset · alanlar · PDF/Paylaş/E-posta
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../customers/model/customer_model.dart';
import '../../orders/view/order_customer_selection_screen.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../cari/cari_report_filter.dart';
import '../cari/cari_report_ids.dart';
import '../cari/cari_report_query_service.dart';
import '../documents/document_report_filter.dart';
import '../documents/document_report_ids.dart';
import '../engine/mbt_report_action_service.dart';
import '../engine/mbt_report_data_service.dart';
import '../model/mbt_report_catalog.dart';
import '../model/mbt_report_definition.dart';
import '../model/mbt_report_param_field.dart';
import '../model/report_locale_resolver.dart';
import '../viewmodel/report_language_preference_store.dart';
import '../viewmodel/report_layout_store.dart';
import 'report_layout_designer_screen.dart';
import 'report_result_viewer_screen.dart';

/// {@template report_date_preset}
/// Tarih hızlı seçim: Bugün / Bu Hafta / Bu Ay / Bu Yıl.
/// {@endtemplate}
enum ReportDatePreset {
  /// Bugün
  today,

  /// Bu hafta (Pzt–bugün)
  thisWeek,

  /// Bu ay
  thisMonth,

  /// Bu yıl
  thisYear,
}

/// {@template report_parameters_screen}
/// Rapor Parametreler dens ekranı.
/// Route: `/field-sales/report-params` (arguments: report id String)
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   ReportParametersScreen.routeName,
///   arguments: 'cari_extre',
/// );
/// ```
/// {@endtemplate}
class ReportParametersScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/report-params';

  /// [reportId]: Katalog id (veya [report] inject)
  final String? reportId;

  /// [report]: Test inject
  final MbtReportDefinition? report;

  /// [actionService]: Aksiyon inject
  final MbtReportActionService? actionService;

  /// [layoutStore]: Dizayn store inject
  final ReportLayoutStore? layoutStore;

  /// [dataService]: SQLite satır kaynağı inject (test)
  final MbtReportDataService? dataService;

  /// {@macro report_parameters_screen}
  const ReportParametersScreen({
    Key? key,
    this.reportId,
    this.report,
    this.actionService,
    this.layoutStore,
    this.dataService,
  }) : super(key: key);

  @override
  State<ReportParametersScreen> createState() => _ReportParametersScreenState();
}

class _ReportParametersScreenState extends State<ReportParametersScreen> {
  late final ReportLayoutStore _layoutStore =
      widget.layoutStore ?? ReportLayoutStore();

  MbtReportDefinition? _report;
  ReportDatePreset _preset = ReportDatePreset.thisYear;
  DateTime _dateFrom = DateTime(DateTime.now().year, 1, 1);
  DateTime _dateTo = DateTime(DateTime.now().year, 12, 31);

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _code2Ctrl = TextEditingController();
  final _name2Ctrl = TextEditingController();
  final _cariCodeCtrl = TextEditingController();
  final _cariNameCtrl = TextEditingController();
  final _cariCode2Ctrl = TextEditingController();
  final _cariName2Ctrl = TextEditingController();
  final _stockCodeCtrl = TextEditingController();
  final _stockNameCtrl = TextEditingController();
  final _stockCode2Ctrl = TextEditingController();
  final _stockName2Ctrl = TextEditingController();
  final _currencyCodeCtrl = TextEditingController(text: 'Tüm');
  final _specialCtrls =
      List.generate(5, (_) => TextEditingController(), growable: false);

  bool _currencyValuation = false;
  bool _reportingCurrency = false;
  bool _gtZero = false;
  bool _ltZero = false;
  bool _eqZero = false;
  bool _selectionSale = true;
  String _workplace = 'Merkez';
  String _factory = 'Merkez';
  String _warehouse = 'Merkez';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report ?? MbtReportCatalog.byId(widget.reportId);
    _applyPreset(ReportDatePreset.thisYear);
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final id = _report?.id;
    if (id == null) return;
    await _layoutStore.load(id);
  }

  Future<void> _openDesigner() async {
    final id = _report?.id;
    if (id == null) return;
    await Navigator.of(context).pushNamed(
      ReportLayoutDesignerScreen.routeName,
      arguments: id,
    );
    if (!mounted) return;
    await _loadLayout();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _code2Ctrl.dispose();
    _name2Ctrl.dispose();
    _cariCodeCtrl.dispose();
    _cariNameCtrl.dispose();
    _cariCode2Ctrl.dispose();
    _cariName2Ctrl.dispose();
    _stockCodeCtrl.dispose();
    _stockNameCtrl.dispose();
    _stockCode2Ctrl.dispose();
    _stockName2Ctrl.dispose();
    _currencyCodeCtrl.dispose();
    for (final c in _specialCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(ReportDatePreset preset) {
    final now = DateTime.now();
    late DateTime from;
    late DateTime to;
    switch (preset) {
      case ReportDatePreset.today:
        from = DateTime(now.year, now.month, now.day);
        to = from;
        break;
      case ReportDatePreset.thisWeek:
        final weekday = now.weekday; // 1=Mon
        from = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        to = DateTime(now.year, now.month, now.day);
        break;
      case ReportDatePreset.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month, now.day);
        break;
      case ReportDatePreset.thisYear:
        from = DateTime(now.year, 1, 1);
        to = DateTime(now.year, 12, 31);
        break;
    }
    setState(() {
      _preset = preset;
      _dateFrom = from;
      _dateTo = to;
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _dateFrom = picked;
        if (_dateFrom.isAfter(_dateTo)) _dateTo = _dateFrom;
      } else {
        _dateTo = picked;
        if (_dateTo.isBefore(_dateFrom)) _dateFrom = _dateTo;
      }
    });
  }

  bool _has(MbtReportParamKind kind) {
    final fields = _report?.fields ?? const <MbtReportParamField>[];
    return fields.any((f) => f.kind == kind);
  }

  MbtReportParamSnapshot _snapshot(AppLocalization l10n) {
    final extra = <String, String>{};
    if (_has(MbtReportParamKind.selectionSalePurchase)) {
      extra[l10n.translate('field_sales.mbt_reports.param_selection')] =
          _selectionSale
              ? l10n.translate('field_sales.mbt_reports.selection_sale')
              : l10n.translate('field_sales.mbt_reports.selection_purchase');
    }
    if (_has(MbtReportParamKind.workplaceFactoryWarehouse)) {
      extra[l10n.translate('field_sales.mbt_reports.param_workplace')] =
          _workplace;
      extra[l10n.translate('field_sales.mbt_reports.param_factory')] = _factory;
      extra[l10n.translate('field_sales.mbt_reports.param_warehouse')] =
          _warehouse;
    }
    return MbtReportParamSnapshot(
      dateFrom: _has(MbtReportParamKind.dateRange) ||
              _has(MbtReportParamKind.dateEnd)
          ? (_has(MbtReportParamKind.dateEnd) &&
                  !_has(MbtReportParamKind.dateRange)
              ? _dateTo
              : _dateFrom)
          : null,
      dateTo: _has(MbtReportParamKind.dateRange) ||
              _has(MbtReportParamKind.dateEnd)
          ? _dateTo
          : null,
      code: _resolvedCode(),
      name: _resolvedName(),
      code2: _resolvedCode2(),
      name2: _resolvedName2(),
      warehouse: _warehouse,
      gtZero: _gtZero,
      ltZero: _ltZero,
      eqZero: _eqZero,
      extraLines: extra,
    );
  }

  /// Serbest KOD yoksa cari seçim kodunu query param’a yazar.
  String _resolvedCode() {
    if (_has(MbtReportParamKind.codeName)) {
      return _codeCtrl.text.trim();
    }
    if (_has(MbtReportParamKind.cariCodeName)) {
      return _cariCodeCtrl.text.trim();
    }
    return '';
  }

  /// Serbest AD yoksa cari seçim adını query param’a yazar.
  String _resolvedName() {
    if (_has(MbtReportParamKind.codeName)) {
      return _nameCtrl.text.trim();
    }
    if (_has(MbtReportParamKind.cariCodeName)) {
      return _cariNameCtrl.text.trim();
    }
    return '';
  }

  /// Kod 2 — serbest veya cari aralık bitiş.
  String _resolvedCode2() {
    if (_has(MbtReportParamKind.codeName2)) {
      return _code2Ctrl.text.trim();
    }
    if (_has(MbtReportParamKind.cariCodeName2)) {
      return _cariCode2Ctrl.text.trim();
    }
    return '';
  }

  /// Ad 2 — serbest veya cari aralık bitiş.
  String _resolvedName2() {
    if (_has(MbtReportParamKind.codeName2)) {
      return _name2Ctrl.text.trim();
    }
    if (_has(MbtReportParamKind.cariCodeName2)) {
      return _cariName2Ctrl.text.trim();
    }
    return '';
  }

  MbtReportActionService _resolveActions(AppLocalization l10n) {
    return widget.actionService ??
        MbtReportActionService(
          layoutStore: _layoutStore,
          resolveTitle: l10n.translate,
        );
  }

  /// Dizayn → ayarlar → uygulama dili zinciri.
  Future<({String languageCode, AppLocalization reportL10n})>
      _resolveReportLocale(AppLocalization appL10n) async {
    final layout = _report == null
        ? null
        : await _layoutStore.load(_report!.id);
    final settingsDefault =
        await const ReportLanguagePreferenceStore().load();
    final languageCode = ReportLocaleResolver.resolve(
      layoutLocale: layout?.locale,
      settingsDefault: settingsDefault,
      appLocale: appL10n.locale.languageCode,
    );
    final reportL10n =
        await AppLocalization.loadForLanguageCode(languageCode);
    return (languageCode: languageCode, reportL10n: reportL10n);
  }

  MbtReportDataService _resolveDataService() {
    return widget.dataService ?? const MbtReportDataService();
  }

  Future<List<Map<String, String>>> _loadReportRows(
    MbtReportDefinition report,
    MbtReportParamSnapshot snapshot,
  ) async {
    if (CariReportIds.handles(report.id)) {
      try {
        final dbService = await DatabaseService.getInstance();
        final db = await dbService.getDatabase();
        return const CariReportQueryService().fetchRows(
          db: db,
          reportId: report.id,
          filter: CariReportFilter(
            dateFrom: snapshot.dateFrom,
            dateTo: snapshot.dateTo,
            code: snapshot.code,
            name: snapshot.name,
          ),
        );
      } catch (_) {
        return const [];
      }
    }
    DocumentReportFilter? docFilter;
    if (DocumentReportIds.handles(report.id)) {
      docFilter = DocumentReportFilter(
        dateFrom: snapshot.dateFrom,
        dateTo: snapshot.dateTo,
        code: snapshot.code,
        name: snapshot.name,
        cariCode: _cariCodeCtrl.text.trim(),
        cariName: _cariNameCtrl.text.trim(),
        stockCode: _stockCodeCtrl.text.trim().isNotEmpty
            ? _stockCodeCtrl.text.trim()
            : _stockCode2Ctrl.text.trim(),
        stockName: _stockNameCtrl.text.trim().isNotEmpty
            ? _stockNameCtrl.text.trim()
            : _stockName2Ctrl.text.trim(),
        warehouse: _warehouse,
      );
    }
    return _resolveDataService().fetchRows(
      reportId: report.id,
      snapshot: snapshot,
      documentFilter: docFilter,
    );
  }

  Future<void> _runAction(
    Future<void> Function(
      MbtReportActionService actions,
      List<Map<String, String>> rows,
    ) action,
  ) async {
    if (_busy || _report == null) return;
    setState(() => _busy = true);
    try {
      final l10n = AppLocalization.of(context);
      final snapshot = _snapshot(l10n);
      final rows = await _loadReportRows(_report!, snapshot);
      await action(_resolveActions(l10n), rows);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.mbt_reports.action_failed'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: FieldSalesDensAppBar(
          title: l10n.translate('field_sales.mbt_reports.parameters_title'),
          backgroundColor: FieldSalesDensAppBar.primaryColor,
        ),
        body: Center(
          child: Text(l10n.translate('field_sales.mbt_reports.not_found')),
        ),
      );
    }

    final title = l10n.translate(report.titleKey);
    final df = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.mbt_reports.parameters_title'),
        backgroundColor: FieldSalesDensAppBar.primaryColor,
      ),
      body: Column(
        children: [
          if (_has(MbtReportParamKind.dateRange)) _buildPresets(l10n),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              children: [
                if (_has(MbtReportParamKind.dateRange)) ...[
                  _dateRow(
                    l10n.translate('field_sales.mbt_reports.param_start'),
                    df.format(_dateFrom),
                    () => _pickDate(from: true),
                  ),
                  _dateRow(
                    l10n.translate('field_sales.mbt_reports.param_end'),
                    df.format(_dateTo),
                    () => _pickDate(from: false),
                  ),
                ],
                if (_has(MbtReportParamKind.dateEnd) &&
                    !_has(MbtReportParamKind.dateRange))
                  _dateRow(
                    l10n.translate('field_sales.mbt_reports.param_end'),
                    df.format(_dateTo),
                    () => _pickDate(from: false),
                  ),
                if (_has(MbtReportParamKind.selectionSalePurchase))
                  _card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.translate(
                              'field_sales.mbt_reports.param_selection',
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownButton<bool>(
                          value: _selectionSale,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          items: [
                            DropdownMenuItem(
                              value: true,
                              child: Text(
                                l10n.translate(
                                  'field_sales.mbt_reports.selection_sale',
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text(
                                l10n.translate(
                                  'field_sales.mbt_reports.selection_purchase',
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectionSale = v);
                          },
                        ),
                      ],
                    ),
                  ),
                if (_has(MbtReportParamKind.workplaceFactoryWarehouse)) ...[
                  _simpleField(
                    l10n.translate('field_sales.mbt_reports.param_workplace'),
                    _workplace,
                    (v) => setState(() => _workplace = v),
                  ),
                  _simpleField(
                    l10n.translate('field_sales.mbt_reports.param_factory'),
                    _factory,
                    (v) => setState(() => _factory = v),
                  ),
                  _simpleField(
                    l10n.translate('field_sales.mbt_reports.param_warehouse'),
                    _warehouse,
                    (v) => setState(() => _warehouse = v),
                  ),
                ],
                if (_has(MbtReportParamKind.stockCodeName))
                  _codeNameCard(
                    codeLabel: l10n
                        .translate('field_sales.mbt_reports.param_stock_code'),
                    nameLabel: l10n
                        .translate('field_sales.mbt_reports.param_stock_name'),
                    codeCtrl: _stockCodeCtrl,
                    nameCtrl: _stockNameCtrl,
                  ),
                if (_has(MbtReportParamKind.stockCodeName2))
                  _codeNameCard(
                    codeLabel: l10n.translate(
                      'field_sales.mbt_reports.param_stock_code2',
                    ),
                    nameLabel: l10n.translate(
                      'field_sales.mbt_reports.param_stock_name2',
                    ),
                    codeCtrl: _stockCode2Ctrl,
                    nameCtrl: _stockName2Ctrl,
                  ),
                if (_has(MbtReportParamKind.codeName))
                  _codeNameCard(
                    codeLabel:
                        l10n.translate('field_sales.mbt_reports.param_code'),
                    nameLabel:
                        l10n.translate('field_sales.mbt_reports.param_name'),
                    codeCtrl: _codeCtrl,
                    nameCtrl: _nameCtrl,
                  ),
                if (_has(MbtReportParamKind.codeName2))
                  _codeNameCard(
                    codeLabel:
                        l10n.translate('field_sales.mbt_reports.param_code2'),
                    nameLabel:
                        l10n.translate('field_sales.mbt_reports.param_name2'),
                    codeCtrl: _code2Ctrl,
                    nameCtrl: _name2Ctrl,
                  ),
                if (_has(MbtReportParamKind.cariCodeName))
                  _cariPickerRow(
                    l10n,
                    labelKey: 'field_sales.mbt_reports.param_cari_select',
                    codeCtrl: _cariCodeCtrl,
                    nameCtrl: _cariNameCtrl,
                  ),
                if (_has(MbtReportParamKind.cariCodeName2))
                  _cariPickerRow(
                    l10n,
                    labelKey: 'field_sales.mbt_reports.param_cari_select2',
                    codeCtrl: _cariCode2Ctrl,
                    nameCtrl: _cariName2Ctrl,
                  ),
                if (_has(MbtReportParamKind.currencyValuation))
                  _switchRow(
                    l10n.translate(
                      'field_sales.mbt_reports.param_currency_valuation',
                    ),
                    _currencyValuation,
                    (v) => setState(() => _currencyValuation = v),
                  ),
                if (_has(MbtReportParamKind.currencyCode))
                  _textRow(
                    l10n.translate('field_sales.mbt_reports.param_currency_code'),
                    _currencyCodeCtrl,
                  ),
                if (_has(MbtReportParamKind.reportingCurrency))
                  _switchRow(
                    l10n.translate(
                      'field_sales.mbt_reports.param_reporting_currency',
                    ),
                    _reportingCurrency,
                    (v) => setState(() => _reportingCurrency = v),
                  ),
                if (_has(MbtReportParamKind.balanceFilters)) ...[
                  _switchRow(
                    l10n.translate('field_sales.mbt_reports.param_gt_zero'),
                    _gtZero,
                    (v) => setState(() => _gtZero = v),
                  ),
                  _switchRow(
                    l10n.translate('field_sales.mbt_reports.param_lt_zero'),
                    _ltZero,
                    (v) => setState(() => _ltZero = v),
                  ),
                  _switchRow(
                    l10n.translate('field_sales.mbt_reports.param_eq_zero'),
                    _eqZero,
                    (v) => setState(() => _eqZero = v),
                  ),
                ],
                if (_has(MbtReportParamKind.specialCodes))
                  for (var i = 0; i < 5; i++)
                    _textRow(
                      l10n.translate(
                        'field_sales.mbt_reports.param_special_code',
                        args: {'n': '${i + 1}'},
                      ),
                      _specialCtrls[i],
                    ),
                if (_has(MbtReportParamKind.designFile))
                  _card(
                    child: InkWell(
                      onTap: _openDesigner,
                      child: Row(
                        children: [
                          Text(
                            l10n.translate(
                              'field_sales.mbt_reports.param_design_file',
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.mbt_reports.layout_edit',
                              ),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildActions(l10n, report, title),
        ],
      ),
    );
  }

  Widget _buildPresets(AppLocalization l10n) {
    final items = <MapEntry<ReportDatePreset, String>>[
      MapEntry(
        ReportDatePreset.today,
        l10n.translate('field_sales.mbt_reports.preset_today'),
      ),
      MapEntry(
        ReportDatePreset.thisWeek,
        l10n.translate('field_sales.mbt_reports.preset_week'),
      ),
      MapEntry(
        ReportDatePreset.thisMonth,
        l10n.translate('field_sales.mbt_reports.preset_month'),
      ),
      MapEntry(
        ReportDatePreset.thisYear,
        l10n.translate('field_sales.mbt_reports.preset_year'),
      ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 0),
      child: FieldSalesDensChipRow(
        primary: FieldSalesDensAppBar.primaryColor,
        fontSize: 11,
        items: [
          for (final e in items)
            FieldSalesDensChipItem(
              label: e.value,
              selected: _preset == e.key,
              onTap: () => _applyPreset(e.key),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(
    AppLocalization l10n,
    MbtReportDefinition report,
    String title,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _fab(
              color: const Color(0xFFE53935),
              icon: Icons.picture_as_pdf,
              label: l10n.translate('field_sales.mbt_reports.action_view_pdf'),
              onTap: _busy
                  ? null
                  : () => _runAction(
                        (actions, rows) async {
                          final resolved = await _resolveReportLocale(l10n);
                          final pdfTitle = resolved.reportL10n
                              .translate(report.titleKey);
                          final pdfActions = widget.actionService ??
                              MbtReportActionService(
                                layoutStore: _layoutStore,
                                resolveTitle: resolved.reportL10n.translate,
                              );
                          await pdfActions.viewPdf(
                            report: report,
                            title: pdfTitle,
                            snapshot: _snapshot(l10n),
                            rows: rows,
                            languageCode: resolved.languageCode,
                          );
                        },
                      ),
            ),
            _fab(
              color: const Color(0xFF1E88E5),
              icon: Icons.share,
              label: l10n.translate('field_sales.mbt_reports.action_share'),
              onTap: _busy
                  ? null
                  : () => _runAction(
                        (actions, rows) async {
                          final resolved = await _resolveReportLocale(l10n);
                          final pdfTitle = resolved.reportL10n
                              .translate(report.titleKey);
                          final pdfActions = widget.actionService ??
                              MbtReportActionService(
                                layoutStore: _layoutStore,
                                resolveTitle: resolved.reportL10n.translate,
                              );
                          await pdfActions.sharePdf(
                            report: report,
                            title: pdfTitle,
                            snapshot: _snapshot(l10n),
                            subject: pdfTitle,
                            text: resolved.reportL10n.translate(
                              'field_sales.mbt_reports.share_text',
                            ),
                            rows: rows,
                            languageCode: resolved.languageCode,
                          );
                        },
                      ),
            ),
            _fab(
              color: const Color(0xFF29B6F6),
              icon: Icons.alternate_email,
              label: l10n.translate('field_sales.mbt_reports.action_email'),
              onTap: _busy
                  ? null
                  : () => _runAction(
                        (actions, rows) async {
                          final resolved = await _resolveReportLocale(l10n);
                          final pdfTitle = resolved.reportL10n
                              .translate(report.titleKey);
                          final pdfActions = widget.actionService ??
                              MbtReportActionService(
                                layoutStore: _layoutStore,
                                resolveTitle: resolved.reportL10n.translate,
                              );
                          await pdfActions.emailPdf(
                            report: report,
                            title: pdfTitle,
                            snapshot: _snapshot(l10n),
                            subject: pdfTitle,
                            body: resolved.reportL10n.translate(
                              'field_sales.mbt_reports.share_text',
                            ),
                            rows: rows,
                            languageCode: resolved.languageCode,
                          );
                        },
                      ),
            ),
            _fab(
              color: const Color(0xFFFDD835),
              icon: Icons.bar_chart,
              iconColor: Colors.black87,
              label: l10n.translate('field_sales.mbt_reports.action_view'),
              onTap: _busy
                  ? null
                  : () => _runAction(
                        (actions, rows) async {
                          final resolved = await _resolveReportLocale(l10n);
                          final pdfTitle = resolved.reportL10n
                              .translate(report.titleKey);
                          if (!mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ReportResultViewerScreen(
                                reportId: report.id,
                                title: pdfTitle,
                                category: report.category,
                                snapshot: _snapshot(l10n),
                                rows: rows,
                                layoutStore: _layoutStore,
                                actionService: widget.actionService ??
                                    MbtReportActionService(
                                      layoutStore: _layoutStore,
                                      resolveTitle:
                                          resolved.reportL10n.translate,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab({
    required Color color,
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _dateRow(String label, String value, VoidCallback onTap) {
    return _card(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(value, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return _card(
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _textRow(String label, TextEditingController ctrl) {
    return _card(
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return _card(
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          SizedBox(
            width: 120,
            child: TextFormField(
              initialValue: value,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeNameCard({
    required String codeLabel,
    required String nameLabel,
    required TextEditingController codeCtrl,
    required TextEditingController nameCtrl,
  }) {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(codeLabel, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                child: TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(nameLabel, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dens cari seçim satırı — boşsa «Tüm», dokununca müşteri listesi.
  Widget _cariPickerRow(
    AppLocalization l10n, {
    required String labelKey,
    required TextEditingController codeCtrl,
    required TextEditingController nameCtrl,
  }) {
    final code = codeCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final hasSelection = code.isNotEmpty || name.isNotEmpty;
    final display = hasSelection
        ? (code.isEmpty ? name : (name.isEmpty ? code : '$code — $name'))
        : l10n.translate('field_sales.mbt_reports.param_all');
    return _card(
      child: InkWell(
        onTap: () => _pickCustomer(codeCtrl: codeCtrl, nameCtrl: nameCtrl),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.translate(labelKey),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Flexible(
              child: Text(
                display,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: hasSelection
                      ? Colors.black87
                      : Colors.grey.shade700,
                ),
              ),
            ),
            if (hasSelection)
              FieldSalesDensAppBar.densIconButton(
                icon: Icons.clear,
                tooltip: l10n.translate('field_sales.mbt_reports.param_all'),
                onPressed: () {
                  setState(() {
                    codeCtrl.clear();
                    nameCtrl.clear();
                  });
                },
              )
            else
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.grey.shade600,
              ),
          ],
        ),
      ),
    );
  }

  /// Mevcut OrderCustomerSelectionScreen ile cari seçer.
  Future<void> _pickCustomer({
    required TextEditingController codeCtrl,
    required TextEditingController nameCtrl,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderCustomerSelectionScreen(
          selectHintKey: 'field_sales.mbt_reports.param_cari_select_hint',
          onCustomerSelected: (ctx, CustomerModel customer) {
            final pickedCode =
                (customer.code ?? customer.displayCodeOrTax).trim();
            final pickedName = customer.name.trim();
            Navigator.of(ctx).pop();
            if (!mounted) return;
            setState(() {
              codeCtrl.text = pickedCode;
              nameCtrl.text = pickedName;
            });
          },
        ),
      ),
    );
  }
}
