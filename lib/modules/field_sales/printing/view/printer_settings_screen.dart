// Dosya Adı: printer_settings_screen.dart
// Açıklama: Yazıcı ayarları dens ekranı (prefs kalıcılık)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/printer_settings_record.dart';
import '../viewmodel/printer_settings_store.dart';

/// {@template printer_settings_screen}
/// Yazıcı ayarları dens ekranı — SharedPreferences kalıcılık.
/// Route: `/field-sales/printer-settings`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, PrinterSettingsScreen.routeName);
/// ```
/// {@endtemplate}
class PrinterSettingsScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/printer-settings`
  static const String routeName = '/field-sales/printer-settings';

  /// {@macro printer_settings_screen}
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  /// [_store]: SharedPreferences load/save
  final PrinterSettingsStore _store = const PrinterSettingsStore();

  final _formKey = GlobalKey<FormState>();
  final _defaultNameController = TextEditingController();
  final _defaultAddressController = TextEditingController();
  final _labelNameController = TextEditingController();
  final _labelAddressController = TextEditingController();
  final _footerController = TextEditingController();
  final _feedbackController = TextEditingController();

  /// [_showPreview]: Ön izleme anahtarı
  bool _showPreview = true;

  /// [_autoPrint]: Otomatik yazdır
  bool _autoPrint = false;

  /// [_paperWidth]: 58 veya 80
  int _paperWidth = 58;

  /// [_slipTemplate]: standard / minimal
  String _slipTemplate = 'standard';

  /// [_labelTemplate]: product_small / shelf_large
  String _labelTemplate = 'product_small';

  /// [_loading]: Yükleme
  bool _loading = true;

  /// [_saving]: Kayıt
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _defaultNameController.dispose();
    _defaultAddressController.dispose();
    _labelNameController.dispose();
    _labelAddressController.dispose();
    _footerController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  /// {@template _loadSettings}
  /// Yerel yazıcı ayarlarını yükler.
  /// {@endtemplate}
  Future<void> _loadSettings() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _defaultNameController.text = record.defaultPrinterName;
      _defaultAddressController.text = record.defaultPrinterAddress;
      _labelNameController.text = record.labelPrinterName;
      _labelAddressController.text = record.labelPrinterAddress;
      _footerController.text = record.footerMessage;
      _feedbackController.text = record.feedbackUrl;
      _showPreview = record.showPreview;
      _autoPrint = record.autoPrint;
      _paperWidth = record.paperWidth;
      _slipTemplate = record.defaultSlipTemplate;
      _labelTemplate = record.defaultLabelTemplate;
      _loading = false;
    });
  }

  /// {@template _saveSettings}
  /// Form değerlerini SharedPreferences'a yazar.
  /// {@endtemplate}
  Future<void> _saveSettings() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _store.save(
        PrinterSettingsRecord(
          defaultPrinterName: _defaultNameController.text,
          defaultPrinterAddress: _defaultAddressController.text,
          labelPrinterName: _labelNameController.text,
          labelPrinterAddress: _labelAddressController.text,
          showPreview: _showPreview,
          paperWidth: _paperWidth,
          autoPrint: _autoPrint,
          footerMessage: _footerController.text,
          feedbackUrl: _feedbackController.text,
          defaultSlipTemplate: _slipTemplate,
          defaultLabelTemplate: _labelTemplate,
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
    final title = l10n.translate('field_sales.stubs.printer_settings');

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
                      controller: _defaultNameController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.translate(
                          'field_sales.printer.default_printer_name',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _defaultAddressController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.translate(
                          'field_sales.printer.default_printer_address',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _labelNameController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.translate(
                          'field_sales.printer.label_printer_name',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _labelAddressController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.translate(
                          'field_sales.printer.label_printer_address',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _paperWidth,
                      decoration: _inputDecoration(
                        l10n.translate('field_sales.printer.paper_width'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 58,
                          child: Text(
                            l10n.translate(
                              'field_sales.printer.paper_width_58',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 80,
                          child: Text(
                            l10n.translate(
                              'field_sales.printer.paper_width_80',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _paperWidth = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _slipTemplate,
                      decoration: _inputDecoration(
                        l10n.translate('field_sales.printer.slip_template'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'standard',
                          child: Text(
                            l10n.translate(
                              'field_sales.printer.template_standard',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'minimal',
                          child: Text(
                            l10n.translate(
                              'field_sales.printer.template_minimal',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _slipTemplate = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _labelTemplate,
                      decoration: _inputDecoration(
                        l10n.translate('field_sales.printer.label_template'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'product_small',
                          child: Text(
                            l10n.translate(
                              'field_sales.printer.template_product_small',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'shelf_large',
                          child: Text(
                            l10n.translate(
                              'field_sales.printer.template_shelf_large',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _labelTemplate = v);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate('field_sales.printer.show_preview'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        l10n.translate(
                          'field_sales.printer.show_preview_subtitle',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _showPreview,
                      activeColor: const Color(0xFF00A8E8),
                      onChanged: (v) => setState(() => _showPreview = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate('field_sales.printer.auto_print'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        l10n.translate(
                          'field_sales.printer.auto_print_subtitle',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _autoPrint,
                      activeColor: const Color(0xFF00A8E8),
                      onChanged: (v) => setState(() => _autoPrint = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _footerController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.translate('field_sales.printer.footer_message'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _feedbackController,
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        l10n.translate('field_sales.printer.feedback_url'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveSettings,
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
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
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
