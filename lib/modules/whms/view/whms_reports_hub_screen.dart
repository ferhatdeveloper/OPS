// Dosya Adı: whms_reports_hub_screen.dart
// Açıklama: WHMS Raporlar dens hub — KPI / emir performans / sayım fark
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import 'whms_dens_hub_section.dart';

/// {@template whms_reports_hub_screen}
/// Raporlar hub. Route: `/whms/reports-hub`
/// {@endtemplate}
class WhmsReportsHubScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsReportsHub;

  /// {@macro whms_reports_hub_screen}
  const WhmsReportsHubScreen({super.key});

  static const List<WhmsDensHubItem> _items = [
    WhmsDensHubItem(
      l10nKey: 'whms.hub.reports_kpi',
      route: WhmsRouteMap.whmsReports,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.reports_order_perf',
      route: WhmsRouteMap.whmsReportsOrderPerf,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.reports_count_var',
      route: WhmsRouteMap.whmsReportsCountVar,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.hub.section_reports'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          Text(
            l10n.translate('whms.hub.reports_hint'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_reports',
            items: _items,
          ),
        ],
      ),
    );
  }
}
