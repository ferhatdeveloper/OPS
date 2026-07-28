// Dosya Adı: report_result_pivot_pane.dart
// Açıklama: Rapor sonuç dens Pivot sekmesi (boyut seçici + DataTable)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../engine/report_pivot_aggregator.dart';
import '../model/report_layout.dart';
import '../model/report_layout_column.dart';
import '../model/report_saved_view.dart';
import '../viewmodel/report_layout_store.dart';
import '../viewmodel/report_pivot_preference_store.dart';
import 'report_dens_empty_state.dart';

/// {@template report_result_pivot_pane}
/// Satır / sütun / ölçü seçicili dens pivot tablo.
/// Rapor id başına varsayılan görünüm SharedPreferences’te saklanır.
///
/// Kullanım örneği:
/// ```dart
/// ReportResultPivotPane(
///   reportId: 'cari_extre',
///   layout: layout,
///   rows: rows,
/// )
/// ```
/// {@endtemplate}
class ReportResultPivotPane extends StatefulWidget {
  /// [reportId]: Katalog id (pivot tercih anahtarı)
  final String reportId;

  /// [layout]: Alan kaynağı
  final ReportLayout layout;

  /// [rows]: Veri
  final List<Map<String, String>> rows;

  /// [preferenceStore]: Test inject
  final ReportPivotPreferenceStore? preferenceStore;

  /// [layoutStore]: Adlı pivot görünüm listesi (test inject)
  final ReportLayoutStore? layoutStore;

  /// {@macro report_result_pivot_pane}
  const ReportResultPivotPane({
    Key? key,
    required this.reportId,
    required this.layout,
    required this.rows,
    this.preferenceStore,
    this.layoutStore,
  }) : super(key: key);

  @override
  State<ReportResultPivotPane> createState() => _ReportResultPivotPaneState();
}

class _ReportResultPivotPaneState extends State<ReportResultPivotPane> {
  String? _rowFieldId;
  String? _columnFieldId;
  String? _valueFieldId;
  List<ReportSavedView> _savedViews = const [];
  String? _selectedViewId;
  bool _prefsLoaded = false;

  late final ReportPivotPreferenceStore _prefStore =
      widget.preferenceStore ?? ReportPivotPreferenceStore();

  ReportLayoutStore get _namedViewStore =>
      widget.layoutStore ?? ReportLayoutStore();

  static final NumberFormat _nf = NumberFormat('#,##0.##', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _applyGuess();
    _loadSaved();
    _loadNamedViews();
  }

  Future<void> _loadNamedViews() async {
    final views = await _namedViewStore.listSavedViews(widget.reportId);
    if (!mounted) return;
    setState(() => _savedViews = views);
  }

