// Dosya Adı: competitor_survey_mbt_fields.dart
// Açıklama: MBT rakip anket dens flat form alanları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template competitor_survey_mbt_fields}
/// Marka · Ürün · Fiyat · Stok · Kampanya · Not dens alan grubu.
///
/// Kullanım örneği:
/// ```dart
/// CompetitorSurveyMbtFields(
///   customerCodeController: codeCtrl,
///   brandController: brandCtrl,
///   productController: productCtrl,
///   priceController: priceCtrl,
///   notesController: notesCtrl,
///   hasStock: true,
///   onPromotion: false,
///   onHasStockChanged: (_) {},
///   onPromotionChanged: (_) {},
/// )
/// ```
/// {@endtemplate}
class CompetitorSurveyMbtFields extends StatelessWidget {
  /// [customerCodeController]: Cari kodu
  final TextEditingController customerCodeController;

  /// [brandController]: Rakip marka
  final TextEditingController brandController;

  /// [productController]: Rakip ürün
  final TextEditingController productController;

  /// [priceController]: Gözlemlenen fiyat
  final TextEditingController priceController;

  /// [notesController]: Not
  final TextEditingController notesController;

  /// [hasStock]: Stokta var
  final bool hasStock;

  /// [onPromotion]: Kampanyada
  final bool onPromotion;

  /// [onHasStockChanged]: Stok değişimi
  final ValueChanged<bool> onHasStockChanged;

  /// [onPromotionChanged]: Kampanya değişimi
  final ValueChanged<bool> onPromotionChanged;

  /// [enabled]: Düzenlenebilir mi
  final bool enabled;

  /// {@macro competitor_survey_mbt_fields}
  const CompetitorSurveyMbtFields({
    Key? key,
    required this.customerCodeController,
    required this.brandController,
    required this.productController,
    required this.priceController,
    required this.notesController,
    required this.hasStock,
    required this.onPromotion,
    required this.onHasStockChanged,
    required this.onPromotionChanged,
    this.enabled = true,
  }) : super(key: key);

  /// {@template competitor_survey_mbt_fields_decoration}
  /// Dense flat InputDecoration (day_status / voucher token'ları).
  /// {@endtemplate}
  InputDecoration _decoration(String label, {String? suffix}) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
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
          decoration: _decoration(
            l10n.translate('field_sales.competitor_survey.customer_code'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: brandController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            l10n.translate('field_sales.competitor_survey.brand'),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate(
                'field_sales.competitor_survey.brand_required',
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: productController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            l10n.translate('field_sales.competitor_survey.product'),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate(
                'field_sales.competitor_survey.product_required',
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: priceController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            l10n.translate('field_sales.competitor_survey.price'),
            suffix: '₺',
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.translate('field_sales.competitor_survey.has_stock'),
            style: const TextStyle(fontSize: 13),
          ),
          value: hasStock,
          onChanged: enabled ? onHasStockChanged : null,
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.translate('field_sales.competitor_survey.on_promotion'),
            style: const TextStyle(fontSize: 13),
          ),
          value: onPromotion,
          onChanged: enabled ? onPromotionChanged : null,
        ),
        TextFormField(
          controller: notesController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 2,
          decoration: _decoration(
            l10n.translate('field_sales.competitor_survey.notes'),
          ),
        ),
      ],
    );
  }
}
