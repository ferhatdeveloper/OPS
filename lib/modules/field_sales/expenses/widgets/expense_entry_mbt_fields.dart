// Dosya Adı: expense_entry_mbt_fields.dart
// Açıklama: Masraf girişi dens flat alan grubu (tip · tutar · not)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/expense_record.dart';

/// {@template expense_entry_mbt_fields}
/// Masraf dens alanları: tip · tutar · açıklama.
///
/// Kullanım örneği:
/// ```dart
/// ExpenseEntryMbtFields(
///   type: ExpenseType.fuel,
///   onTypeChanged: (_) {},
///   amountController: amountCtrl,
///   noteController: noteCtrl,
/// )
/// ```
/// {@endtemplate}
class ExpenseEntryMbtFields extends StatelessWidget {
  /// [type]: Seçili masraf tipi
  final ExpenseType type;

  /// [onTypeChanged]: Tip değişimi
  final ValueChanged<ExpenseType> onTypeChanged;

  /// [amountController]: Tutar
  final TextEditingController amountController;

  /// [noteController]: Açıklama
  final TextEditingController noteController;

  /// {@macro expense_entry_mbt_fields}
  const ExpenseEntryMbtFields({
    Key? key,
    required this.type,
    required this.onTypeChanged,
    required this.amountController,
    required this.noteController,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.translate('field_sales.expense.fields_title'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ExpenseType>(
          value: type,
          isExpanded: true,
          decoration: _decoration(
            l10n.translate('field_sales.expense.type_label'),
          ),
          items: ExpenseType.values
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    l10n.translate(t.labelKey),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onTypeChanged(v);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: amountController,
          style: const TextStyle(fontSize: 13),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: _decoration(
            l10n.translate('field_sales.expense.amount_label'),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: noteController,
          style: const TextStyle(fontSize: 13),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(
            l10n.translate('field_sales.expense.note_label'),
          ),
        ),
      ],
    );
  }
}
