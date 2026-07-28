// Dosya Adı: field_sales_dens_filter_bar.dart
// Açıklama: Dens filtre chip / segment — tek aktif-pasif dil (AppBar altı)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import 'field_sales_dens_app_bar.dart';
import 'field_sales_dens_theme.dart';

/// {@template field_sales_dens_chip_item}
/// Dens chip satırı öğesi (etiket + seçili + tap).
/// {@endtemplate}
class FieldSalesDensChipItem {
  /// [label]: Chip metni (l10n çözülmüş)
  final String label;

  /// [selected]: Aktif mi
  final bool selected;

  /// [onTap]: Dokunma
  final VoidCallback onTap;

  /// {@macro field_sales_dens_chip_item}
  const FieldSalesDensChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// {@template field_sales_dens_chip}
/// Tek dens filtre chip — tip toggle ve dönem preset aynı görsel.
///
/// Aktif: primary dolgu + beyaz metin.
/// Pasif: beyaz dolgu + primary kenar/metin.
///
/// Kullanım örneği:
/// ```dart
/// FieldSalesDensChip(
///   label: '1-SATIŞ',
///   selected: true,
///   onTap: () {},
/// )
/// ```
/// {@endtemplate}
class FieldSalesDensChip extends StatelessWidget {
  /// [chipHeight]: Dens chip yüksekliği
  static const double chipHeight = 30;

  /// [chipRadius]: Kenar yuvarlaklığı (mevcut dens dil)
  static const double chipRadius = 6;

  /// [label]: Etiket
  final String label;

  /// [selected]: Seçili (aktif)
  final bool selected;

  /// [onTap]: Tap
  final VoidCallback? onTap;

  /// [primary]: Vurgu rengi (varsayılan dens primary)
  final Color primary;

  /// [fontSize]: Metin boyutu
  final double fontSize;

  /// {@macro field_sales_dens_chip}
  const FieldSalesDensChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.primary = FieldSalesDensAppBar.primaryColor,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? primary
        : FieldSalesDensTheme.surface(context);
    final fg = selected ? Colors.white : primary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(chipRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(chipRadius),
        child: Container(
          height: chipHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(chipRadius),
            border: Border.all(color: primary, width: 1),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              color: fg,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// {@template field_sales_dens_chip_row}
/// Eşit genişlik dens chip satırı (segment veya dönem).
/// RTL: [Row] Directionality ile otomatik ayna.
///
/// Kullanım örneği:
/// ```dart
/// FieldSalesDensChipRow(items: [
///   FieldSalesDensChipItem(label: 'A', selected: true, onTap: () {}),
/// ])
/// ```
/// {@endtemplate}
class FieldSalesDensChipRow extends StatelessWidget {
  /// [items]: Chip öğeleri
  final List<FieldSalesDensChipItem> items;

  /// [primary]: Vurgu rengi
  final Color primary;

  /// [gap]: Chip arası boşluk
  final double gap;

  /// [fontSize]: Chip metin boyutu
  final double fontSize;

  /// {@macro field_sales_dens_chip_row}
  const FieldSalesDensChipRow({
    super.key,
    required this.items,
    this.primary = FieldSalesDensAppBar.primaryColor,
    this.gap = 4,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: FieldSalesDensChip(
              label: items[i].label,
              selected: items[i].selected,
              onTap: items[i].onTap,
              primary: primary,
              fontSize: fontSize,
            ),
          ),
        ],
      ],
    );
  }
}

/// {@template field_sales_dens_filter_bar}
/// Dens AppBar altı filtre şeridi (chip satırları).
///
/// [FieldSalesDensAppBar.bottom] veya body üstü olarak kullanılır.
/// Tip toggle ve dönem preset aynı [FieldSalesDensChip] dilini paylaşır.
///
/// Kullanım örneği:
/// ```dart
/// FieldSalesDensAppBar(
///   title: title,
///   bottom: FieldSalesDensFilterBar(children: [chipRow]),
/// )
/// ```
/// {@endtemplate}
class FieldSalesDensFilterBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// [barPadding]: Dens kenar boşluk
  static const EdgeInsetsGeometry barPadding = EdgeInsetsDirectional.fromSTEB(
    10,
    6,
    10,
    6,
  );

  /// [rowGap]: Satırlar arası
  static const double rowGap = 6;

  /// [children]: Chip satırları (segment, dönem, …)
  final List<Widget> children;

  /// [backgroundColor]: Şerit arka planı (null → dens body)
  final Color? backgroundColor;

  /// {@macro field_sales_dens_filter_bar}
  const FieldSalesDensFilterBar({
    super.key,
    required this.children,
    this.backgroundColor,
  });

  @override
  Size get preferredSize {
    if (children.isEmpty) return Size.zero;
    final rows = children.length;
    final height = barPadding.resolve(TextDirection.ltr).vertical +
        (rows * FieldSalesDensChip.chipHeight) +
        ((rows - 1).clamp(0, 100) * rowGap);
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Material(
      color: backgroundColor ??
          FieldSalesDensTheme.bodyBackground(context),
      child: Padding(
        padding: barPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: rowGap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
