// Dosya Adı: period_comparison_report.dart
// Açıklama: Esnek dönem karşılaştırma sihirbazı (şablon/eksen/filtre/sonuç + PDF)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/ai/widgets/report_ai_insight_banner.dart';
import '../../../field_sales/companies/viewmodel/company_context_loader.dart';
import '../../../field_sales/reports/model/report_pdf_viewer_args.dart';
import '../../../field_sales/reports/view/report_pdf_viewer_screen.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_theme.dart';
import '../model/compare_history_entry.dart';
import '../model/compare_matrix_models.dart';
import '../model/period_comparison_models.dart';
import '../service/compare_pdf_builder.dart';
import '../viewmodel/comparison_wizard_provider.dart';
import '../widgets/compare_grouped_bar_chart.dart';
import '../widgets/compare_line_chart.dart';
import '../widgets/compare_matrix_pivot.dart';
import '../widgets/period_comparison_chart.dart';
import '../widgets/period_comparison_pivot_table.dart';

/// {@template period_comparison_report_screen}
/// Yönetici esnek dönem karşılaştırma — 4 adımlı dens sihirbaz.
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
    final wizard = ref.watch(comparisonWizardProvider);
    final notifier = ref.read(comparisonWizardProvider.notifier);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('advanced.period_comparison'),
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.history,
            tooltip: l10n.translate('advanced.compare_history_open'),
            onPressed: () => _openHistorySheet(context, ref),
          ),
          if (wizard.step == 3)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.save_outlined,
              tooltip: l10n.translate('advanced.compare_history_save'),
              onPressed: () => _saveHistory(context, ref),
            ),
          if (wizard.step == 3)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: l10n.translate('advanced.compare_pdf'),
              onPressed: () => _exportPdf(context, ref, shareOnly: false),
            ),
          if (wizard.step == 3)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.share_outlined,
              tooltip: l10n.translate('advanced.compare_share'),
              onPressed: () => _exportPdf(context, ref, shareOnly: true),
            ),
        ],
        bottom: FieldSalesDensFilterBar(
          children: [
            _StepIndicator(step: wizard.step, l10n: l10n),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildStep(context, ref, wizard, l10n)),
          _NavBar(
            step: wizard.step,
            canNext: _canNext(wizard),
            onBack: wizard.step > 0 ? notifier.prevStep : null,
            onNext: () {
              final ok = notifier.nextStep();
              if (!ok && wizard.step == 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.translate('advanced.compare_axes_invalid'),
                    ),
                  ),
                );
              }
              if (!ok && wizard.step == 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.translate('advanced.compare_periods_min'),
                    ),
                  ),
                );
              }
            },
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  bool _canNext(ComparisonWizardState w) {
    if (w.step == 1) return w.isAxesValid;
    if (w.step == 2) return w.canProceedFromFilters;
    return w.step < 3;
  }

  Widget _buildStep(
    BuildContext context,
    WidgetRef ref,
    ComparisonWizardState wizard,
    AppLocalization l10n,
  ) {
    switch (wizard.step) {
      case 0:
        return _TemplateStep(l10n: l10n);
      case 1:
        return _AxisStep(l10n: l10n, wizard: wizard);
      case 2:
        return _FilterStep(l10n: l10n, wizard: wizard);
      default:
        return _ResultStep(l10n: l10n);
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref, {
    required bool shareOnly,
  }) async {
    final l10n = AppLocalization.of(context);
    final async = ref.read(compareMatrixResultProvider);
    final result = async.asData?.value;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('advanced.period_compare_error'))),
      );
      return;
    }

    final wizard = ref.read(comparisonWizardProvider);
    final labels = ComparePdfLabels(
      generatedAt: l10n.translate('advanced.compare_generated_at'),
      template: l10n.translate('advanced.compare_template'),
      templateName: _templateLabel(l10n, wizard.template),
      rowAxis: l10n.translate('advanced.compare_row_axis'),
      rowAxisName: _axisLabel(l10n, wizard.rowAxis),
      colAxis: l10n.translate('advanced.compare_col_axis'),
      colAxisName: _axisLabel(l10n, wizard.columnAxis),
      periods: l10n.translate('advanced.compare_periods'),
      summary: l10n.translate('advanced.period_compare_pivot'),
      matrix: l10n.translate('advanced.compare_matrix'),
      empty: l10n.translate('advanced.period_compare_empty'),
      metric: l10n.translate('advanced.metric'),
      previous: l10n.translate('advanced.previous_period'),
      current: l10n.translate('advanced.current_period'),
      diffPct: l10n.translate('advanced.diff_pct'),
    );

    final bytes = await const ComparePdfBuilder().build(
      result: result,
      title: l10n.translate('advanced.period_comparison'),
      labels: labels,
    );

    if (!context.mounted) return;

    if (shareOnly) {
      await _shareBytes(bytes, l10n);
      return;
    }

    await Navigator.of(context).pushNamed(
      ReportPdfViewerScreen.routeName,
      arguments: ReportPdfViewerArgs(
        bytes: bytes,
        title: l10n.translate('advanced.period_comparison'),
      ),
    );
  }

  Future<void> _shareBytes(Uint8List bytes, AppLocalization l10n) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/period_compare_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      text: l10n.translate('advanced.period_comparison'),
    );
  }

  Future<void> _saveHistory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalization.of(context);
    final wizard = ref.read(comparisonWizardProvider);
    final result = ref.read(compareMatrixResultProvider).asData?.value;
    final controller = TextEditingController(
      text: _defaultHistoryName(l10n, wizard),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.translate('advanced.compare_history_save'),
            style: const TextStyle(fontSize: 15),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.translate('advanced.compare_history_save_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.translate('advanced.compare_back')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: FieldSalesDensAppBar.primaryColor,
              ),
              child: Text(l10n.translate('advanced.compare_history_save')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null) return;
    if (name.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('advanced.compare_history_name_required'),
          ),
        ),
      );
      return;
    }
    final store = ref.read(compareHistoryStoreProvider);
    await store.save(name: name, query: wizard, result: result);
    ref.invalidate(compareHistoryListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('advanced.compare_history_saved')),
      ),
    );
  }

  String _defaultHistoryName(
    AppLocalization l10n,
    ComparisonWizardState wizard,
  ) {
    final tpl = _templateLabel(l10n, wizard.template);
    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return '$tpl $stamp';
  }

  Future<void> _openHistorySheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalization.of(context);
    ref.invalidate(compareHistoryListProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final async = sheetRef.watch(compareHistoryListProvider);
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Text(
                        l10n.translate('advanced.compare_history'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: async.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => Center(
                          child: Text(
                            l10n.translate('advanced.compare_history_empty'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return Center(
                              child: Text(
                                l10n.translate(
                                  'advanced.compare_history_empty',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final e = items[i];
                              return _HistoryTile(
                                entry: e,
                                l10n: l10n,
                                onLoad: () {
                                  sheetRef
                                      .read(
                                        compareMatrixSnapshotProvider.notifier,
                                      )
                                      .state = e.result;
                                  sheetRef
                                      .read(comparisonWizardProvider.notifier)
                                      .loadHistory(e);
                                  Navigator.pop(ctx);
                                },
                                onDelete: () async {
                                  final ok = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dCtx) => AlertDialog(
                                      title: Text(
                                        l10n.translate(
                                          'advanced.compare_history_delete',
                                        ),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      content: Text(
                                        l10n.translate(
                                          'advanced.compare_history_delete_confirm',
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dCtx, false),
                                          child: Text(
                                            l10n.translate(
                                              'advanced.compare_back',
                                            ),
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(dCtx, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                FieldSalesDensAppBar
                                                    .primaryColor,
                                          ),
                                          child: Text(
                                            l10n.translate(
                                              'advanced.compare_history_delete',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;
                                  await sheetRef
                                      .read(compareHistoryStoreProvider)
                                      .delete(e.id);
                                  sheetRef.invalidate(
                                    compareHistoryListProvider,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// {@template _history_tile}
/// Dens kayıtlı karşılaştırma satırı.
/// {@endtemplate}
class _HistoryTile extends StatelessWidget {
  final CompareHistoryEntry entry;
  final AppLocalization l10n;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.l10n,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_templateLabel(l10n, entry.template)} · '
                  '${entry.updatedAt.length >= 10 ? entry.updatedAt.substring(0, 10) : entry.updatedAt}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onLoad,
            child: Text(
              l10n.translate('advanced.compare_history_load'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: l10n.translate('advanced.compare_history_delete'),
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  final int step;
  final AppLocalization l10n;

  const _StepIndicator({required this.step, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final keys = [
      'advanced.compare_step_template',
      'advanced.compare_step_axis',
      'advanced.compare_step_filter',
      'advanced.compare_step_result',
    ];
    return FieldSalesDensChipRow(
      fontSize: 10,
      items: [
        for (var i = 0; i < keys.length; i++)
          FieldSalesDensChipItem(
            label: '${i + 1}. ${l10n.translate(keys[i])}',
            selected: step == i,
            onTap: () {},
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nav bar
// ---------------------------------------------------------------------------

class _NavBar extends StatelessWidget {
  final int step;
  final bool canNext;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final AppLocalization l10n;

  const _NavBar({
    required this.step,
    required this.canNext,
    required this.onBack,
    required this.onNext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (step >= 3) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: SizedBox(
            height: 40,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: Text(l10n.translate('advanced.compare_back')),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onBack,
                    child: Text(l10n.translate('advanced.compare_back')),
                  ),
                ),
              ),
            if (onBack != null) const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: canNext ? onNext : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: FieldSalesDensAppBar.primaryColor,
                  ),
                  child: Text(
                    step == 2
                        ? l10n.translate('advanced.compare_show_result')
                        : l10n.translate('advanced.compare_next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Template step
// ---------------------------------------------------------------------------

class _TemplateStep extends ConsumerWidget {
  final AppLocalization l10n;

  const _TemplateStep({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(comparisonWizardProvider).template;
    final items = CompareTemplate.values;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        Text(
          l10n.translate('advanced.compare_choose_template'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        for (final t in items) ...[
          _TemplateTile(
            title: _templateLabel(l10n, t),
            subtitle: _templateDesc(l10n, t),
            selected: selected == t,
            onTap: () =>
                ref.read(comparisonWizardProvider.notifier).applyTemplate(t),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = FieldSalesDensAppBar.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Axis step
// ---------------------------------------------------------------------------

class _AxisStep extends ConsumerWidget {
  final AppLocalization l10n;
  final ComparisonWizardState wizard;

  const _AxisStep({required this.l10n, required this.wizard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axes = CompareAxis.values
        .where((a) => a != CompareAxis.none)
        .toList();
    final rowOptions = [CompareAxis.none, ...axes];

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        Text(
          l10n.translate('advanced.compare_row_axis'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in rowOptions)
              FieldSalesDensChip(
                label: _axisLabel(l10n, a),
                selected: wizard.rowAxis == a,
                onTap: () => ref
                    .read(comparisonWizardProvider.notifier)
                    .setAxes(rowAxis: a),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.translate('advanced.compare_col_axis'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in axes)
              FieldSalesDensChip(
                label: _axisLabel(l10n, a),
                selected: wizard.columnAxis == a,
                onTap: () => ref
                    .read(comparisonWizardProvider.notifier)
                    .setAxes(columnAxis: a),
              ),
          ],
        ),
        if (!wizard.isAxesValid) ...[
          const SizedBox(height: 10),
          Text(
            l10n.translate('advanced.compare_axes_invalid'),
            style: TextStyle(fontSize: 11, color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter step
// ---------------------------------------------------------------------------

class _FilterStep extends ConsumerWidget {
  final AppLocalization l10n;
  final ComparisonWizardState wizard;

  const _FilterStep({required this.l10n, required this.wizard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(comparisonWizardProvider.notifier);
    final catalogAsync = ref.watch(compareContextCatalogProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        // —— Sistem firmaları ——
        Text(
          l10n.translate('advanced.compare_firms_title'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        catalogAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, __) => Text(
            l10n.translate('advanced.compare_catalog_empty'),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          data: (catalog) {
            final firms = catalog.firms;
            final label = wizard.companyIds.isEmpty
                ? l10n.translate('advanced.compare_firms_all')
                : l10n.translate(
                    'advanced.compare_firms_selected',
                    args: {'count': '${wizard.companyIds.length}'},
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: firms.isEmpty
                      ? null
                      : () => _pickFirms(context, ref, firms),
                  icon: const Icon(Icons.business, size: 18),
                  label: Text(
                    '${l10n.translate('advanced.compare_select_firms')}: $label',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    foregroundColor: FieldSalesDensAppBar.primaryColor,
                    side: const BorderSide(
                      color: FieldSalesDensAppBar.primaryColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
                if (firms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.translate('advanced.compare_catalog_empty'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (wizard.companyIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final id in wizard.companyIds)
                        Chip(
                          label: Text(
                            _firmLabel(firms, id),
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onDeleted: () {
                            final next = wizard.companyIds
                                .where((x) => x != id)
                                .toList();
                            n.setCompanyIds(next);
                          },
                        ),
                      TextButton(
                        onPressed: () => n.setCompanyIds(const []),
                        child: Text(
                          l10n.translate('advanced.compare_firms_all'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // —— Sistem dönemleri ——
        Text(
          l10n.translate('advanced.compare_periods'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        catalogAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (catalog) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: catalog.periods.isEmpty
                    ? null
                    : () => _pickSystemPeriods(context, ref, catalog),
                icon: const Icon(Icons.list_alt, size: 18),
                label: Text(
                  l10n.translate('advanced.compare_select_system_periods'),
                ),
              ),
            );
          },
        ),
        for (final p in wizard.periods) ...[
          _PeriodTile(
            slot: p,
            onEdit: () => _editPeriod(context, ref, p),
            onRemove: wizard.periods.length > 2
                ? () => n.removePeriod(p.id)
                : null,
          ),
          const SizedBox(height: 4),
        ],
        if (wizard.periods.length < ComparisonWizardState.maxPeriods)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _addPeriod(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.translate('advanced.compare_custom_period')),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () =>
                ref.invalidate(compareContextCatalogProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.translate('advanced.compare_reload_catalog')),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.translate('advanced.compare_top_n'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        FieldSalesDensChipRow(
          fontSize: 11,
          items: [
            for (final v in [5, 10, 15, 25])
              FieldSalesDensChipItem(
                label: '$v',
                selected: wizard.topN == v,
                onTap: () => n.setTopN(v),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.translate('advanced.metric'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in [
              PeriodMetricKind.sales,
              PeriodMetricKind.orderCount,
              PeriodMetricKind.collection,
              PeriodMetricKind.visit,
            ])
              FieldSalesDensChip(
                label: _metricTitle(l10n, m),
                selected: wizard.primaryMetric == m,
                onTap: () => n.setPrimaryMetric(m),
              ),
          ],
        ),
      ],
    );
  }

  String _firmLabel(List<CompanyContextFirm> firms, String id) {
    for (final f in firms) {
      if (f.companyId == id || f.companyNo == id) {
        return '${f.companyNo} · ${f.name}';
      }
    }
    return id;
  }

  Future<void> _pickFirms(
    BuildContext context,
    WidgetRef ref,
    List<CompanyContextFirm> firms,
  ) async {
    final selected = Set<String>.from(
      ref.read(comparisonWizardProvider).companyIds,
    );
    // Prefer companyId; fallback companyNo for repository filter
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                AppLocalization.of(context)
                    .translate('advanced.compare_firms_title'),
                style: const TextStyle(fontSize: 15),
              ),
              content: SizedBox(
                width: 340,
                height: 360,
                child: ListView.builder(
                  itemCount: firms.length,
                  itemBuilder: (_, i) {
                    final f = firms[i];
                    final key = f.companyNo.isNotEmpty
                        ? f.companyNo
                        : f.companyId;
                    final on = selected.contains(key) ||
                        selected.contains(f.companyId);
                    return CheckboxListTile(
                      dense: true,
                      value: on,
                      title: Text(
                        '${f.companyNo} · ${f.name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) {
                        setLocal(() {
                          if (v == true) {
                            selected.add(key);
                          } else {
                            selected.remove(key);
                            selected.remove(f.companyId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    AppLocalization.of(context)
                        .translate('advanced.compare_back'),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: FieldSalesDensAppBar.primaryColor,
                  ),
                  child: Text(
                    AppLocalization.of(context)
                        .translate('advanced.compare_firms_apply'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null) return;
    ref.read(comparisonWizardProvider.notifier).setCompanyIds(result.toList());
  }

  Future<void> _pickSystemPeriods(
    BuildContext context,
    WidgetRef ref,
    CompanyContextData catalog,
  ) async {
    // Unique by companyNo+periodNo+dates for multi-firm
    final items = catalog.periods;
    final selected = <String>{};
    for (final p in ref.read(comparisonWizardProvider).periods) {
      selected.add(p.id);
    }

    final applied = await showDialog<List<ComparePeriodSlot>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                AppLocalization.of(context)
                    .translate('advanced.compare_system_periods_title'),
                style: const TextStyle(fontSize: 15),
              ),
              content: SizedBox(
                width: 340,
                height: 360,
                child: items.isEmpty
                    ? Text(
                        AppLocalization.of(context)
                            .translate('advanced.compare_catalog_empty'),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final p = items[i];
                          final id =
                              '${p.companyNo}_${p.periodNo}_${p.startDate}_${p.endDate}';
                          final on = selected.contains(id);
                          final label =
                              '${p.companyNo} · ${p.periodNo}: '
                              '${p.startDate} – ${p.endDate}';
                          return CheckboxListTile(
                            dense: true,
                            value: on,
                            title: Text(
                              label,
                              style: const TextStyle(fontSize: 12),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) {
                              setLocal(() {
                                if (v == true) {
                                  if (selected.length >=
                                      ComparisonWizardState.maxPeriods) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalization.of(context)
                                              .translate(
                                            'advanced.compare_period_max',
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    AppLocalization.of(context)
                        .translate('advanced.compare_back'),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final slots = <ComparePeriodSlot>[];
                    for (final p in items) {
                      final id =
                          '${p.companyNo}_${p.periodNo}_${p.startDate}_${p.endDate}';
                      if (!selected.contains(id)) continue;
                      final range = _rangeFromSystem(p.startDate, p.endDate);
                      if (range == null) continue;
                      slots.add(
                        ComparePeriodSlot(
                          id: id,
                          label: '${p.companyNo}/${p.periodNo}',
                          range: range,
                        ),
                      );
                    }
                    Navigator.pop(ctx, slots);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: FieldSalesDensAppBar.primaryColor,
                  ),
                  child: Text(
                    AppLocalization.of(context)
                        .translate('advanced.compare_period_apply'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (applied == null) return;
    if (applied.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('advanced.compare_periods_min'),
            ),
          ),
        );
      }
      return;
    }
    ref.read(comparisonWizardProvider.notifier).setPeriods(applied);
  }

  PeriodDateRange? _rangeFromSystem(String start, String end) {
    final a = _parseFlexibleDate(start);
    final b = _parseFlexibleDate(end);
    if (a == null || b == null) return null;
    return PeriodDateRange(from: a, to: b);
  }

  DateTime? _parseFlexibleDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final iso = DateTime.tryParse(t);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = t.split(RegExp(r'[./\-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 == null || p1 == null || p2 == null) return null;
      // YYYY-MM-DD
      if (p0 > 31) return DateTime(p0, p1, p2);
      // DD-MM-YYYY
      if (p2 > 31) return DateTime(p2, p1, p0);
    }
    return null;
  }

  Future<void> _addPeriod(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await _pickRange(
      context,
      now.subtract(const Duration(days: 30)),
      now,
    );
    if (range == null) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    ref.read(comparisonWizardProvider.notifier).addPeriod(
          ComparePeriodSlot(
            id: id,
            label:
                'P${ref.read(comparisonWizardProvider).periods.length + 1}',
            range: range,
          ),
        );
  }

  Future<void> _editPeriod(
    BuildContext context,
    WidgetRef ref,
    ComparePeriodSlot slot,
  ) async {
    final range = await _pickRange(
      context,
      slot.range.from,
      slot.range.to,
    );
    if (range == null) return;
    final list = ref.read(comparisonWizardProvider).periods.map((p) {
      if (p.id != slot.id) return p;
      return p.copyWith(range: range);
    }).toList();
    ref.read(comparisonWizardProvider.notifier).setPeriods(list);
  }

  Future<PeriodDateRange?> _pickRange(
    BuildContext context,
    DateTime initialFrom,
    DateTime initialTo,
  ) async {
    final from = await showDatePicker(
      context: context,
      initialDate: initialFrom,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (from == null || !context.mounted) return null;
    final to = await showDatePicker(
      context: context,
      initialDate: initialTo.isBefore(from) ? from : initialTo,
      firstDate: from,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (to == null) return null;
    return PeriodDateRange(from: from, to: to);
  }
}

class _PeriodTile extends StatelessWidget {
  final ComparePeriodSlot slot;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  const _PeriodTile({
    required this.slot,
    required this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${slot.range.fromKey} – ${slot.range.toKey}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined, size: 20),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result step
// ---------------------------------------------------------------------------

class _ResultStep extends ConsumerWidget {
  final AppLocalization l10n;

  const _ResultStep({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(comparisonWizardProvider);
    final async = ref.watch(compareMatrixResultProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(compareMatrixResultProvider),
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
        onRefresh: () async => ref.invalidate(compareMatrixResultProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          children: [
            _QueryCaption(wizard: wizard, l10n: l10n),
            const SizedBox(height: 8),
            if (result.summaryMetrics.isNotEmpty) ...[
              ReportAiInsightBanner(
                reportTitle: l10n.translate('advanced.period_comparison'),
                rows: [
                  for (final r in result.summaryMetrics)
                    r.toInsightMap(_metricTitle(l10n, r.kind)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.translate('advanced.period_compare_pivot'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              PeriodComparisonPivotTable(rows: result.summaryMetrics),
              const SizedBox(height: 10),
              if (wizard.rowAxis == CompareAxis.none) ...[
                Text(
                  l10n.translate('advanced.period_compare_chart'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 6),
                PeriodComparisonChart(rows: result.summaryMetrics),
                const SizedBox(height: 10),
              ],
            ],
            if (wizard.rowAxis != CompareAxis.none) ...[
              Text(
                l10n.translate('advanced.compare_chart_bar'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              CompareGroupedBarChart(result: result),
              const SizedBox(height: 10),
              if (result.colKeys.length >= 2) ...[
                Text(
                  l10n.translate('advanced.compare_chart_line'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 6),
                CompareLineChart(result: result),
                const SizedBox(height: 10),
              ],
              Text(
                l10n.translate('advanced.compare_matrix'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              CompareMatrixPivot(result: result),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueryCaption extends StatelessWidget {
  final ComparisonWizardState wizard;
  final AppLocalization l10n;

  const _QueryCaption({required this.wizard, required this.l10n});

  @override
  Widget build(BuildContext context) {
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
            _templateLabel(l10n, wizard.template),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_axisLabel(l10n, wizard.rowAxis)} × '
            '${_axisLabel(l10n, wizard.columnAxis)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          for (final p in wizard.periods)
            Text(
              '${p.label}: ${p.range.fromKey} – ${p.range.toKey}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// l10n helpers
// ---------------------------------------------------------------------------

String _templateLabel(AppLocalization l10n, CompareTemplate t) {
  switch (t) {
    case CompareTemplate.periodOverview:
      return l10n.translate('advanced.template_period_overview');
    case CompareTemplate.companyPeriod:
      return l10n.translate('advanced.template_company_period');
    case CompareTemplate.productPeriod:
      return l10n.translate('advanced.template_product_period');
    case CompareTemplate.customerPeriod:
      return l10n.translate('advanced.template_customer_period');
    case CompareTemplate.supplierPeriod:
      return l10n.translate('advanced.template_supplier_period');
    case CompareTemplate.salesmanPeriod:
      return l10n.translate('advanced.template_salesman_period');
    case CompareTemplate.brandCategory:
      return l10n.translate('advanced.template_brand_category');
    case CompareTemplate.regionPeriod:
      return l10n.translate('advanced.template_region_period');
    case CompareTemplate.custom:
      return l10n.translate('advanced.template_custom');
  }
}

String _templateDesc(AppLocalization l10n, CompareTemplate t) {
  switch (t) {
    case CompareTemplate.periodOverview:
      return l10n.translate('advanced.template_period_overview_desc');
    case CompareTemplate.companyPeriod:
      return l10n.translate('advanced.template_company_period_desc');
    case CompareTemplate.productPeriod:
      return l10n.translate('advanced.template_product_period_desc');
    case CompareTemplate.customerPeriod:
      return l10n.translate('advanced.template_customer_period_desc');
    case CompareTemplate.supplierPeriod:
      return l10n.translate('advanced.template_supplier_period_desc');
    case CompareTemplate.salesmanPeriod:
      return l10n.translate('advanced.template_salesman_period_desc');
    case CompareTemplate.brandCategory:
      return l10n.translate('advanced.template_brand_category_desc');
    case CompareTemplate.regionPeriod:
      return l10n.translate('advanced.template_region_period_desc');
    case CompareTemplate.custom:
      return l10n.translate('advanced.template_custom_desc');
  }
}

String _axisLabel(AppLocalization l10n, CompareAxis a) {
  switch (a) {
    case CompareAxis.none:
      return l10n.translate('advanced.axis_none');
    case CompareAxis.period:
      return l10n.translate('advanced.axis_period');
    case CompareAxis.company:
      return l10n.translate('advanced.axis_company');
    case CompareAxis.product:
      return l10n.translate('advanced.axis_product');
    case CompareAxis.customer:
      return l10n.translate('advanced.axis_customer');
    case CompareAxis.supplier:
      return l10n.translate('advanced.axis_supplier');
    case CompareAxis.salesman:
      return l10n.translate('advanced.axis_salesman');
    case CompareAxis.region:
      return l10n.translate('advanced.axis_region');
    case CompareAxis.productGroup:
      return l10n.translate('advanced.axis_product_group');
    case CompareAxis.brand:
      return l10n.translate('advanced.axis_brand');
  }
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
