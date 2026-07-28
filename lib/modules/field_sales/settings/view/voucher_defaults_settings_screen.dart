// Dosya Adı: voucher_defaults_settings_screen.dart
// Açıklama: Fiş ön değerleri ekranı (MBT: AÇIKLAMA, PLAKA NO, ÖZELKOD 1)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/model/voucher_defaults_record.dart';
import '../../shared/viewmodel/voucher_defaults_store.dart';

/// {@template voucher_defaults_settings_screen}
/// Fatura / irsaliye fiş ön değerleri (MBT alanları).
///
/// Rota: `/field-sales/voucher-defaults`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   VoucherDefaultsSettingsScreen.routeName,
/// );
/// ```
/// {@endtemplate}
class VoucherDefaultsSettingsScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/voucher-defaults`
  static const String routeName = '/field-sales/voucher-defaults';

  const VoucherDefaultsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VoucherDefaultsSettingsScreen> createState() =>
      _VoucherDefaultsSettingsScreenState();
}

class _VoucherDefaultsSettingsScreenState
    extends State<VoucherDefaultsSettingsScreen> {
  /// [_store]: SharedPreferences load/save
  final VoucherDefaultsStore _store = const VoucherDefaultsStore();

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _description2Controller = TextEditingController();
  final _plateNoController = TextEditingController();
  final _specialCode1Controller = TextEditingController();

  /// [_loading]: Ayarlar yüklenirken true
  bool _loading = true;

  /// [_saving]: Kayıt sırasında true
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _description2Controller.dispose();
    _plateNoController.dispose();
    _specialCode1Controller.dispose();
    super.dispose();
  }

  /// {@template _loadDefaults}
  /// Yerel kayıtlı fiş ön değerlerini yükler.
  /// {@endtemplate}
  Future<void> _loadDefaults() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _descriptionController.text = record.description;
      _description2Controller.text = record.description2;
      _plateNoController.text = record.plateNo;
      _specialCode1Controller.text = record.specialCode1;
      _loading = false;
    });
  }

  /// {@template _saveDefaults}
  /// Form değerlerini SharedPreferences'a yazar ve ekranı kapatır.
  /// {@endtemplate}
  Future<void> _saveDefaults() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _store.save(
        VoucherDefaultsRecord(
          description: _descriptionController.text,
          description2: _description2Controller.text,
          plateNo: _plateNoController.text,
          specialCode1: _specialCode1Controller.text,
        ),
      );
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('common.success')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template _inputDecoration}
  /// Dense flat InputDecoration (voucher_defaults stil token'ları).
  ///
  /// Parametreler:
  /// - [label]: Alan etiketi
  ///
  /// Dönüş değeri:
  /// - [InputDecoration]: isDense, radius 8, grey.shade200
  /// {@endtemplate}
  InputDecoration _inputDecoration(String label) {
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
    final title = l10n.translate('submodules.fis_on_degerleri');
    final descriptionLabel = l10n.translate('field_sales.fis_description');
    final description2Label =
        l10n.translate('field_sales.fis_description_2');
    final plateLabel = l10n.translate('field_sales.fis_plate_no');
    final specialCodeLabel =
        l10n.translate('field_sales.fis_special_code_1');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(descriptionLabel),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _description2Controller,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(description2Label),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _plateNoController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(plateLabel),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _specialCode1Controller,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(specialCodeLabel),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveDefaults,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          l10n.translate('common.save').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF375A7F),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF375A7F),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.translate('common.close').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
