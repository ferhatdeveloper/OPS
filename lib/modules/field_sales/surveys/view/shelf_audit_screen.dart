// Dosya Adı: shelf_audit_screen.dart
// Açıklama: Raf denetimi dens form + SharedPreferences minimal persist
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/shelf_audit_record.dart';
import '../viewmodel/shelf_audit_store.dart';
import '../widgets/shelf_audit_mbt_fields.dart';

/// {@template shelf_audit_screen}
/// Raf / mağaza raf denetimi dens form ekranı.
///
/// Rota: `/field-sales/shelf-audit`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ShelfAuditScreen.routeName);
/// ```
/// {@endtemplate}
class ShelfAuditScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/shelf-audit`
  static const String routeName = '/field-sales/shelf-audit';

  /// {@macro shelf_audit_screen}
  const ShelfAuditScreen({Key? key}) : super(key: key);

  @override
  State<ShelfAuditScreen> createState() => _ShelfAuditScreenState();
}

class _ShelfAuditScreenState extends State<ShelfAuditScreen> {
  /// [_formKey]: Form doğrulama
  final _formKey = GlobalKey<FormState>();

  /// [_store]: SharedPreferences kalıcılık
  final ShelfAuditStore _store = const ShelfAuditStore();

  /// [_customerCodeController]: Cari kodu
  final TextEditingController _customerCodeController =
      TextEditingController();

  /// [_customerNameController]: Cari ünvan
  final TextEditingController _customerNameController =
      TextEditingController();

  /// [_categoryController]: Kategori
  final TextEditingController _categoryController = TextEditingController();

  /// [_brandController]: Marka
  final TextEditingController _brandController = TextEditingController();

  /// [_facingsController]: Facing
  final TextEditingController _facingsController = TextEditingController();

  /// [_shelfShareController]: Raf payı
  final TextEditingController _shelfShareController = TextEditingController();

  /// [_notesController]: Not
  final TextEditingController _notesController = TextEditingController();

  /// [_hasStock]: Rafta stok
  bool _hasStock = true;

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_saving]: Kayıt durumu
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template shelf_audit_screen_load}
  /// Yerel dens kaydı yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _customerCodeController.text = record.customerCode;
      _customerNameController.text = record.customerName;
      _categoryController.text = record.category;
      _brandController.text = record.brandName;
      _facingsController.text =
          record.facings > 0 ? '${record.facings}' : '';
      _shelfShareController.text = record.shelfSharePct > 0
          ? record.shelfSharePct.toString()
          : '';
      _notesController.text = record.notes;
      _hasStock = record.hasStock;
      _loading = false;
    });
  }

  /// {@template shelf_audit_screen_parse_int}
  /// Metin int? okur.
  /// {@endtemplate}
  int _parseInt(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 0;
    return int.tryParse(t) ?? 0;
  }

  /// {@template shelf_audit_screen_parse_double}
  /// Metin double okur.
  /// {@endtemplate}
  double _parseDouble(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    return double.tryParse(t) ?? 0;
  }

  /// {@template shelf_audit_screen_on_save}
  /// Formu doğrular ve SharedPreferences'a kaydeder.
  /// {@endtemplate}
  Future<void> _onSave(AppLocalization l10n) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final record = ShelfAuditRecord(
        customerCode: _customerCodeController.text.trim(),
        customerName: _customerNameController.text.trim(),
        category: _categoryController.text.trim(),
        brandName: _brandController.text.trim(),
        facings: _parseInt(_facingsController.text),
        shelfSharePct: _parseDouble(_shelfShareController.text),
        hasStock: _hasStock,
        notes: _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await _store.save(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.shelf_audit.saved'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template shelf_audit_screen_bottom_bar}
  /// Kaydet çubuğu (partial_delivery dens stil — UI no-touch).
  /// {@endtemplate}
  Widget _buildBottomBar(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF375A7F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _saving ? null : () => _onSave(l10n),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.translate('common.save'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerCodeController.dispose();
    _customerNameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _facingsController.dispose();
    _shelfShareController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.shelf_audit');

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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.translate(
                              'field_sales.shelf_audit.form_hint',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ShelfAuditMbtFields(
                            customerCodeController: _customerCodeController,
                            customerNameController: _customerNameController,
                            categoryController: _categoryController,
                            brandController: _brandController,
                            facingsController: _facingsController,
                            shelfShareController: _shelfShareController,
                            notesController: _notesController,
                            hasStock: _hasStock,
                            onHasStockChanged: (v) =>
                                setState(() => _hasStock = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(l10n),
              ],
            ),
    );
  }
}
