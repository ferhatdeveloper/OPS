// Dosya Adı: collection_cash_mbt_fields.dart
// Açıklama: MBT nakit tahsilat dens flat alan grubu (kasa/tutar/plasiyer/açıklama)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import 'cash_card_code_field.dart';

/// {@template collection_cash_mbt_fields}
/// Nakit tahsilat MBT dens alanları: İşlem Dövizi · EVRAK NO · KASA KODU ·
/// AÇIKLAMA · TUTAR · PLASIYER · ÖZELKOD 1.
///
/// Kasa Kodu: CashCardList / master dens seçici (safe_code).
///
/// Kullanım örneği:
/// ```dart
/// CollectionCashMbtFields(
///   currencyController: currencyCtrl,
///   documentNoController: docCtrl,
///   cashCodeController: cashCtrl,
///   descriptionController: descCtrl,
///   amountController: amountCtrl,
///   salespersonController: salesCtrl,
///   specialCodeController: specialCtrl,
/// )
/// ```
/// {@endtemplate}
class CollectionCashMbtFields extends StatelessWidget {
  /// [currencyController]: İşlem dövizi
  final TextEditingController currencyController;

  /// [documentNoController]: Evrak no
  final TextEditingController documentNoController;

  /// [cashCodeController]: Kasa kodu (safe_code)
  final TextEditingController cashCodeController;

  /// [descriptionController]: Açıklama
  final TextEditingController descriptionController;

  /// [amountController]: Tutar (dens; üst tutar kartı ile aynı controller)
  final TextEditingController amountController;

  /// [salespersonController]: Plasiyer kodu / adı
  final TextEditingController salespersonController;

  /// [specialCodeController]: Özelkod 1
  final TextEditingController specialCodeController;

  /// [showAmountField]: Dens tutar satırı gösterilsin mi
  final bool showAmountField;

  /// [titleL10nKey]: Başlık çeviri anahtarı (nakit tahsilat / nakit ödeme)
  final String titleL10nKey;

  /// {@macro collection_cash_mbt_fields}
  const CollectionCashMbtFields({
    Key? key,
    required this.currencyController,
    required this.documentNoController,
    required this.cashCodeController,
    required this.descriptionController,
    required this.amountController,
    required this.salespersonController,
    required this.specialCodeController,
    this.showAmountField = true,
    this.titleL10nKey = 'field_sales.collection_cash_fields_title',
  }) : super(key: key);

  /// {@template collection_cash_mbt_fields_decoration}
  /// Dense flat InputDecoration (voucher_defaults stil token'ları).
  /// {@endtemplate}
  InputDecoration _decoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
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

  /// {@template collection_cash_mbt_fields_text}
  /// Tek satır dens TextField.
  /// {@endtemplate}
  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.characters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: _decoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.translate(titleL10nKey),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 10),
        _textField(
          controller: currencyController,
          label: l10n.translate('field_sales.collection_transaction_currency'),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: documentNoController,
          label: l10n.translate('field_sales.collection_document_no'),
        ),
        const SizedBox(height: 8),
        CashCardCodeField(
          controller: cashCodeController,
          label: l10n.translate('field_sales.payment_cash_code'),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: descriptionController,
          label: l10n.translate('field_sales.fis_description'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          textInputAction: TextInputAction.next,
        ),
        if (showAmountField) ...[
          const SizedBox(height: 8),
          _textField(
            controller: amountController,
            label: l10n.translate('field_sales.collection_cash_amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textCapitalization: TextCapitalization.none,
          ),
        ],
        const SizedBox(height: 8),
        _textField(
          controller: salespersonController,
          label: l10n.translate('field_sales.collection_salesperson'),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: specialCodeController,
          label: l10n.translate('field_sales.fis_special_code_1'),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
