// Dosya Adı: report_result_list_pane.dart
// Açıklama: Rapor sonuç dens Liste sekmesi (layout sütunları)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/report_layout.dart';
import '../model/report_layout_column.dart';
import 'report_dens_empty_state.dart';

/// {@template report_result_list_pane}
/// Görünür layout sütunlarıyla dens satır listesi.
///
/// Kullanım örneği:
/// ```dart
/// ReportResultListPane(layout: layout, rows: rows)
/// ```
/// {@endtemplate}
class ReportResultListPane extends StatelessWidget {
  /// [layout]: Sütun şeması
  final ReportLayout layout;

  /// [rows]: columnId → değer
  final List<Map<String, String>> rows;

  /// {@macro report_result_list_pane}
  const ReportResultListPane({
    Key? key,
    required this.layout,
    required this.rows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final cols = layout.visibleColumns;

    // P0: query [] → dens empty (blank body yasak)
    if (rows.isEmpty) {
      return const ReportDensEmptyState();
    }

    return Column(
      children: [
        Container(
          color: FieldSalesDensTheme.surface(context),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              for (final c in cols)
                Expanded(
                  flex: c.flex,
                  child: Text(
                    l10n.translate(c.titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: FieldSalesDensTheme.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    for (final c in cols)
                      Expanded(
                        flex: c.flex,
                        child: Text(
                          row[c.id] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign:
                              c.align == ReportLayoutColumnAlign.right
                                  ? TextAlign.right
                                  : TextAlign.left,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
