// Dosya Adı: whms_stock_hub_screen.dart
// Açıklama: WHMS Stok dens hub — sorgu / lot / rezervasyon
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import 'whms_dens_hub_section.dart';

/// {@template whms_stock_hub_screen}
/// Stok hub. Route: `/whms/stock`
/// {@endtemplate}
class WhmsStockHubScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsStockHub;

  /// {@macro whms_stock_hub_screen}
  const WhmsStockHubScreen({super.key});

  static const List<WhmsDensHubItem> _items = [
    WhmsDensHubItem(
      l10nKey: 'whms.hub.stock_query',
      route: WhmsRouteMap.whmsStockQuery,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.lot',
      route: WhmsRouteMap.whmsLot,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.reservation',
      route: WhmsRouteMap.whmsReservation,
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
        title: l10n.translate('whms.hub.section_stock'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          Text(
            l10n.translate('whms.hub.stock_hint'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_stock',
            items: _items,
          ),
        ],
      ),
    );
  }
}
