// Dosya Adı: visit_mbt_fields.dart
// Açıklama: MBT ziyaret formu dens flat alan grubu (EKLER image/file picker)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../engine/visit_attachment_picker.dart';

/// {@template visit_mbt_fields}
/// KOD…EKLER + not/sonuç dens flat alanları (MBT parity).
///
/// Kullanım örneği:
/// ```dart
/// VisitMbtFields(
///   codeController: codeCtrl,
///   titleController: titleCtrl,
///   ...
///   visitReason: reasonCode,
///   onVisitReasonChanged: (_) {},
///   outcome: outcome,
///   onOutcomeChanged: (_) {},
///   reasonOptions: VisitReasonMaster.labeled(l10n),
///   outcomeOptions: outcomes,
/// )
/// ```
/// {@endtemplate}
class VisitMbtFields extends StatelessWidget {
  /// [codeController]: KOD
  final TextEditingController codeController;

  /// [titleController]: ÜNVAN
  final TextEditingController titleController;

  /// [addressController]: ADRES
  final TextEditingController addressController;

  /// [cityController]: İL
  final TextEditingController cityController;

  /// [districtController]: İLÇE
  final TextEditingController districtController;

  /// [countryController]: ÜLKE
  final TextEditingController countryController;

  /// [customerTypeController]: MÜŞTERI TIPI
  final TextEditingController customerTypeController;

  /// [departmentController]: BÖLÜM
  final TextEditingController departmentController;

  /// [contactController]: İLGILI KIŞI
  final TextEditingController contactController;

  /// [projectController]: PROJE KODU
  final TextEditingController projectController;

  /// [referenceController]: REFERANS KIŞI
  final TextEditingController referenceController;

  /// [attachmentsController]: EKLER
  final TextEditingController attachmentsController;

  /// [notesController]: Not
  final TextEditingController notesController;

  /// [notesHeader]: Not alanı üstü dens şerit (ör. STT kayıt)
  final Widget? notesHeader;

  /// [visitReason]: Seçili ziyaret sebebi kodu (null = Seçim)
  final String? visitReason;
  /// [onVisitReasonChanged]: Sebep kodu değişimi
  final ValueChanged<String?> onVisitReasonChanged;

  /// [outcome]: Seçili sonuç
  final String? outcome;

  /// [onOutcomeChanged]: Sonuç değişimi
  final ValueChanged<String?> onOutcomeChanged;

  /// [reasonOptions]: ZIYARET SEBEBI master satırları
  /// (`code` + `label` map; dens dropdown)
  final List<Map<String, String>> reasonOptions;

  /// [outcomeOptions]: Sonuç seçenekleri
  final List<String> outcomeOptions;

  /// [customerReadOnly]: Cari alanları salt okunur mu
  final bool customerReadOnly;

  /// [attachmentPicker]: Test / DI için EKLER picker
  final VisitAttachmentPicker? attachmentPicker;

  /// {@macro visit_mbt_fields}
  const VisitMbtFields({
    Key? key,
    required this.codeController,
    required this.titleController,
    required this.addressController,
    required this.cityController,
    required this.districtController,
    required this.countryController,
    required this.customerTypeController,
    required this.departmentController,
    required this.contactController,
    required this.projectController,
    required this.referenceController,
    required this.attachmentsController,
    required this.notesController,
    this.notesHeader,
    required this.visitReason,
    required this.onVisitReasonChanged,
    required this.outcome,
    required this.onOutcomeChanged,
    required this.reasonOptions,
    required this.outcomeOptions,
    this.customerReadOnly = true,
    this.attachmentPicker,
  }) : super(key: key);

  /// {@template visit_mbt_fields_decoration}
  /// Dense flat InputDecoration (voucher_defaults stil token'ları).
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

