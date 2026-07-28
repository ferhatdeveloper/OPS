// Dosya Adı: report_dens_empty_state.dart
// Açıklama: Rapor sonuç dens boş durum (query [] / veri yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template report_dens_empty_state}
/// Query `[]` veya sayısal veri yokken dens empty-state.
///
/// Kullanım örneği:
/// ```dart
/// const ReportDensEmptyState(
///   messageKey: 'field_sales.mbt_reports.grid_empty',
/// )
/// ```
/// {@endtemplate}
class ReportDensEmptyState extends StatelessWidget {
  /// [messageKey]: Ana mesaj çeviri anahtarı
  final String messageKey;

  /// [hintKey]: İsteğe bağlı alt ipucu
  final String hintKey;

  /// [icon]: Dens ikon (≤ 40)
  final IconData icon;

  /// {@macro report_dens_empty_state}
  const ReportDensEmptyState({
    Key? key,
    this.messageKey = 'field_sales.mbt_reports.grid_empty',
    this.hintKey = 'field_sales.mbt_reports.grid_empty_hint',
    this.icon = Icons.inbox_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              l10n.translate(messageKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.translate(hintKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
