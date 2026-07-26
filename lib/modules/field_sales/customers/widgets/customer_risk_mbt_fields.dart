// Dosya Adı: customer_risk_mbt_fields.dart
// Açıklama: MBT müşteri risk dens flat alan grubu (limit / bakiye)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template customer_risk_mbt_fields}
/// Cari kod/ünvan + Risk Limiti / Bakiye / Kullanılabilir / Yaş. Borç dens alanlar.
///
/// Kullanım örneği:
/// ```dart
/// CustomerRiskMbtFields(
///   codeController: codeCtrl,
///   nameController: nameCtrl,
///   riskLimitController: limitCtrl,
///   balanceController: balanceCtrl,
///   availableController: availableCtrl,
///   agingController: agingCtrl,
///   statusLabel: 'Uygun',
/// )
/// ```
/// {@endtemplate}
class CustomerRiskMbtFields extends StatelessWidget {
  /// [codeController]: Cari kodu
  final TextEditingController codeController;

  /// [nameController]: Cari ünvanı
  final TextEditingController nameController;

  /// [riskLimitController]: Risk limiti (credit_limit)
  final TextEditingController riskLimitController;

  /// [balanceController]: Bakiye
  final TextEditingController balanceController;

  /// [availableController]: Kullanılabilir limit
  final TextEditingController availableController;

  /// [agingController]: Yaşlandırılmış borç
  final TextEditingController agingController;

  /// [statusLabel]: Risk durumu metni (l10n çözülmüş)
  final String statusLabel;

  /// [enabled]: Düzenlenebilir mi (stub’ta genelde false)
  final bool enabled;

  /// {@macro customer_risk_mbt_fields}
  const CustomerRiskMbtFields({
    Key? key,
    required this.codeController,
    required this.nameController,
    required this.riskLimitController,
    required this.balanceController,
    required this.availableController,
    required this.agingController,
    required this.statusLabel,
    this.enabled = false,
  }) : super(key: key);

  /// {@template customer_risk_mbt_fields_decoration}
  /// Dense flat InputDecoration (voucher_defaults / day_status token’ları).
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  /// {@template customer_risk_mbt_fields_text}
  /// Tek satır dens TextFormField.
  /// {@endtemplate}
  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: !enabled,
      style: const TextStyle(fontSize: 13),
      textCapitalization: TextCapitalization.none,
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
        _textField(
          controller: codeController,
          label: l10n.translate('field_sales.risk_code_label'),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: nameController,
          label: l10n.translate('field_sales.risk_name_label'),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: riskLimitController,
          label: l10n.translate('field_sales.risk_limit_label'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: balanceController,
          label: l10n.translate('field_sales.balance'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: availableController,
          label: l10n.translate('field_sales.risk_available_label'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        _textField(
          controller: agingController,
          label: l10n.translate('field_sales.risk_aging_label'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: _decoration(
            l10n.translate('field_sales.risk_status_label'),
          ),
          child: Text(
            statusLabel,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
          ),
        ),
      ],
    );
  }
}
