// Dosya Adı: whms_labels_hub_screen.dart
// Açıklama: WHMS /whms/labels dens hub — cihaz + paket + dara + şablon
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../contract/whms_route_map.dart';

/// {@template whms_labels_hub_screen}
/// Etiket / cihaz hub — yalnız `/whms/*`.
/// Route: `/whms/labels`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsLabelsHubScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsLabelsHubScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsLabels;

  /// {@macro whms_labels_hub_screen}
  const WhmsLabelsHubScreen({super.key});

  static const List<_HubItem> _items = [
    _HubItem(
      l10nKey: 'whms.labels.devices',
      route: WhmsRouteMap.whmsDevices,
    ),
    _HubItem(
      l10nKey: 'whms.labels.package_types_title',
      route: WhmsRouteMap.whmsPackageTypes,
    ),
    _HubItem(
      l10nKey: 'whms.labels.tares_title',
      route: WhmsRouteMap.whmsTares,
    ),
    _HubItem(
      l10nKey: 'whms.labels.templates_title',
      route: WhmsRouteMap.whmsLabelTemplates,
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
        title: l10n.translate('field_sales.menu.sub_whms_devices'),
        showCalculatorHome: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
        children: [
          Text(
            l10n.translate('whms.labels.hub_hint'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          ..._items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pushNamed(context, item.route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.translate(item.l10nKey),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HubItem {
  final String l10nKey;
  final String route;

  const _HubItem({required this.l10nKey, required this.route});
}
