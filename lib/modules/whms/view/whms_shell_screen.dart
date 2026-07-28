// Dosya Adı: whms_shell_screen.dart
// Açıklama: WHMS /whms shell — kategorili dens hub (DEYS hissi)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import 'whms_dens_hub_section.dart';

/// {@template whms_shell_screen}
/// Merkez depo giriş kabuğu. Plasiyer `fs_stock` menüsüne gömülmez.
/// Bölümler: Emirler · Tanımlamalar · Stok · Raporlar · Sistem · Etiket.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsShellScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsShellScreen extends StatelessWidget {
  /// [routeName]: `/whms`
  static const String routeName = WhmsRouteMap.whmsShell;

  /// {@macro whms_shell_screen}
  const WhmsShellScreen({super.key});

  static const List<WhmsDensHubItem> _orders = [
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

  static const List<WhmsDensHubItem> _defs = [
    WhmsDensHubItem(
      l10nKey: 'whms.defs.warehouses',
      route: WhmsRouteMap.whmsMultiWarehouse,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.locations',
      route: WhmsRouteMap.whmsLocations,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.fifo',
      route: WhmsRouteMap.whmsFifo,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.packages',
      route: WhmsRouteMap.whmsPackageTypes,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.tares',
      route: WhmsRouteMap.whmsTares,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.templates',
      route: WhmsRouteMap.whmsLabelTemplates,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.devices',
      route: WhmsRouteMap.whmsDevices,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.vehicle_types',
      route: WhmsRouteMap.whmsVehicleTypes,
    ),
    WhmsDensHubItem(
      l10nKey: 'whms.defs.vehicles',
      route: WhmsRouteMap.whmsVehicles,
    ),
  ];

  static const List<WhmsDensHubItem> _stock = [
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

  static const List<WhmsDensHubItem> _reports = [
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

  static const List<WhmsDensHubItem> _system = [
    WhmsDensHubItem(
      l10nKey: 'whms.system.title',
      route: WhmsRouteMap.whmsSystem,
    ),
  ];

  static const List<WhmsDensHubItem> _labels = [
    WhmsDensHubItem(
      l10nKey: 'field_sales.menu.sub_whms_labels',
      route: WhmsRouteMap.whmsLabels,
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
        title: l10n.translate('whms.module_name'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          Text(
            l10n.translate('whms.hub_title'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.translate('whms.hub_native_hint'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_orders',
            items: _orders,
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_defs',
            items: _defs,
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_stock',
            items: _stock,
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_reports',
            items: _reports,
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_system',
            items: _system,
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_labels',
            items: _labels,
          ),
        ],
      ),
    );
  }
}
