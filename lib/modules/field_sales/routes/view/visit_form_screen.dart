// Dosya Adı: visit_form_screen.dart
// Açıklama: MBT ziyaret formu (alan seti + ZIYARETI TAMAMLA)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../customers/model/customer_model.dart';
import '../model/visit_mbt_form_data.dart';
import '../model/visit_reason_master.dart';
import '../viewmodel/visit_provider.dart';
import '../widgets/visit_mbt_fields.dart';

/// {@template visit_form_screen}
/// Cari bağlamında MBT ziyaret formu (not / sonuç / tamamla).
///
/// Rota: [VisitFormScreen.routeName] — arguments: cariId (String)
/// {@endtemplate}
class VisitFormScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/visit-form`
  static const String routeName = '/field-sales/visit-form';

  /// [customerId]: Cari kimliği
  final String customerId;

  /// {@macro visit_form_screen}
  const VisitFormScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  ConsumerState<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends ConsumerState<VisitFormScreen> {
  /// [_formKey]: Form doğrulama
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  final _customerTypeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _contactController = TextEditingController();
  final _projectController = TextEditingController();
  final _referenceController = TextEditingController();
  final _attachmentsController = TextEditingController();
  final _notesController = TextEditingController();

  /// [_visitReason]: ZIYARET SEBEBI master kodu
  String? _visitReason;

  /// [_outcome]: Ziyaret sonucu
  String? _outcome;

  /// [_loadingCustomer]: Cari yükleniyor
  bool _loadingCustomer = true;

  /// [_saving]: Tamamlama devam ediyor
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  /// {@template _loadCustomer}
  /// Cari kartından KOD/ÜNVAN/ADRES… alanlarını doldurur.
  /// {@endtemplate}
  Future<void> _loadCustomer() async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final rows = await sqliteDb.query(
        'customers',
        where: 'id = ?',
        whereArgs: [widget.customerId],
        limit: 1,
      );
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() => _loadingCustomer = false);
        return;
      }
      final customer = CustomerModel.fromMap(rows.first);
      setState(() {
        _codeController.text =
            (customer.code?.trim().isNotEmpty == true)
                ? customer.code!.trim()
                : customer.id;
        _titleController.text = customer.name;
        _addressController.text = customer.address ?? '';
        _cityController.text = customer.il ?? '';
        _districtController.text = customer.ilce ?? '';
        _countryController.text = customer.ulke ?? '';
        _contactController.text = customer.yetkili ?? '';
        _loadingCustomer = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCustomer = false);
    }
  }

  /// {@template _outcomeOptions}
  /// Ziyaret sonucu seçenekleri (l10n).
  /// {@endtemplate}
  List<String> _outcomeOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.outcome_ordered'),
        l10n.translate('field_sales.outcome_not_ordered'),
        l10n.translate('field_sales.outcome_not_found'),
        l10n.translate('field_sales.outcome_postponed'),
        l10n.translate('field_sales.outcome_collected'),
        l10n.translate('field_sales.outcome_discovery'),
      ];

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _customerTypeController.dispose();
    _departmentController.dispose();
    _contactController.dispose();
    _projectController.dispose();
    _referenceController.dispose();
    _attachmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// {@template _onCancel}
  /// VAZGEÇ — formu kapatır.
  /// {@endtemplate}
  void _onCancel() {
    Navigator.of(context).maybePop();
  }

  /// {@template _onComplete}
  /// ZIYARETI TAMAMLA — doğrula + provider kaydı.
  /// {@endtemplate}
  Future<void> _onComplete(AppLocalization l10n) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final form = VisitMbtFormData(
        code: _codeController.text,
        title: _titleController.text,
        address: _addressController.text,
        city: _cityController.text,
        district: _districtController.text,
        country: _countryController.text,
        visitReason: _visitReason ?? '',
        customerType: _customerTypeController.text,
        department: _departmentController.text,
        contactPerson: _contactController.text,
        projectCode: _projectController.text,
        referencePerson: _referenceController.text,
        attachments: _attachmentsController.text,
        notes: _notesController.text,
        outcome: _outcome ?? '',
      );

      final ok = await ref.read(visitProvider.notifier).completeMbtVisit(
            customerId: widget.customerId,
            form: form,
          );
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('field_sales.visit_completed')),
          ),
        );
        Navigator.of(context).maybePop(true);
      } else {
        final err = ref.read(visitProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err != null && err.startsWith('field_sales.')
                  ? l10n.translate(err)
                  : l10n.translate('field_sales.visit_finish_error'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final reasons = VisitReasonMaster.labeled(l10n);
    final outcomes = _outcomeOptions(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.visit_record'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: _loadingCustomer
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VisitMbtFields(
                      codeController: _codeController,
                      titleController: _titleController,
                      addressController: _addressController,
                      cityController: _cityController,
                      districtController: _districtController,
                      countryController: _countryController,
                      customerTypeController: _customerTypeController,
                      departmentController: _departmentController,
                      contactController: _contactController,
                      projectController: _projectController,
                      referenceController: _referenceController,
                      attachmentsController: _attachmentsController,
                      notesController: _notesController,
                      visitReason: _visitReason,
                      onVisitReasonChanged: (val) {
                        setState(() => _visitReason = val);
                      },
                      outcome: _outcome,
                      onOutcomeChanged: (val) {
                        setState(() => _outcome = val);
                      },
                      reasonOptions: reasons,
                      outcomeOptions: outcomes,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving ? null : () => _onComplete(l10n),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF375A7F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.translate('field_sales.complete_visit'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _saving ? null : _onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: const Color(0xFF375A7F),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.translate('field_sales.visit_mbt_cancel'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
