// Dosya Adı: whms_system_screen.dart
// Açıklama: WHMS Sistem dens — ayar / sync durumu stub
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';

/// {@template whms_system_screen}
/// WHMS sistem / sync stub. Route: `/whms/system`
/// {@endtemplate}
class WhmsSystemScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsSystem;

  /// {@macro whms_system_screen}
  const WhmsSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.system.title'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          _row(
            isDark: isDark,
            title: l10n.translate('whms.system.sync_status'),
            value: l10n.translate('whms.system.sync_idle'),
          ),
          const SizedBox(height: 4),
          _row(
            isDark: isDark,
            title: l10n.translate('whms.system.queue'),
            value: l10n.translate('whms.system.queue_empty'),
          ),
          const SizedBox(height: 4),
          _row(
            isDark: isDark,
            title: l10n.translate('whms.system.mode'),
            value: l10n.translate('whms.system.mode_offline'),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('whms.system.hint'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required bool isDark,
    required String title,
    required String value,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
