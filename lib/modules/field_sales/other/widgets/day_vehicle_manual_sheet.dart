// Dosya Adı: day_vehicle_manual_sheet.dart
// Açıklama: Elle araç kartı dens formu (plaka + opsiyonel marka/tip)
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../../vehicles/model/vehicle_model.dart';
import '../../vehicles/viewmodel/vehicle_card_store.dart';

/// {@template show_day_vehicle_manual_sheet}
/// Elle araç kartı ekleme bottom sheet.
///
/// Parametreler:
/// - [context]: BuildContext
/// - [store]: Test enjeksiyonu
/// - [initialPlate]: Ön doldurma plaka
///
/// Dönüş değeri:
/// - [VehicleModel?]: Kaydedilen araç veya null
/// {@endtemplate}
Future<VehicleModel?> showDayVehicleManualSheet(
  BuildContext context, {
  VehicleCardStore? store,
  String? initialPlate,
}) {
  return showModalBottomSheet<VehicleModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FieldSalesDensTheme.bodyBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: DayVehicleManualSheet(
          store: store ?? VehicleCardStore(),
          initialPlate: initialPlate,
        ),
      );
    },
  );
}

/// {@template day_vehicle_manual_sheet}
/// Plaka zorunlu; marka/model ve tip opsiyonel dens form.
/// {@endtemplate}
class DayVehicleManualSheet extends StatefulWidget {
  /// [store]: Araç kart deposu
  final VehicleCardStore store;

  /// [initialPlate]: Plaka ön değeri
  final String? initialPlate;

  /// {@macro day_vehicle_manual_sheet}
  const DayVehicleManualSheet({
    Key? key,
    required this.store,
    this.initialPlate,
  }) : super(key: key);

  @override
  State<DayVehicleManualSheet> createState() => _DayVehicleManualSheetState();
}

class _DayVehicleManualSheetState extends State<DayVehicleManualSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(
      text: widget.initialPlate?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
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

  Future<void> _onSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final nameParts = <String>[
        if (_nameController.text.trim().isNotEmpty)
          _nameController.text.trim(),
        if (_typeController.text.trim().isNotEmpty)
          _typeController.text.trim(),
      ];
      final name =
          nameParts.isEmpty ? null : nameParts.join(' ');
      final vehicle = await widget.store.upsertByPlate(
        plate: _plateController.text,
        name: name,
      );
      if (!mounted) return;
      if (vehicle == null) {
        final l10n = AppLocalization.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate('field_sales.day_plate_required'),
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(vehicle);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final primary = const Color(0xFF375A7F);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('field_sales.day_vehicle_manual_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  tooltip:
                      MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _plateController,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      l10n.translate('field_sales.day_plate_label'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.translate(
                          'field_sales.day_plate_required',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      l10n.translate('field_sales.day_vehicle_name_label'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _typeController,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration: _decoration(
                      l10n.translate('field_sales.day_vehicle_type_label'),
                    ),
                    onFieldSubmitted: (_) => _onSave(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.translate('common.save'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
