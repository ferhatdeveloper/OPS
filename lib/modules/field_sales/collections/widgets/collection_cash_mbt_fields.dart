// Dosya Adı: collection_cash_mbt_fields.dart
// Açıklama: MBT nakit tahsilat dens flat alan grubu (döviz/kur/kasa/tutar)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../currency/engine/collection_currency_exchange.dart';
import '../../currency/model/currency_rate_seed.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import 'cash_card_code_field.dart';

/// {@template collection_cash_mbt_fields}
/// Nakit tahsilat MBT dens alanları: İşlem Dövizi · Kur · EVRAK NO ·
/// KASA KODU · AÇIKLAMA · TUTAR · PLASIYER · ÖZELKOD 1.
///
/// Varsayılan döviz merkez/firma kodu; başka dövizde kur alanı +
/// merkez tutarı özeti gösterilir.
///
/// Kullanım örneği:
/// ```dart
/// CollectionCashMbtFields(
///   currencyController: currencyCtrl,
///   rateController: rateCtrl,
///   defaultCurrencyCode: 'TRY',
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

  /// [rateController]: Kur (seçilen → merkez); varsayılan dövizde gizli
  final TextEditingController? rateController;

  /// [defaultCurrencyCode]: Merkez varsayılan para birimi
  final String defaultCurrencyCode;

  /// [currencyCodes]: Seçilebilir kodlar (boşsa seed listesi)
  final List<String> currencyCodes;

  /// [documentNoController]: Evrak no
  final TextEditingController documentNoController;

  /// [cashCodeController]: Kasa kodu (safe_code)
  final TextEditingController cashCodeController;

  /// [descriptionController]: Açıklama
  final TextEditingController descriptionController;

  /// [amountController]: Tutar (işlem dövizi)
  final TextEditingController amountController;

  /// [salespersonController]: Plasiyer kodu / adı
  final TextEditingController salespersonController;

  /// [specialCodeController]: Özelkod 1
  final TextEditingController specialCodeController;

  /// [showAmountField]: Dens tutar satırı gösterilsin mi
  final bool showAmountField;

  /// [titleL10nKey]: Başlık çeviri anahtarı (nakit tahsilat / nakit ödeme)
  final String titleL10nKey;

  /// [onCurrencyChanged]: Döviz seçimi sonrası (kur prefill)
  final ValueChanged<String>? onCurrencyChanged;

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
    TextEditingController? rateController,
    TextEditingController? exchangeRateController,
    this.defaultCurrencyCode =
        CollectionCurrencyExchange.fallbackDefaultCode,
    this.currencyCodes = const [],
    this.showAmountField = true,
    this.titleL10nKey = 'field_sales.collection_cash_fields_title',
    this.onCurrencyChanged,
  })  : rateController = rateController ?? exchangeRateController,
        super(key: key);

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

  List<String> get _codes {
    if (currencyCodes.isNotEmpty) return currencyCodes;
    return CurrencyRateSeed.codes;
  }

  bool get _isForeign {
    return !CollectionCurrencyExchange.isDefaultCurrency(
      currencyController.text,
      defaultCurrencyCode,
    );
  }

  String? get _baseAmountHint {
    if (!_isForeign || rateController == null) return null;
    final amount = CollectionCurrencyExchange.parseRate(
          amountController.text,
        ) ??
        0;
    final rate = CollectionCurrencyExchange.parseRate(
          rateController!.text,
        ) ??
        0;
    final base = CollectionCurrencyExchange.toBaseAmount(
      amountInCurrency: amount,
      exchangeRate: rate,
    );
    if (base <= 0) return null;
    final baseCode = CollectionCurrencyExchange.normalize(
      defaultCurrencyCode,
    );
    return '${CollectionCurrencyExchange.formatRate(base)} $baseCode';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final selected = CollectionCurrencyExchange.normalize(
      currencyController.text,
    );
    final codes = List<String>.from(_codes);
    if (selected.isNotEmpty && !codes.contains(selected)) {
      codes.insert(0, selected);
    }
    final effectiveSelected =
        codes.contains(selected) ? selected : (codes.isNotEmpty ? codes.first : selected);
    final baseHint = _baseAmountHint;
    final defCode = CollectionCurrencyExchange.normalize(
      defaultCurrencyCode,
    );

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
        DropdownButtonFormField<String>(
          value: effectiveSelected.isEmpty ? null : effectiveSelected,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
          decoration: _decoration(
            l10n.translate('field_sales.collection_transaction_currency'),
          ),
          items: codes
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(
                    c == defCode
                        ? '$c (${l10n.translate('field_sales.collection_currency_default_badge')})'
                        : c,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            currencyController.text = value;
            onCurrencyChanged?.call(value);
          },
        ),
        if (_isForeign && rateController != null) ...[
          const SizedBox(height: 8),
          _textField(
            controller: rateController!,
            label: l10n.translate('field_sales.collection_exchange_rate'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textCapitalization: TextCapitalization.none,
          ),
          if (baseHint != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.translate(
                'field_sales.collection_base_amount_hint',
                args: {'amount': baseHint},
              ),
              style: const TextStyle(
                fontSize: 11,
                color: FieldSalesDensAppBar.primaryColor,
              ),
            ),
          ],
        ],
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
