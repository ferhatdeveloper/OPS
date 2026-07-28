// Dosya Adı: whms_label_template_list_screen.dart
// Açıklama: WHMS etiket şablon dens liste (+ baskı hook)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_label_template.dart';
import '../viewmodel/whms_label_print_hook.dart';
import '../viewmodel/whms_label_template_store.dart';

/// {@template whms_label_template_list_screen}
/// Etiket şablon dens liste.
/// Route: `/whms/labels/templates`
/// {@endtemplate}
class WhmsLabelTemplateListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsLabelTemplates;

  /// [store]: Test
  final WhmsLabelTemplateStore? store;

  /// [rows]: Test
  final List<WhmsLabelTemplate>? rows;

  /// {@macro whms_label_template_list_screen}
  const WhmsLabelTemplateListScreen({
    super.key,
    this.store,
    this.rows,
  });

  @override
  State<WhmsLabelTemplateListScreen> createState() =>
      _WhmsLabelTemplateListScreenState();
}

class _WhmsLabelTemplateListScreenState
    extends State<WhmsLabelTemplateListScreen> {
  List<WhmsLabelTemplate> _rows = const [];
  bool _loading = true;

  WhmsLabelTemplateStore get _store =>
      widget.store ?? const WhmsLabelTemplateStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _rows = List<WhmsLabelTemplate>.from(widget.rows!);
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _store.ensureReady();
      await _store.seedDefaultsIfEmpty();
      final rows = await _store.listActive();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

  Future<void> _printSample(WhmsLabelTemplate t) async {
    final l10n = AppLocalization.of(context);
    try {
      await const WhmsLabelPrintHook().printTemplate(t);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('whms.labels.print_sent'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('whms.labels.print_error'))),
      );
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
        title: l10n.translate('whms.labels.templates'),
        showCalculatorHome: false,
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('whms.labels.templates_empty'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final t = _rows[i];
                    return Material(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.code,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    t.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FieldSalesDensAppBar.densIconButton(
                              icon: Icons.print,
                              tooltip:
                                  l10n.translate('whms.labels.print_test'),
                              onPressed: () => _printSample(t),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
