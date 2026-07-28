// Dosya Adı: field_sales_dens_app_bar.dart
// Açıklama: MBT dens AppBar — düşük toolbar / kompakt ikon / başlık (görsel dil korunur)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

/// {@template field_sales_dens_app_bar}
/// Saha satış dens AppBar yardımcısı.
///
/// Varsayılan: `toolbarHeight` 44, başlık 16sp, kompakt aksiyon ikonları.
/// Renk / gradient mevcut field_sales dilini korur (redesign yok).
///
/// Kullanım örneği:
/// ```dart
/// appBar: FieldSalesDensAppBar(
///   title: l10n.translate('submodules.yonetici_raporlari'),
/// ),
/// ```
/// {@endtemplate}
class FieldSalesDensAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// [kToolbarHeightDens]: Standart dens toolbar yüksekliği (px)
  static const double kToolbarHeightDens = 44;

  /// [primaryColor]: Flat primary (375A7F)
  static const Color primaryColor = Color(0xFF375A7F);

  /// [accentColor]: Flat accent (00A8E8)
  static const Color accentColor = Color(0xFF00A8E8);

  /// [title]: AppBar başlık metni
  final String title;

  /// [backgroundColor]: Düz arka plan (gradient yoksa)
  final Color? backgroundColor;

  /// [useGradient]: true → mevcut 375A7F→00A8E8 flexibleSpace
  final bool useGradient;

  /// [actions]: Ek aksiyonlar (hesap makinesi / ana sayfa öncesi)
  final List<Widget>? actions;

  /// [showCalculatorHome]: MBT calculator + home aksiyonları
  final bool showCalculatorHome;

  /// [bottom]: TabBar vb. alt şerit
  final PreferredSizeWidget? bottom;

  /// [leading]: Opsiyonel leading
  final Widget? leading;

  /// [automaticallyImplyLeading]: Geri ok
  final bool automaticallyImplyLeading;

  /// {@macro field_sales_dens_app_bar}
  const FieldSalesDensAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.useGradient = false,
    this.actions,
    this.showCalculatorHome = true,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  /// {@template field_sales_dens_icon_button}
  /// Kompakt AppBar [IconButton] (piksel verimli).
  ///
  /// Parametreler:
  /// - [icon]: İkon
  /// - [onPressed]: Dokunma
  /// - [tooltip]: Erişilebilirlik
  ///
  /// Dönüş değeri:
  /// - [Widget]: Kompakt IconButton
  /// {@endtemplate}
  static Widget densIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
      splashRadius: 18,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeightDens + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedActions = <Widget>[
      ...?actions,
      if (showCalculatorHome) ...[
        densIconButton(
          icon: Icons.calculate,
          onPressed: () {},
        ),
        densIconButton(
          icon: Icons.home,
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        const SizedBox(width: 4),
      ],
    ];

    return AppBar(
      toolbarHeight: kToolbarHeightDens,
      titleSpacing: 0,
      leadingWidth: 40,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
          height: 1.1,
        ),
      ),
      backgroundColor: useGradient
          ? Colors.transparent
          : (backgroundColor ?? primaryColor),
      flexibleSpace: useGradient
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, accentColor],
                ),
              ),
            )
          : null,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white, size: 20),
      actionsIconTheme: const IconThemeData(color: Colors.white, size: 20),
      actions: resolvedActions.isEmpty ? null : resolvedActions,
      bottom: bottom,
    );
  }
}
