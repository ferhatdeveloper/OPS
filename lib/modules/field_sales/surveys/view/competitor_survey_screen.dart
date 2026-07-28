// Dosya Adı: competitor_survey_screen.dart
// Açıklama: Rakip anket dens form + SharedPreferences minimal persist
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/competitor_survey_record.dart';
import '../viewmodel/competitor_survey_store.dart';
import '../widgets/competitor_survey_mbt_fields.dart';

/// {@template competitor_survey_screen}
/// Rakip anketi dens form ekranı (OPS surveys parity).
/// Route: `/field-sales/competitor-survey`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CompetitorSurveyScreen.routeName);
/// ```
/// {@endtemplate}
class CompetitorSurveyScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/competitor-survey`
  static const String routeName = '/field-sales/competitor-survey';

  /// {@macro competitor_survey_screen}
  const CompetitorSurveyScreen({Key? key}) : super(key: key);

  @override
  State<CompetitorSurveyScreen> createState() =>
      _CompetitorSurveyScreenState();
}

class _CompetitorSurveyScreenState extends State<CompetitorSurveyScreen> {
  /// [_formKey]: Form doğrulama
  final _formKey = GlobalKey<FormState>();

  /// [_store]: SharedPreferences kalıcılık
  final CompetitorSurveyStore _store = const CompetitorSurveyStore();

  /// [_customerCodeController]: Cari kodu
  final TextEditingController _customerCodeController =
      TextEditingController();

  /// [_brandController]: Rakip marka
  final TextEditingController _brandController = TextEditingController();

  /// [_productController]: Rakip ürün
  final TextEditingController _productController = TextEditingController();

  /// [_priceController]: Gözlemlenen fiyat
  final TextEditingController _priceController = TextEditingController();

  /// [_notesController]: Not
  final TextEditingController _notesController = TextEditingController();

  /// [_hasStock]: Stokta var
  bool _hasStock = true;

  /// [_onPromotion]: Kampanyada
  bool _onPromotion = false;

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_saving]: Kayıt durumu
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template competitor_survey_screen_load}
  /// Yerel dens kaydı yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _customerCodeController.text = record.customerCode;
      _brandController.text = record.brandName;
      _productController.text = record.productName;
      _priceController.text = record.observedPrice == null
          ? ''
          : record.observedPrice.toString();
      _notesController.text = record.notes;
      _hasStock = record.hasStock;
      _onPromotion = record.onPromotion;
      _loading = false;
    });
  }

  /// {@template competitor_survey_screen_parse_price}
  /// Fiyat metnini double? okur.
  /// {@endtemplate}
  double? _parsePrice(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// {@template competitor_survey_screen_on_save}
  /// Formu doğrular ve SharedPreferences'a kaydeder.
  /// {@endtemplate}
  Future<void> _onSave(AppLocalization l10n) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final record = CompetitorSurveyRecord(
        customerCode: _customerCodeController.text.trim(),
        brandName: _brandController.text.trim(),
        productName: _productController.text.trim(),
        observedPrice: _parsePrice(_priceController.text),
        hasStock: _hasStock,
        onPromotion: _onPromotion,
        notes: _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await _store.save(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.competitor_survey.saved'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template competitor_survey_screen_bottom_bar}
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
    _brandController.dispose();
    _productController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.competitor_survey');

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
                              'field_sales.competitor_survey.form_hint',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CompetitorSurveyMbtFields(
                            customerCodeController: _customerCodeController,
                            brandController: _brandController,
                            productController: _productController,
                            priceController: _priceController,
                            notesController: _notesController,
                            hasStock: _hasStock,
                            onPromotion: _onPromotion,
                            onHasStockChanged: (v) =>
                                setState(() => _hasStock = v),
                            onPromotionChanged: (v) =>
                                setState(() => _onPromotion = v),
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
