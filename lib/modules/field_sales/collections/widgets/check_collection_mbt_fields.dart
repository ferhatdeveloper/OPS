// Dosya Adı: check_collection_mbt_fields.dart
// Açıklama: MBT çek tahsilat dens alanları (vade·asıl borçlu·banka·çek no·şube…)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template check_collection_mbt_fields}
/// Çek tahsilat dens flat alan grubu (MBT P0-12).
///
/// Kullanım örneği:
/// ```dart
/// CheckCollectionMbtFields(
///   documentNoController: docCtrl,
///   endorsementController: ciroCtrl,
///   originalDebtorController: debtorCtrl,
///   bankController: bankCtrl,
///   branchController: branchCtrl,
///   workplaceController: wpCtrl,
///   checkNoController: checkCtrl,
///   accountNoController: accountCtrl,
///   dueDate: due,
///   onDueDateTap: () {},
/// )
/// ```
/// {@endtemplate}
class CheckCollectionMbtFields extends StatelessWidget {
  /// [documentNoController]: Evrak no
  final TextEditingController documentNoController;

  /// [endorsementController]: Ciro
  final TextEditingController endorsementController;

  /// [originalDebtorController]: Asıl borçlu
  final TextEditingController originalDebtorController;

  /// [bankController]: Banka
  final TextEditingController bankController;

  /// [branchController]: Şube
  final TextEditingController branchController;

  /// [workplaceController]: İşyeri
  final TextEditingController workplaceController;

  /// [checkNoController]: Çek no
  final TextEditingController checkNoController;

  /// [accountNoController]: Hesap no
  final TextEditingController accountNoController;

  /// [dueDate]: Vade tarihi
  final DateTime? dueDate;

  /// [onDueDateTap]: Vade seçici
  final VoidCallback onDueDateTap;

  /// {@macro check_collection_mbt_fields}
  const CheckCollectionMbtFields({
    Key? key,
    required this.documentNoController,
    required this.endorsementController,
    required this.originalDebtorController,
    required this.bankController,
    required this.branchController,
    required this.workplaceController,
    required this.checkNoController,
    required this.accountNoController,
    required this.dueDate,
    required this.onDueDateTap,
  }) : super(key: key);

  /// {@template check_collection_mbt_fields_decoration}
  /// Dense flat InputDecoration (MBT dens stil token'ları).
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
        TextField(
          controller: documentNoController,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.check_document_no'),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onDueDateTap,
          child: InputDecorator(
            decoration: _decoration(context, 
              l10n.translate('field_sales.check_due_date'),
            ),
            child: Text(
              dueDate == null
                  ? l10n.translate('field_sales.select_date')
                  : l10n.translate(
                      'field_sales.due_date_prefix',
                      args: {
                        'date':
                            '${dueDate!.day}.${dueDate!.month}.${dueDate!.year}',
                      },
                    ),
              style: TextStyle(
                fontSize: 13,
                color: dueDate == null ? Colors.grey.shade600 : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: endorsementController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.check_endorsement'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: originalDebtorController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.check_original_debtor'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: bankController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.bank_name'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: branchController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.branch_name'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: workplaceController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.check_workplace'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: checkNoController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context, 
            l10n.translate('field_sales.check_number'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: accountNoController,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: _decoration(context, 
            l10n.translate('field_sales.check_account_no'),
          ),
        ),
      ],
    );
  }
}
