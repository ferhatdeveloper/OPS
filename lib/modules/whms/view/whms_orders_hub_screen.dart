// Dosya Adı: whms_orders_hub_screen.dart
// Açıklama: WHMS Emirler dens hub — tip satırları → liste/yürütme
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import 'whms_dens_hub_section.dart';

/// {@template whms_orders_hub_screen}
/// Emirler alt hub — DEYS emir menüsü hissi.
/// Route: `/whms/orders-hub`
/// {@endtemplate}
class WhmsOrdersHubScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsOrdersHub;

  /// {@macro whms_orders_hub_screen}
  const WhmsOrdersHubScreen({super.key});

  static const List<WhmsDensHubItem> _items = [
    WhmsDensHubItem(
      l10nKey: 'whms.hub.order_list',
      route: WhmsRouteMap.whmsOrders,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.receipt',
      route: WhmsRouteMap.whmsReceiptList,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.putaway',
      route: WhmsRouteMap.whmsPutaway,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.pick',
      route: WhmsRouteMap.whmsPickList,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.shipping',
      route: WhmsRouteMap.whmsShipping,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.transfer',
      route: WhmsRouteMap.whmsTransfer,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.count',
      route: WhmsRouteMap.whmsCount,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.hub.returns',
      route: WhmsRouteMap.whmsReturns,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.hub.section_orders'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          Text(
            l10n.translate('whms.hub.orders_hint'),
            style: TextStyle(
              fontSize: 12,
              color: FieldSalesDensTheme.muted(context),
            ),
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_orders',
            items: _items,
          ),
        ],
      ),
    );
  }
}
