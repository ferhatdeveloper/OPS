// Dosya Adı: day_status_mbt_fields.dart
// Açıklama: MBT gün başla/bitir dense flat form alanları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/day_status_record.dart';

/// {@template day_status_mbt_fields}
/// PLAKA, BAŞLANGIÇ KM, BİTİŞ KM, Tamamlandı? dense flat alan grubu.
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
  }) : super(key: key);

  /// {@template day_status_mbt_fields_decoration}
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
            l10n.translate('field_sales.day_plate_label'),
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