  /// {@template visit_mbt_fields_text}
  /// Tek satır dens TextFormField.
  /// {@endtemplate}
  Widget _textField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool enabled,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      textCapitalization: TextCapitalization.sentences,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: _decoration(context, label),
      validator: validator,
    );
  }

  /// {@template visit_mbt_attachments_field}
  /// EKLER dens dosya/foto picker (gerçek seçim veya stub path).
  /// {@endtemplate}
  Widget _attachmentsField(BuildContext context, AppLocalization l10n) {
    final fileLabel = l10n.translate('field_sales.visit_mbt_attach_file');
    final photoLabel = l10n.translate('field_sales.visit_mbt_attach_photo');
    return TextFormField(
      controller: attachmentsController,
      readOnly: true,
      style: const TextStyle(fontSize: 13),
      textCapitalization: TextCapitalization.none,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onTap: () => _openAttachmentsPicker(context, l10n),
      decoration: _decoration(context, 
        l10n.translate('field_sales.visit_mbt_attachments'),
      ).copyWith(
        hintText: l10n.translate('field_sales.visit_mbt_attach_hint'),
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: fileLabel,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              icon: Icon(
                Icons.attach_file,
                size: 18,
                color: Colors.grey.shade700,
              ),
              onPressed: () => _pickAttachment(
                context,
                l10n,
                kind: VisitAttachKind.file,
              ),
            ),
            IconButton(
              tooltip: photoLabel,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              icon: Icon(
                Icons.photo_camera_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              onPressed: () => _pickAttachment(
                context,
                l10n,
                kind: VisitAttachKind.photo,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  /// {@template _openAttachmentsPicker}
  /// Dens bottom sheet: Dosya / Foto seçenekleri.
  /// {@endtemplate}
  void _openAttachmentsPicker(
    BuildContext context,
    AppLocalization l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FieldSalesDensTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.attach_file, size: 20),
                title: Text(
                  l10n.translate('field_sales.visit_mbt_attach_file'),
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAttachment(
                    context,
                    l10n,
                    kind: VisitAttachKind.file,
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_camera_outlined, size: 20),
                title: Text(
                  l10n.translate('field_sales.visit_mbt_attach_photo'),
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAttachment(
                    context,
                    l10n,
                    kind: VisitAttachKind.photo,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// {@template _pickAttachment}
  /// image_picker / file_picker veya net stub path; dens SnackBar.
  /// {@endtemplate}
  Future<void> _pickAttachment(
    BuildContext context,
    AppLocalization l10n, {
    required VisitAttachKind kind,
  }) async {
    final picker = attachmentPicker ?? VisitAttachmentPicker();
    final result = kind == VisitAttachKind.file
        ? await picker.pickFile()
        : await picker.pickPhoto();
    if (!context.mounted || result == null) return;

    final token = result.path.trim();
    if (token.isEmpty) return;

    final current = attachmentsController.text.trim();
    if (current.isEmpty) {
      attachmentsController.text = token;
    } else if (!current.split(',').map((e) => e.trim()).contains(token)) {
      attachmentsController.text = '$current, $token';
    }

    final actionLabel = kind == VisitAttachKind.file
        ? l10n.translate('field_sales.visit_mbt_attach_file')
        : l10n.translate('field_sales.visit_mbt_attach_photo');
    final message = result.isStub
        ? l10n.translate(
            'field_sales.visit_mbt_attach_picker_stub',
            args: {'action': actionLabel, 'path': token},
          )
        : l10n.translate(
            'field_sales.visit_mbt_attach_picked',
            args: {'action': actionLabel, 'path': token},
          );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final reasonCodes =
        reasonOptions.map((o) => o['code'] ?? '').where((c) => c.isNotEmpty);
    final reasonValue =
        visitReason != null && reasonCodes.contains(visitReason)
            ? visitReason
            : null;
    final outcomeValue =
        outcome != null && outcomeOptions.contains(outcome) ? outcome : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(
          context: context,
          controller: codeController,
          label: l10n.translate('field_sales.visit_mbt_code'),
          enabled: !customerReadOnly,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: titleController,
          label: l10n.translate('field_sales.visit_mbt_title'),
          enabled: !customerReadOnly,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: addressController,
          label: l10n.translate('field_sales.visit_mbt_address'),
          enabled: !customerReadOnly,
          maxLines: 2,
          keyboardType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: cityController,
          label: l10n.translate('field_sales.visit_mbt_city'),
          enabled: !customerReadOnly,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: districtController,
          label: l10n.translate('field_sales.visit_mbt_district'),
          enabled: !customerReadOnly,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: countryController,
          label: l10n.translate('field_sales.visit_mbt_country'),
          enabled: !customerReadOnly,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: reasonValue,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
          decoration: _decoration(context, 
            l10n.translate('field_sales.visit_mbt_reason'),
          ),
          hint: Text(
            l10n.translate('field_sales.visit_mbt_reason_select'),
            style: const TextStyle(fontSize: 13),
          ),
          items: reasonOptions
              .where((r) => (r['code'] ?? '').isNotEmpty)
              .map(
                (r) => DropdownMenuItem(
                  value: r['code'],
                  child: Text(
                    r['label'] ?? r['code']!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: onVisitReasonChanged,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate('field_sales.visit_reason_required');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: customerTypeController,
          label: l10n.translate('field_sales.visit_mbt_customer_type'),
          enabled: true,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: departmentController,
          label: l10n.translate('field_sales.visit_mbt_department'),
          enabled: true,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: contactController,
          label: l10n.translate('field_sales.visit_mbt_contact'),
          enabled: true,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: projectController,
          label: l10n.translate('field_sales.visit_mbt_project'),
          enabled: true,
        ),
        const SizedBox(height: 8),
        _textField(
          context: context,
          controller: referenceController,
          label: l10n.translate('field_sales.visit_mbt_reference'),
          enabled: true,
        ),
        const SizedBox(height: 8),
        _attachmentsField(context, l10n),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: outcomeValue,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
          decoration: _decoration(context, 
            l10n.translate('field_sales.visit_outcome'),
          ),
          items: outcomeOptions
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onOutcomeChanged,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate('field_sales.visit_outcome_required');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        if (notesHeader != null) notesHeader!,
        _textField(
          context: context,
          controller: notesController,
          label: l10n.translate('field_sales.visit_note_label'),
          enabled: true,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return l10n.translate('field_sales.note_required');
            }
            return null;
          },
        ),
      ],
    );
  }
}
