// Dosya Adı: mbt_catalog_toolbar.dart
// Açıklama: MBT belge katalog araç çubuğu (Stok/Hizmet/Kod/Barkod/…) — dens stub UI
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template MbtCatalogToolbarAction}
/// Katalog araç çubuğu aksiyon kimlikleri (MBT parity).
/// {@endtemplate}
enum MbtCatalogToolbarAction {
  /// Stok Kartı
  stockCard,

  /// Hizmet Kartı
  serviceCard,

  /// Kod/Ad
  codeName,

  /// Barkod
  barcode,

  /// Kamera
  camera,

  /// Grup
  group,

  /// Resim
  image,

  /// Ara
  search,
}

/// {@template MbtCatalogToolbar}
/// MBT belge UI dens katalog araç çubuğu.
///
/// Aksiyonlar varsayılan olarak SnackBar stub gösterir; [onAction] ile
/// override edilebilir (örn. barkod taraması).
///
/// Kullanım örneği:
/// ```dart
/// MbtCatalogToolbar(
///   onAction: (action) {
///     if (action == MbtCatalogToolbarAction.barcode) _scanBarcode();
///   },
/// )
/// ```
/// {@endtemplate}
class MbtCatalogToolbar extends StatelessWidget {
  /// [onAction]: Aksiyon seçildiğinde çağrılır; null ise stub SnackBar
  final void Function(MbtCatalogToolbarAction action)? onAction;

  const MbtCatalogToolbar({
    super.key,
    this.onAction,
  });

  static const Color _barColor = Color(0xFF375A7F);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final items = <(MbtCatalogToolbarAction, String, IconData)>[
      (
        MbtCatalogToolbarAction.stockCard,
        l10n.translate('field_sales.mbt_toolbar.stock_card'),
        Icons.inventory_2_outlined,
      ),
      (
        MbtCatalogToolbarAction.serviceCard,
        l10n.translate('field_sales.mbt_toolbar.service_card'),
        Icons.miscellaneous_services_outlined,
      ),
      (
        MbtCatalogToolbarAction.codeName,
        l10n.translate('field_sales.mbt_toolbar.code_name'),
        Icons.abc,
      ),
      (
        MbtCatalogToolbarAction.barcode,
        l10n.translate('field_sales.mbt_toolbar.barcode'),
        Icons.qr_code_2,
      ),
      (
        MbtCatalogToolbarAction.camera,
        l10n.translate('field_sales.mbt_toolbar.camera'),
        Icons.photo_camera_outlined,
      ),
      (
        MbtCatalogToolbarAction.group,
        l10n.translate('field_sales.mbt_toolbar.group'),
        Icons.folder_outlined,
      ),
      (
        MbtCatalogToolbarAction.image,
        l10n.translate('field_sales.mbt_toolbar.image'),
        Icons.image_outlined,
      ),
      (
        MbtCatalogToolbarAction.search,
        l10n.translate('field_sales.mbt_toolbar.search'),
        Icons.search,
      ),
    ];

    return Container(
      color: _barColor,
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final (action, label, icon) = items[index];
          return TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _handleTap(context, l10n, action, label),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// {@template _handleTap}
  /// Araç çubuğu aksiyonunu işler; [onAction] yoksa stub SnackBar gösterir.
  /// {@endtemplate}
  void _handleTap(
    BuildContext context,
    AppLocalization l10n,
    MbtCatalogToolbarAction action,
    String label,
  ) {
    if (onAction != null) {
      onAction!(action);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate(
            'field_sales.mbt_toolbar.stub_action',
            args: {'action': label},
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
