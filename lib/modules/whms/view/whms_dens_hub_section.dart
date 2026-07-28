// Dosya Adı: whms_dens_hub_section.dart
// Açıklama: WHMS dens hub bölüm başlığı + satır listesi (shell / alt hub)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../core/localization/app_localization.dart';

/// {@template whms_dens_hub_item}
/// Hub satırı — l10n + named route.
///
/// Kullanım örneği:
/// ```dart
/// const WhmsDensHubItem(l10nKey: 'whms.hub.orders', route: '/whms/orders');
/// ```
/// {@endtemplate}
class WhmsDensHubItem {
  /// [l10nKey]: Çeviri anahtarı
  final String l10nKey;

  /// [route]: Named route
  final String route;

  /// {@macro whms_dens_hub_item}
  const WhmsDensHubItem({
    required this.l10nKey,
    required this.route,
  });
}

/// {@template whms_dens_hub_section}
/// Bölüm başlığı + dens satırlar (DEYS hissi, Flutter dens).
///
/// Kullanım örneği:
/// ```dart
/// WhmsDensHubSection(
///   titleKey: 'whms.hub.section_orders',
///   items: const [WhmsDensHubItem(...)],
/// )
/// ```
/// {@endtemplate}
class WhmsDensHubSection extends StatelessWidget {
  /// [titleKey]: Bölüm başlığı l10n
  final String titleKey;

  /// [items]: Satırlar
  final List<WhmsDensHubItem> items;

  /// {@macro whms_dens_hub_section}
  const WhmsDensHubSection({
    super.key,
    required this.titleKey,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
          child: Text(
            l10n.translate(titleKey),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FieldSalesDensTheme.muted(context),
            ),
          ),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: FieldSalesDensTheme.surface(context),
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
                            fontWeight: FontWeight.w400,
                            color: FieldSalesDensTheme.title(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: FieldSalesDensTheme.muted(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
