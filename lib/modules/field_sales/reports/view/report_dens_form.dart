// Dosya Adı: report_dens_form.dart
// Açıklama: MBT rapor dens form iskeleti (tarih aralığı · satırlar · Yedekle/İndir)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import 'report_dens_empty_state.dart';

/// {@template report_dens_row_placeholder}
/// Rapor dens satır iskeleti için yer tutucu.
/// {@endtemplate}
class ReportDensRowPlaceholder {
  /// [title]: Satır başlığı
  final String title;

  /// [subtitle]: Alt metin (kod / müşteri / tarih)
  final String subtitle;

  /// [value]: Sağ değer (tutar / adet)
  final String value;

  const ReportDensRowPlaceholder({
    required this.title,
    required this.subtitle,
    required this.value,
  });
}

/// {@template report_dens_form}
/// Rapor dens iskeleti: başlangıç/bitiş tarihi, satır listesi, Yedekle/İndir.
///
/// Kullanım örneği:
/// ```dart
/// ReportDensForm(
///   dateFrom: DateTime.now(),
///   dateTo: DateTime.now(),
///   onDateFromTap: () {},
///   onDateToTap: () {},
///   rows: const [],
///   onBackup: () {},
///   onDownload: () {},
/// )
/// ```
/// {@endtemplate}
class ReportDensForm extends StatelessWidget {
  /// [dateFrom]: Başlangıç tarihi
  final DateTime dateFrom;

  /// [dateTo]: Bitiş tarihi
  final DateTime dateTo;

  /// [onDateFromTap]: Başlangıç tarih seçici
  final VoidCallback onDateFromTap;

  /// [onDateToTap]: Bitiş tarih seçici
  final VoidCallback onDateToTap;

  /// [rows]: Görünür satır iskeleti (boş olabilir)
  final List<ReportDensRowPlaceholder> rows;

  /// [onBackup]: Rapor yedekle (iskelet)
  final VoidCallback? onBackup;

  /// [onDownload]: Rapor indir (iskelet)
  final VoidCallback? onDownload;

  /// [onRun]: Raporu getir (iskelet — opsiyonel)
  final VoidCallback? onRun;

  const ReportDensForm({
    Key? key,
    required this.dateFrom,
    required this.dateTo,
    required this.onDateFromTap,
    required this.onDateToTap,
    required this.rows,
    this.onBackup,
    this.onDownload,
    this.onRun,
  }) : super(key: key);

  InputDecoration _denseDecoration(BuildContext context, String? label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: FieldSalesDensTheme.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required AppLocalization l10n,
    required String labelKey,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final dateText = DateFormat('dd.MM.yyyy').format(date);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: _denseDecoration(context, l10n.translate(labelKey)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateText,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FieldSalesDensTheme.surface(context),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            children: [
              _dateField(
                context: context,
                l10n: l10n,
                labelKey: 'field_sales.report_dens.date_from',
                date: dateFrom,
                onTap: onDateFromTap,
              ),
              const SizedBox(height: 8),
              _dateField(
                context: context,
                l10n: l10n,
                labelKey: 'field_sales.report_dens.date_to',
                date: dateTo,
                onTap: onDateToTap,
              ),
              if (onRun != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onRun,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF375A7F),
                      side: BorderSide(color: Colors.grey.shade300),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      l10n.translate('field_sales.report_dens.run'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.translate('field_sales.report_dens.rows'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const ReportDensEmptyState(
                  messageKey: 'field_sales.report_dens.rows_empty',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FieldSalesDensTheme.surface(context),
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
                                  row.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  row.subtitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            row.value,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBackup,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(
                    l10n.translate('field_sales.report_dens.backup'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF375A7F),
                    side: BorderSide(color: Colors.grey.shade300),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(
                    l10n.translate('field_sales.report_dens.download'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00A8E8),
                    side: BorderSide(color: Colors.grey.shade300),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            l10n.translate('field_sales.report_dens.skeleton_hint'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
