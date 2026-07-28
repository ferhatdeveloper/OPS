// Dosya Adı: whms_defs_hub_screen.dart
// Açıklama: WHMS Tanımlamalar dens hub — ambar / lokasyon / FIFO / araç…
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import 'whms_dens_hub_section.dart';

/// {@template whms_defs_hub_screen}
/// Tanımlamalar hub — yalnız `/whms/*` alt route’lar.
/// Route: `/whms/defs`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsDefsHubScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsDefsHubScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsDefs;

  /// {@macro whms_defs_hub_screen}
  const WhmsDefsHubScreen({super.key});

  static const List<WhmsDensHubItem> _rows = [
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.menu.sub_whms_defs'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          Text(
            l10n.translate('whms.defs.hub_hint'),
            style: TextStyle(
              fontSize: 12,
              color: FieldSalesDensTheme.muted(context),
            ),
          ),
          const WhmsDensHubSection(
            titleKey: 'whms.hub.section_defs',
            items: _rows,
          ),
        ],
      ),
    );
  }
}
