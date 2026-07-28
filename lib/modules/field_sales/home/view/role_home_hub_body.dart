// Dosya Adı: role_home_hub_body.dart
// Açıklama: Plasiyer / depocu dens ana sayfa kısayol ızgarası
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/auth/app_user_role.dart';
import '../../../../core/auth/role_home_menu_filter.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template role_home_hub_body}
/// Rol özel dens hub — mevcut named route’lara gider; redesign yok.
///
/// Kullanım örneği:
/// ```dart
/// RoleHomeHubBody(role: AppUserRole.salesperson);
/// ```
/// {@endtemplate}
class RoleHomeHubBody extends StatelessWidget {
  /// [role]: Oturum rolü
  final AppUserRole role;

  /// {@macro role_home_hub_body}
  const RoleHomeHubBody({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final shortcuts = RoleHomeMenuFilter.hubShortcuts(role);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = FieldSalesDensAppBar.primaryColor;

    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate(
                    role == AppUserRole.warehouseKeeper
                        ? 'role_home.hub_title_warehouse'
                        : 'role_home.hub_title_salesperson',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: primary),
                ),
                child: Text(
                  l10n.translate(role.l10nKey),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cross = constraints.maxWidth >= 420 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shortcuts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.4,
                ),
                itemBuilder: (context, index) {
                  final item = shortcuts[index];
                  return _RoleHubTile(
                    label: l10n.translate(item.l10nKey),
                    icon: item.icon,
                    onTap: () {
                      Navigator.of(context).pushNamed(item.route);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dens hub satır kutusu — mevcut primary dil.
class _RoleHubTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleHubTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = FieldSalesDensAppBar.primaryColor;

    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
