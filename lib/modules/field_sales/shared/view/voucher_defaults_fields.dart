// Dosya Adı: voucher_defaults_fields.dart
// Açıklama: Fiş ön değer alanları (Açıklama, Plaka No, Özelkod) — MBT parity
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../viewmodel/voucher_defaults_store.dart';

/// {@template voucher_defaults_fields}
/// Fiş ön değer TextField grubu: Açıklama, Plaka No, Özelkod 1.
/// initState'te SharedPreferences fiş ön değerlerini yükler
/// (sipariş / fatura / irsaliye).
///
/// Kullanım örneği:
/// ```dart
/// VoucherDefaultsFields(
///   descriptionController: descriptionCtrl,
///   plateController: plateCtrl,
///   specialCodeController: specialCodeCtrl,
/// )
/// ```
/// {@endtemplate}
class VoucherDefaultsFields extends StatefulWidget {
  /// [descriptionController]: Açıklama alanı (opsiyonel; yoksa dahili)
  final TextEditingController? descriptionController;

  /// [plateController]: Plaka No alanı (opsiyonel; yoksa dahili)
  final TextEditingController? plateController;

  /// [specialCodeController]: Özelkod 1 alanı (opsiyonel; yoksa dahili)
  final TextEditingController? specialCodeController;

  /// [store]: Prefs katmanı (test için enjekte edilebilir)
  final VoucherDefaultsStore store;

  /// [loadDefaults]: true ise prefs'ten varsayılanları doldurur
  final bool loadDefaults;

  const VoucherDefaultsFields({
    super.key,
    this.descriptionController,
    this.plateController,
    this.specialCodeController,
    this.store = const VoucherDefaultsStore(),
    this.loadDefaults = true,
  });

  @override
  State<VoucherDefaultsFields> createState() => _VoucherDefaultsFieldsState();
}

class _VoucherDefaultsFieldsState extends State<VoucherDefaultsFields> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _plateController;
  late final TextEditingController _specialCodeController;
  late final bool _ownsDescription;
  late final bool _ownsPlate;
  late final bool _ownsSpecialCode;

  @override
  void initState() {
    super.initState();
    _ownsDescription = widget.descriptionController == null;
    _ownsPlate = widget.plateController == null;
    _ownsSpecialCode = widget.specialCodeController == null;
    _descriptionController =
        widget.descriptionController ?? TextEditingController();
    _plateController = widget.plateController ?? TextEditingController();
    _specialCodeController =
        widget.specialCodeController ?? TextEditingController();
    if (widget.loadDefaults) {
      _applyStoredDefaults();
    }
  }

  /// {@template _applyStoredDefaults}
  /// SharedPreferences fiş ön değerlerini boş controller'lara yazar.
  /// Dolu controller metni ezilmez.
  /// {@endtemplate}
  Future<void> _applyStoredDefaults() async {
    final record = await widget.store.load();
    if (!mounted) return;
    if (_descriptionController.text.isEmpty && record.description.isNotEmpty) {
      _descriptionController.text = record.description;
    }
    if (_plateController.text.isEmpty && record.plateNo.isNotEmpty) {
      _plateController.text = record.plateNo;
    }
    if (_specialCodeController.text.isEmpty &&
        record.specialCode1.isNotEmpty) {
      _specialCodeController.text = record.specialCode1;
    }
  }

  @override
  void dispose() {
    if (_ownsDescription) _descriptionController.dispose();
    if (_ownsPlate) _plateController.dispose();
    if (_ownsSpecialCode) _specialCodeController.dispose();
    super.dispose();
  }

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
        TextField(
          controller: _descriptionController,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            l10n.translate('field_sales.fis_description'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _plateController,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            l10n.translate('field_sales.fis_plate_no'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _specialCodeController,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: _decoration(
            l10n.translate('field_sales.fis_special_code_1'),
          ),
        ),
      ],
    );
  }
}
