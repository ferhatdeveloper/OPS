// Dosya Adı: product_detail_screen.dart
// Açıklama: Ürün dens form — Create / Update / Delete (SQLite + sync_queue)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../ai_social/view/social_media_image_screen.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/product_catalog_row.dart';
import '../viewmodel/product_catalog_store.dart';

/// {@template product_detail_screen}
/// Ürün oluştur / düzenle dens formu.
/// Route: `/field-sales/product-detail`
///
/// Arguments: [ProductCatalogRow] veya `{id,code,name,...}` map / null (yeni).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ProductDetailScreen.routeName);
/// ```
/// {@endtemplate}
class ProductDetailScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/product-detail`
  static const String routeName = '/field-sales/product-detail';

  /// [initial]: Mevcut ürün (null → yeni)
  final ProductCatalogRow? initial;

  /// [store]: Test / enjekte store
  final ProductCatalogStore? store;

  const ProductDetailScreen({
    Key? key,
    this.initial,
    this.store,
  }) : super(key: key);

  /// Named route arguments → satır.
  static ProductCatalogRow? rowFromArgs(Object? args) {
    if (args is ProductCatalogRow) return args;
    if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      final id = (map['id'] ?? '').toString();
      final code = (map['code'] ?? '').toString();
      final name = (map['name'] ?? '').toString();
      if (id.isEmpty && code.isEmpty && name.isEmpty) return null;
      return ProductCatalogRow.fromMap(map);
    }
    return null;
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _vatCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _categoryCtrl;
  bool _saving = false;
  bool _loading = false;
  ProductCatalogRow? _loaded;

  ProductCatalogStore get _store =>
      widget.store ?? const ProductCatalogStore();

  bool get _isEditing =>
      (_loaded ?? widget.initial)?.id.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    final seed = widget.initial;
    _codeCtrl = TextEditingController(text: seed?.code ?? '');
    _nameCtrl = TextEditingController(text: seed?.name ?? '');
    _barcodeCtrl = TextEditingController(text: seed?.barcode ?? '');
    _unitCtrl = TextEditingController(text: seed?.unit ?? 'ADET');
    _priceCtrl = TextEditingController(
      text: seed != null ? seed.price.toString() : '0',
    );
    _vatCtrl = TextEditingController(
      text: seed != null ? seed.vatRate.toString() : '20',
    );
    _stockCtrl = TextEditingController(
      text: seed != null ? seed.stockQuantity.toString() : '0',
    );
    _categoryCtrl = TextEditingController(text: seed?.category ?? '');
    _loaded = seed;
    if (seed != null &&
        seed.id.trim().isNotEmpty &&
        seed.name.trim().isEmpty) {
      _hydrateFromStore(seed.id);
    }
  }

  Future<void> _hydrateFromStore(String id) async {
    setState(() => _loading = true);
    try {
      final row = await _store.getById(id);
      if (!mounted || row == null) return;
      setState(() {
        _loaded = row;
        _codeCtrl.text = row.code;
        _nameCtrl.text = row.name;
        _barcodeCtrl.text = row.barcode;
        _unitCtrl.text = row.unit;
        _priceCtrl.text = row.price.toString();
        _vatCtrl.text = row.vatRate.toString();
        _stockCtrl.text = row.stockQuantity.toString();
        _categoryCtrl.text = row.category;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _vatCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  /// Form alanlarından sosyal medya ekranı için satır.
  ProductCatalogRow _rowFromForm() {
    final existing = _loaded ?? widget.initial;
    return ProductCatalogRow(
      id: existing?.id ?? '',
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      unit: _unitCtrl.text.trim().isEmpty ? 'ADET' : _unitCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      vatRate: int.tryParse(_vatCtrl.text.trim()) ?? 20,
      stockQuantity:
          double.tryParse(_stockCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      category: _categoryCtrl.text.trim(),
    );
  }

  /// Sosyal medya görseli dens ekranına git.
  void _openSocialMedia() {
    final row = _rowFromForm();
    if (row.name.trim().isEmpty) return;
    Navigator.pushNamed(
      context,
      SocialMediaImageScreen.routeName,
      arguments: row,
    );
  }

  /// {@template product_detail_save}
  /// Validasyon → upsert → dens SnackBar.
  /// {@endtemplate}
  Future<void> _save(AppLocalization l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = _loaded ?? widget.initial;
      final row = ProductCatalogRow(
        id: existing?.id.trim().isNotEmpty == true
            ? existing!.id
            : const Uuid().v4(),
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? 'ADET' : _unitCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ??
            0,
        vatRate: int.tryParse(_vatCtrl.text.trim()) ?? 20,
        stockQuantity:
            double.tryParse(_stockCtrl.text.trim().replaceAll(',', '.')) ??
                0,
        category: _categoryCtrl.text.trim(),
      );
      final saved = await _store.upsert(row);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.product_saved')),
        ),
      );
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.product_save_failed')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template product_detail_delete}
  /// Onay → sil → pop.
  /// {@endtemplate}
  Future<void> _delete(AppLocalization l10n) async {
    final existing = _loaded ?? widget.initial;
    final id = existing?.id.trim() ?? '';
    if (id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('field_sales.product_delete')),
        content: Text(l10n.translate('field_sales.product_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('common.delete')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    final ok = await _store.deleteById(id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.product_deleted')),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.product_save_failed')),
        ),
      );
    }
  }

  InputDecoration _denseDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = _isEditing
        ? l10n.translate('field_sales.product_edit_title')
        : l10n.translate('field_sales.product_new_title');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
        useGradient: true,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.campaign_outlined,
            onPressed: _saving || _loading ? null : _openSocialMedia,
            tooltip: l10n.translate('field_sales.ai_social.title'),
          ),
          if (_isEditing)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.delete_outline,
              onPressed: _saving ? null : () => _delete(l10n),
              tooltip: l10n.translate('field_sales.product_delete'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                children: [
                  TextFormField(
                    controller: _codeCtrl,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    decoration: _denseDeco(
                      l10n.translate('field_sales.product_code_label'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.translate(
                            'field_sales.product_code_required',
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    decoration: _denseDeco(
                      l10n.translate('field_sales.product_name_label'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.translate(
                            'field_sales.product_name_required',
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _barcodeCtrl,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    decoration: _denseDeco(
                      l10n.translate('field_sales.product_barcode_label'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitCtrl,
                          style: const TextStyle(fontSize: 13),
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          decoration: _denseDeco(
                            l10n.translate('field_sales.product_unit_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          style: const TextStyle(fontSize: 13),
                          textInputAction: TextInputAction.next,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: _denseDeco(
                            l10n.translate(
                              'field_sales.product_price_label',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _vatCtrl,
                          style: const TextStyle(fontSize: 13),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _denseDeco(
                            l10n.translate('field_sales.product_vat_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          style: const TextStyle(fontSize: 13),
                          textInputAction: TextInputAction.next,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: _denseDeco(
                            l10n.translate(
                              'field_sales.product_stock_label',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _categoryCtrl,
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.text,
                    decoration: _denseDeco(
                      l10n.translate('field_sales.product_category_label'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _openSocialMedia,
                      icon: const Icon(Icons.campaign_outlined, size: 18),
                      label: Text(
                        l10n.translate('field_sales.ai_social.action'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF375A7F),
                        side: const BorderSide(color: Color(0xFF375A7F)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _save(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF375A7F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.translate('common.save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
