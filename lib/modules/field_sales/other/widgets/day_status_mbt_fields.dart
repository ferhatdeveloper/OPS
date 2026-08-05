// Dosya Adı: day_status_mbt_fields.dart
// Açıklama: MBT gün başla/bitir dense flat form alanları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../ai_vehicle_vision/view/vehicle_vision_screen.dart';
import '../model/day_status_record.dart';
import 'day_vehicle_manual_sheet.dart';
import 'day_vehicle_picker_sheet.dart';

/// {@template day_status_mbt_fields}
/// PLAKA, BAŞLANGIÇ KM, BİTİŞ KM, Tamamlandı? dense flat alan grubu.
/// Plaka: kayıtlı araç seç / elle kart / kamera (AI vision).
///
/// Kullanım örneği:
/// ```dart
/// DayStatusMbtFields(
///   plateController: plateCtrl,
///   startKmController: startCtrl,
///   endKmController: endCtrl,
///   completed: false,
///   onCompletedChanged: (_) {},
/// )
/// ```
/// {@endtemplate}
class DayStatusMbtFields extends StatelessWidget {
  /// [plateController]: Plaka alanı
  final TextEditingController plateController;

  /// [startKmController]: Başlangıç KM alanı
  final TextEditingController startKmController;

  /// [endKmController]: Bitiş KM alanı
  final TextEditingController endKmController;

  /// [completed]: Tamamlandı? değeri
  final bool completed;

  /// [onCompletedChanged]: Tamamlandı değişimi
  final ValueChanged<bool> onCompletedChanged;

  /// [showStartKm]: Başlangıç KM gösterilsin mi
  final bool showStartKm;

  /// [showEndKm]: Bitiş KM gösterilsin mi
  final bool showEndKm;

  /// [showCompleted]: Tamamlandı? gösterilsin mi
  final bool showCompleted;

  /// [enabled]: Alanlar düzenlenebilir mi
  final bool enabled;

  /// [showVehicleActions]: Plaka araç seç/ekle/kamera
  final bool showVehicleActions;

  /// {@macro day_status_mbt_fields}
  const DayStatusMbtFields({
    Key? key,
    required this.plateController,
    required this.startKmController,
    required this.endKmController,
    required this.completed,
    required this.onCompletedChanged,
    this.showStartKm = true,
    this.showEndKm = true,
    this.showCompleted = true,
    this.enabled = true,
    this.showVehicleActions = true,
  }) : super(key: key);

  /// {@template day_status_mbt_fields_decoration}
  /// Dense flat InputDecoration (voucher_defaults stil token'ları).
  /// {@endtemplate}
  InputDecoration _decoration(
    BuildContext context,
    String label, {
    Widget? suffixIcon,
  }) {
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
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIcon == null
          ? null
          : const BoxConstraints(minHeight: 36, maxHeight: 40),
    );
  }

  Future<void> _pickVehicle(BuildContext context) async {
    final vehicle = await showDayVehiclePicker(context);
    if (vehicle == null || !context.mounted) return;
    plateController.text = vehicle.plate;
  }

  Future<void> _addManual(BuildContext context) async {
    final vehicle = await showDayVehicleManualSheet(
      context,
      initialPlate: plateController.text,
    );
    if (vehicle == null || !context.mounted) return;
    plateController.text = vehicle.plate;
    final l10n = AppLocalization.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('field_sales.day_vehicle_saved')),
      ),
    );
  }

  Future<void> _addFromCamera(BuildContext context) async {
    final plate = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const VehicleVisionScreen(
          returnPlateOnSave: true,
        ),
      ),
    );
    if (plate == null || plate.trim().isEmpty || !context.mounted) return;
    plateController.text = plate.trim().toUpperCase();
    final l10n = AppLocalization.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('field_sales.day_vehicle_saved')),
      ),
    );
  }

  Widget? _plateSuffix(BuildContext context, AppLocalization l10n) {
    if (!enabled || !showVehicleActions) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: l10n.translate('field_sales.day_vehicle_select'),
          icon: Icon(
            Icons.list_alt,
            size: 20,
            color: FieldSalesDensTheme.muted(context),
          ),
          onPressed: () => _pickVehicle(context),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: l10n.translate('field_sales.day_vehicle_add_manual'),
          icon: Icon(
            Icons.add,
            size: 20,
            color: FieldSalesDensTheme.muted(context),
          ),
          onPressed: () => _addManual(context),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: l10n.translate('field_sales.day_vehicle_add_camera'),
          icon: Icon(
            Icons.photo_camera_outlined,
            size: 20,
            color: FieldSalesDensTheme.muted(context),
          ),
          onPressed: () => _addFromCamera(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: plateController,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            context,
            l10n.translate('field_sales.day_plate_label'),
            suffixIcon: _plateSuffix(context, l10n),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate('field_sales.day_plate_required');
            }
            return null;
          },
        ),
        if (showStartKm) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: startKmController,
            enabled: enabled,
            style: const TextStyle(fontSize: 13),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoration(
              context,
              l10n.translate('field_sales.day_start_km_label'),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return l10n.translate('field_sales.day_start_km_required');
              }
              if (int.tryParse(val.trim()) == null) {
                return l10n.translate('validation.number');
              }
              return null;
            },
          ),
        ],
        if (showEndKm) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: endKmController,
            enabled: enabled,
            style: const TextStyle(fontSize: 13),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoration(
              context,
              l10n.translate('field_sales.day_end_km_label'),
            ),
            validator: (val) {
              final raw = val?.trim() ?? '';
              if (completed && raw.isEmpty) {
                return l10n.translate('field_sales.day_end_km_required');
              }
              if (raw.isEmpty) return null;
              final endKm = int.tryParse(raw);
              if (endKm == null) {
                return l10n.translate('validation.number');
              }
              final startKm = int.tryParse(startKmController.text.trim());
              final errKey =
                  DayStatusRecord.validateEndKm(startKm, endKm);
              if (errKey != null) {
                return l10n.translate(errKey);
              }
              return null;
            },
          ),
        ],
        if (showCompleted) ...[
          const SizedBox(height: 4),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF375A7F),
            value: completed,
            onChanged: enabled
                ? (v) => onCompletedChanged(v ?? false)
                : null,
            title: Text(
              l10n.translate('field_sales.day_completed_label'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}