  Future<void> _saveCurrentPivotView() async {
    final l10n = AppLocalization.of(context);
    final nameCtrl = TextEditingController(
      text: l10n.translate('field_sales.mbt_reports.saved_view_default_name'),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
        );
      },
    );
    if (saved != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final rowId = _rowFieldId ?? widget.layout.columns.first.id;
    final valueId = _valueFieldId ?? widget.layout.columns.last.id;
    final view = ReportSavedView.pivot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      rowFieldId: rowId,
      columnFieldId: _columnFieldId,
      valueFieldId: valueId,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _namedViewStore.upsertSavedView(
      reportId: widget.reportId,
      view: view,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.mbt_reports.saved_view_saved'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    await _loadNamedViews();
    setState(() => _selectedViewId = view.id);
  }

  void _applySavedView(ReportSavedView? view) {
    if (view == null || view.kind != ReportSavedViewKind.pivot) {
      setState(() => _selectedViewId = null);
      return;
    }
    setState(() {
      _selectedViewId = view.id;
      _rowFieldId = view.rowFieldId;
      _columnFieldId = view.columnFieldId;
      _valueFieldId = view.valueFieldId;
    });
    _persist();
  }

  void _applyGuess() {
    final guess = ReportPivotAggregator.guessFields(widget.layout);
    _rowFieldId = guess.rowFieldId;
    _columnFieldId = guess.columnFieldId;
    _valueFieldId = guess.valueFieldId;
  }

  Future<void> _loadSaved() async {
    final saved = await _prefStore.load(widget.reportId);
    if (!mounted) return;
    if (saved != null) {
      final ids = widget.layout.columns.map((c) => c.id).toSet();
      setState(() {
        if (saved.rowFieldId != null && ids.contains(saved.rowFieldId)) {
          _rowFieldId = saved.rowFieldId;
        }
        if (saved.columnFieldId == null ||
            ids.contains(saved.columnFieldId)) {
          _columnFieldId = saved.columnFieldId;
        }
        if (saved.valueFieldId != null &&
            ids.contains(saved.valueFieldId)) {
          _valueFieldId = saved.valueFieldId;
        }
        _prefsLoaded = true;
      });
    } else {
      setState(() => _prefsLoaded = true);
    }
  }

  Future<void> _persist() async {
    if (!_prefsLoaded) return;
    await _prefStore.save(
      widget.reportId,
      ReportPivotPreference(
        rowFieldId: _rowFieldId,
        columnFieldId: _columnFieldId,
        valueFieldId: _valueFieldId,
      ),
    );
  }

  void _onFieldChanged({
    String? row,
    String? column,
    bool clearColumn = false,
    String? value,
  }) {
    setState(() {
      if (row != null) _rowFieldId = row;
      if (clearColumn) {
        _columnFieldId = null;
      } else if (column != null) {
        _columnFieldId = column;
      }
      if (value != null) _valueFieldId = value;
    });
    _persist();
  }

  @override
  void didUpdateWidget(covariant ReportResultPivotPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout ||
        oldWidget.reportId != widget.reportId) {
      _applyGuess();
      _prefsLoaded = false;
      _loadSaved();
    }
  }

  List<ReportLayoutColumn> get _fields => widget.layout.columns;

  String _titleFor(String? id, AppLocalization l10n) {
    if (id == null) return '—';
    for (final c in _fields) {
      if (c.id == id) return l10n.translate(c.titleKey);
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final fields = _fields;
    if (fields.isEmpty) {
      return const ReportDensEmptyState(
        messageKey: 'field_sales.mbt_reports.pivot_empty',
        icon: Icons.table_chart_outlined,
      );
    }

    final rowId = _rowFieldId ?? fields.first.id;
    final valueId = _valueFieldId ?? fields.last.id;
    final colId = _columnFieldId;

    final pivot = widget.rows.isEmpty
        ? null
        : ReportPivotAggregator.aggregate(
            rows: widget.rows,
            rowFieldId: rowId,
            columnFieldId: colId,
            valueFieldId: valueId,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.reportId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
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
                        value: _selectedViewId,
                        hint: Text(
                          l10n.translate(
                            'field_sales.mbt_reports.saved_view_pick',
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
                            if (v.kind == ReportSavedViewKind.pivot)
                              DropdownMenuItem<String?>(
                                value: v.id,
                                child: Text(
                                  v.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                        ],
                        onChanged: (v) {
                          if (v == null) {
                            _applySavedView(null);
                            return;
                          }
                          final found =
                              _savedViews.where((e) => e.id == v).firstOrNull;
                          _applySavedView(found);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FieldSalesDensAppBar.densIconButton(
                  icon: Icons.bookmark_add_outlined,
                  tooltip: l10n.translate(
                    'field_sales.mbt_reports.saved_view_save',
                  ),
                  onPressed: _saveCurrentPivotView,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Column(
            children: [
              _pickerRow(
                label: l10n.translate('field_sales.mbt_reports.pivot_row'),
                value: rowId,
                allowNone: false,
                onChanged: (v) {
                  if (v != null) _onFieldChanged(row: v);
                },
                l10n: l10n,
              ),
              const SizedBox(height: 4),
              _pickerRow(
                label: l10n.translate('field_sales.mbt_reports.pivot_column'),
                value: colId,
                allowNone: true,
                onChanged: (v) {
                  if (v == null) {
                    _onFieldChanged(clearColumn: true);
                  } else {
                    _onFieldChanged(column: v);
                  }
                },
                l10n: l10n,
              ),
              const SizedBox(height: 4),
              _pickerRow(
                label: l10n.translate('field_sales.mbt_reports.pivot_value'),
                value: valueId,
                allowNone: false,
                onChanged: (v) {
                  if (v != null) _onFieldChanged(value: v);
                },
                l10n: l10n,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: pivot == null || pivot.rowKeys.isEmpty
              ? const ReportDensEmptyState(
                  messageKey: 'field_sales.mbt_reports.pivot_empty',
                  icon: Icons.table_chart_outlined,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                    child: _buildTable(pivot, l10n),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _pickerRow({
    required String label,
    required String? value,
    required bool allowNone,
    required ValueChanged<String?> onChanged,
    required AppLocalization l10n,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
                value: value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                items: [
                  if (allowNone)
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.translate(
                          'field_sales.mbt_reports.pivot_none',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  for (final f in _fields)
                    DropdownMenuItem<String?>(
                      value: f.id,
                      child: Text(
                        _titleFor(f.id, l10n),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(ReportPivotResult pivot, AppLocalization l10n) {
    final headingStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final cellStyle = const TextStyle(fontSize: 11);

    final colKeys = pivot.columnKeys;
    final singleCol =
        colKeys.first == ReportPivotAggregator.singleMeasureKey;

    String _fmt(double v) => _nf.format(v);

    return DataTable(
      headingRowHeight: 32,
      dataRowMinHeight: 28,
      dataRowMaxHeight: 32,
      columnSpacing: 12,
      horizontalMargin: 8,
      columns: [
        const DataColumn(label: SizedBox.shrink()),
        for (final ck in colKeys)
          DataColumn(
            label: Text(
              singleCol
                  ? l10n.translate(
                      'field_sales.mbt_reports.pivot_value',
                    )
                  : (ck == ReportPivotAggregator.emptyLabel
                      ? l10n.translate(
                          'field_sales.mbt_reports.pivot_empty_label',
                        )
                      : ck),
              style: headingStyle,
            ),
          ),
        DataColumn(
          label: Text(
            l10n.translate('field_sales.mbt_reports.pivot_total'),
            style: headingStyle,
          ),
        ),
      ],
      rows: [
        for (final rk in pivot.rowKeys)
          DataRow(
            cells: [
              DataCell(
                Text(
                  rk == ReportPivotAggregator.emptyLabel
                      ? l10n.translate(
                          'field_sales.mbt_reports.pivot_empty_label',
                        )
                      : rk,
                  style: headingStyle,
                ),
              ),
              for (final ck in colKeys)
                DataCell(
                  Text(
                    _fmt(pivot.cell(rk, ck)),
                    style: cellStyle,
                  ),
                ),
              DataCell(
                Text(
                  _fmt(pivot.rowTotals[rk] ?? 0),
                  style: headingStyle,
                ),
              ),
            ],
          ),
        DataRow(
          cells: [
            DataCell(
              Text(
                l10n.translate('field_sales.mbt_reports.pivot_total'),
                style: headingStyle,
              ),
            ),
            for (final ck in colKeys)
              DataCell(
                Text(
                  _fmt(pivot.columnTotals[ck] ?? 0),
                  style: headingStyle,
                ),
              ),
            DataCell(
              Text(_fmt(pivot.grandTotal), style: headingStyle),
            ),
          ],
        ),
      ],
    );
  }
}
