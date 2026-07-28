// Dosya Adı: report_layout_designer_screen.dart
// Açıklama: Rapor dizayn dens UI — sütun sıra/göster · sayfa · başlık
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/language_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/mbt_report_catalog.dart';
import '../model/report_layout.dart';
import '../model/report_layout_page_size.dart';
import '../model/report_locale_resolver.dart';
import '../model/report_saved_view.dart';
import '../viewmodel/report_layout_store.dart';

/// {@template report_layout_designer_screen}
/// Mobil + web rapor dizayn editörü (.repx yok).
/// Route: `/field-sales/report-layout` (arguments: report id)
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   ReportLayoutDesignerScreen.routeName,
///   arguments: 'cari_extre',
/// );
/// ```
/// {@endtemplate}
class ReportLayoutDesignerScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/report-layout';

  /// [reportId]: Katalog id
  final String? reportId;

  /// [store]: Test inject
  final ReportLayoutStore? store;

  /// {@macro report_layout_designer_screen}
  const ReportLayoutDesignerScreen({
    Key? key,
    this.reportId,
    this.store,
  }) : super(key: key);

  @override
  State<ReportLayoutDesignerScreen> createState() =>
      _ReportLayoutDesignerScreenState();
}

class _ReportLayoutDesignerScreenState
    extends State<ReportLayoutDesignerScreen> {
  late final ReportLayoutStore _store = widget.store ?? ReportLayoutStore();
  ReportLayout? _layout;
  bool _loading = true;
  bool _saving = false;
  List<ReportSavedView> _savedViews = const [];
  String? _selectedLayoutViewId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadSavedLayoutViews(String reportId) async {
    final views = await _store.listSavedViews(reportId);
    if (!mounted) return;
    setState(() {
      _savedViews = views
          .where((v) => v.kind == ReportSavedViewKind.layout)
          .toList(growable: false);
    });
  }

  Future<void> _saveLayoutAsTemplate() async {
    final layout = _layout;
    final id = widget.reportId;
    if (layout == null || id == null) return;
    final l10n = AppLocalization.of(context);
    final nameCtrl = TextEditingController(
      text: l10n.translate('field_sales.mbt_reports.saved_view_default_name'),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.mbt_reports.saved_view_save_title'),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: l10n.translate(
              'field_sales.mbt_reports.saved_view_name_label',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('common.save')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final view = ReportSavedView.layout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      layout: layout,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _store.upsertSavedView(reportId: id, view: view);
    await _loadSavedLayoutViews(id);
    if (!mounted) return;
    setState(() => _selectedLayoutViewId = view.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.mbt_reports.saved_view_saved'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _applyLayoutTemplate(String? viewId) async {
    final id = widget.reportId;
    if (id == null || viewId == null) {
      setState(() => _selectedLayoutViewId = null);
      return;
    }
    final view = _savedViews.where((v) => v.id == viewId).firstOrNull;
    if (view?.layout == null) return;
    await _persist(view!.layout!);
    setState(() => _selectedLayoutViewId = viewId);
  }

  Future<void> _load() async {
    final id = widget.reportId ?? '';
    if (id.isEmpty || MbtReportCatalog.byId(id) == null) {
      setState(() {
        _layout = null;
        _loading = false;
      });
      return;
    }
    final layout = await _store.load(id);
    if (!mounted) return;
    setState(() {
      _layout = layout;
      _loading = false;
    });
    await _loadSavedLayoutViews(id);
  }

  Future<void> _persist(ReportLayout layout) async {
    setState(() {
      _layout = layout;
      _saving = true;
    });
    try {
      await _store.save(layout);
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.mbt_reports.layout_saved'),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    final id = widget.reportId;
    if (id == null) return;
    final layout = await _store.reset(id);
    if (!mounted) return;
    setState(() => _layout = layout);
    final l10n = AppLocalization.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.mbt_reports.layout_reset_done'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final layout = _layout;

    if (_loading) {
      return Scaffold(
        appBar: FieldSalesDensAppBar(
          title: l10n.translate('field_sales.mbt_reports.layout_designer_title'),
          backgroundColor: FieldSalesDensAppBar.primaryColor,
        ),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (layout == null) {
      return Scaffold(
        appBar: FieldSalesDensAppBar(
          title: l10n.translate('field_sales.mbt_reports.layout_designer_title'),
          backgroundColor: FieldSalesDensAppBar.primaryColor,
        ),
        body: Center(
          child: Text(l10n.translate('field_sales.mbt_reports.not_found')),
        ),
      );
    }

    final reportTitle = l10n.translate(layout.titleKey);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.mbt_reports.layout_designer_title'),
        backgroundColor: FieldSalesDensAppBar.primaryColor,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.restart_alt,
            tooltip: l10n.translate('field_sales.mbt_reports.layout_reset'),
            onPressed: _saving ? null : _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              reportTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_savedViews.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: FieldSalesDensAppBar.primaryColor,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          isDense: true,
                          value: _selectedLayoutViewId,
                          hint: Text(
                            l10n.translate(
                              'field_sales.mbt_reports.saved_view_layout_pick',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                l10n.translate(
                                  'field_sales.mbt_reports.saved_view_none',
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            for (final v in _savedViews)
                              DropdownMenuItem<String?>(
                                value: v.id,
                                child: Text(
                                  v.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                          onChanged: _saving ? null : _applyLayoutTemplate,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FieldSalesDensAppBar.densIconButton(
                    icon: Icons.bookmark_add_outlined,
                    tooltip: l10n.translate(
                      'field_sales.mbt_reports.saved_view_layout_save',
                    ),
                    onPressed: _saving ? null : _saveLayoutAsTemplate,
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate(
                          'field_sales.mbt_reports.layout_page_size',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<ReportLayoutPageSize>(
                        value: layout.pageSize,
                        isDense: true,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(
                            value: ReportLayoutPageSize.a4,
                            child: Text(
                              l10n.translate(
                                'field_sales.mbt_reports.layout_page_a4',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: ReportLayoutPageSize.a5,
                            child: Text(
                              l10n.translate(
                                'field_sales.mbt_reports.layout_page_a5',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: ReportLayoutPageSize.letter,
                            child: Text(
                              l10n.translate(
                                'field_sales.mbt_reports.layout_page_letter',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: ReportLayoutPageSize.thermal80,
                            child: Text(
                              l10n.translate(
                                'field_sales.mbt_reports.layout_page_80mm',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) {
                                if (v == null) return;
                                _persist(layout.copyWith(pageSize: v));
                              },
                      ),
                    ],
                  ),
                ),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate(
                          'field_sales.mbt_reports.layout_language',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String?>(
                        value: ReportLocaleResolver.normalize(layout.locale),
                        isDense: true,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              l10n.translate(
                                'field_sales.mbt_reports.layout_language_default',
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          ...LanguageService.supportedLanguages
                              .where(
                                (lang) => ReportLocaleResolver.supportedCodes
                                    .contains(lang.code),
                              )
                              .map(
                                (lang) => DropdownMenuItem<String?>(
                                  value: lang.code,
                                  child: Text(
                                    lang.localName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) {
                                if (v == null) {
                                  _persist(layout.copyWith(clearLocale: true));
                                } else {
                                  _persist(layout.copyWith(locale: v));
                                }
                              },
                      ),
                    ],
                  ),
                ),
                _switchCard(
                  l10n.translate('field_sales.mbt_reports.layout_show_header'),
                  layout.showHeader,
                  (v) => _persist(layout.copyWith(showHeader: v)),
                ),
                _switchCard(
                  l10n.translate('field_sales.mbt_reports.layout_show_footer'),
                  layout.showFooter,
                  (v) => _persist(layout.copyWith(showFooter: v)),
                ),
                _switchCard(
                  l10n.translate('field_sales.mbt_reports.layout_show_totals'),
                  layout.showTotals,
                  (v) => _persist(layout.copyWith(showTotals: v)),
                ),
                _switchCard(
                  l10n.translate('field_sales.mbt_reports.layout_density'),
                  layout.dense,
                  (v) => _persist(layout.copyWith(dense: v)),
                ),
                    Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
                  child: Text(
                    l10n.translate('field_sales.mbt_reports.layout_all_fields'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
                  child: Text(
                    l10n.translate(
                      'field_sales.mbt_reports.layout_all_fields_hint',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: layout.columns.length,
                  onReorder: (oldIndex, newIndex) {
                    if (_saving) return;
                    _persist(layout.reorderColumns(oldIndex, newIndex));
                  },
                  itemBuilder: (context, index) {
                    final col = layout.columns[index];
                    return _card(
                      key: ValueKey(col.id),
                      child: Row(
                        children: [
                          Icon(
                            Icons.drag_handle,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.translate(col.titleKey),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Switch.adaptive(
                            value: col.visible,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: _saving
                                ? null
                                : (v) => _persist(
                                      layout.toggleColumn(col.id, visible: v),
                                    ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCard(String label, bool value, ValueChanged<bool> onChanged) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Switch.adaptive(
            value: value,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: _saving ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _card({Key? key, required Widget child}) {
    return Container(
      key: key,
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
}
