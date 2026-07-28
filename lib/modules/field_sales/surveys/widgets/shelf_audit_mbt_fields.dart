// Dosya Adı: shelf_audit_mbt_fields.dart
// Açıklama: MBT raf denetimi dens flat form alanları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template shelf_audit_mbt_fields}
/// Cari · Kategori · Marka · Facing · Raf payı · Stok · Not dens alan grubu.
///
/// Kullanım örneği:
/// ```dart
/// ShelfAuditMbtFields(
///   customerCodeController: codeCtrl,
///   customerNameController: nameCtrl,
///   categoryController: catCtrl,
///   brandController: brandCtrl,
///   facingsController: faceCtrl,
///   shelfShareController: shareCtrl,
///   notesController: notesCtrl,
///   hasStock: true,
///   onHasStockChanged: (_) {},
/// )
/// ```
/// {@endtemplate}
class ShelfAuditMbtFields extends StatelessWidget {
  /// [customerCodeController]: Cari kodu
  final TextEditingController customerCodeController;

  /// [customerNameController]: Cari ünvan
  final TextEditingController customerNameController;

  /// [categoryController]: Kategori / raf
  final TextEditingController categoryController;

  /// [brandController]: Marka
  final TextEditingController brandController;

  /// [facingsController]: Facing adedi
  final TextEditingController facingsController;

  /// [shelfShareController]: Raf payı (%)
  final TextEditingController shelfShareController;

  /// [notesController]: Not
  final TextEditingController notesController;

  /// [hasStock]: Rafta stok
  final bool hasStock;

  /// [onHasStockChanged]: Stok değişimi
  final ValueChanged<bool> onHasStockChanged;

  /// [enabled]: Düzenlenebilir mi
  final bool enabled;

  /// {@macro shelf_audit_mbt_fields}
  const ShelfAuditMbtFields({
    Key? key,
    required this.customerCodeController,
    required this.customerNameController,
    required this.categoryController,
    required this.brandController,
    required this.facingsController,
    required this.shelfShareController,
    required this.notesController,
    required this.hasStock,
    required this.onHasStockChanged,
    this.enabled = true,
  }) : super(key: key);

  /// {@template shelf_audit_mbt_fields_decoration}
  /// Dense flat InputDecoration (day_status / voucher token'ları).
  /// {@endtemplate}
  InputDecoration _decoration(BuildContext context, String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: FieldSalesDensTheme.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: customerCodeController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.customer_code'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: customerNameController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.customer_name'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: categoryController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.category'),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate(
                'field_sales.shelf_audit.category_required',
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: brandController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.brand'),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate(
                'field_sales.shelf_audit.brand_required',
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: facingsController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.facings'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: shelfShareController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.shelf_share'),
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.translate('field_sales.shelf_audit.has_stock'),
            style: const TextStyle(fontSize: 13),
          ),
          value: hasStock,
          onChanged: enabled ? onHasStockChanged : null,
        ),
        TextFormField(
          controller: notesController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 2,
          decoration: _decoration(context, 
            l10n.translate('field_sales.shelf_audit.notes'),
          ),
        ),
      ],
    );
  }
}
