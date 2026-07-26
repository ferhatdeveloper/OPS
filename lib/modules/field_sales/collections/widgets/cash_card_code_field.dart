// Dosya Adı: cash_card_code_field.dart
// Açıklama: CashCardMaster dens seçici alan — nakit Kasa / KK POS
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/cash_card_master.dart';
import '../view/cash_card_list_screen.dart';

/// {@template cash_card_code_field}
/// Kasa / POS kodu dens seçici (readOnly → CashCardList master).
///
/// Kullanım örneği:
/// ```dart
/// CashCardCodeField(
///   controller: cashCtrl,
///   label: l10n.translate('field_sales.cc_pos_code'),
///   prefixIcon: Icons.point_of_sale,
/// )
/// ```
/// {@endtemplate}
class CashCardCodeField extends StatelessWidget {
  /// [controller]: safe_code yazılacak alan
  final TextEditingController controller;

  /// [label]: Yerelleştirilmiş etiket (labelText veya hint)
  final String label;

  /// [prefixIcon]: Opsiyonel önek ikon (KK dens)
  final IconData? prefixIcon;

  /// [prefixIconColor]: Önek ikon rengi
  final Color? prefixIconColor;

  /// [fillColor]: Alan dolgu rengi
  final Color fillColor;

  /// [labelAsHint]: true → hintText (collection_entry parity)
  final bool labelAsHint;

  /// {@macro cash_card_code_field}
  const CashCardCodeField({
    Key? key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.prefixIconColor,
    this.fillColor = Colors.white,
    this.labelAsHint = false,
  }) : super(key: key);

  /// {@template cash_card_code_field_open}
  /// Kasa Kart Listesi dens seçici — sonucu [controller]'a yazar.
  /// {@endtemplate}
  Future<void> _openPicker(BuildContext context) async {
    final selected = await Navigator.of(context).push<CashCardOption>(
      MaterialPageRoute(
        builder: (_) => CashCardListScreen(
          selectionMode: true,
          initialCode: controller.text.trim().isEmpty
              ? CashCardMaster.defaultCode
              : controller.text.trim(),
        ),
      ),
    );
    if (selected == null) return;
    controller.text = selected.code;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade200),
    );

    return TextField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      style: const TextStyle(fontSize: 13),
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onTap: () => _openPicker(context),
      decoration: InputDecoration(
        isDense: true,
        labelText: labelAsHint ? null : label,
        labelStyle: labelAsHint ? null : const TextStyle(fontSize: 13),
        hintText: labelAsHint
            ? label
            : l10n.translate('field_sales.cash_card_select_hint'),
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                size: prefixIconColor != null ? 18 : 20,
                color: prefixIconColor,
              ),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: fillColor,
        border: border,
        enabledBorder: border,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }
}
