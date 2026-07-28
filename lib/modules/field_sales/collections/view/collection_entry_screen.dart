// Dosya Adı: collection_entry_screen.dart
// Açıklama: Tahsilat girişi — cari guard + nakit MBT dens alan seti
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../shared/view/unsaved_voucher_scope.dart';
import '../../currency/engine/collection_currency_exchange.dart';
import '../../currency/viewmodel/currency_rate_store.dart';
import '../../currency/viewmodel/default_currency_resolver.dart';
import '../model/finance_movement_type.dart';
import '../model/session_salesperson_code.dart';
import '../viewmodel/collection_provider.dart';
import '../widgets/cash_card_code_field.dart';
import '../widgets/check_collection_mbt_fields.dart';
import '../widgets/collection_cash_mbt_fields.dart';
import 'collection_customer_selection_screen.dart';

/// {@template collection_entry_screen}
/// Tahsilat girişi ekranı.
///
/// Kullanım örneği:
/// ```dart
/// CollectionEntryScreen(customerId: 'C001');
/// CollectionEntryScreen(
///   customerId: 'C001',
///   initialPaymentType: 'check',
/// );
/// ```
/// {@endtemplate}
class CollectionEntryScreen extends ConsumerStatefulWidget {
  /// [customerId]: Seçili cari kimliği
  final String customerId;

  /// [initialPaymentType]: cash | credit_card | check | note
  /// (legacy: Cash | CreditCard | Check | Note)
  final String? initialPaymentType;

  /// [initialSalespersonCode]: Plasiyer ön-doldurma (test / enjeksiyon).
  /// Null ise oturum kullanıcı kodundan okunur.
  final String? initialSalespersonCode;

  /// {@macro collection_entry_screen}
  const CollectionEntryScreen({
    Key? key,
    required this.customerId,
    this.initialPaymentType,
    this.initialSalespersonCode,
  }) : super(key: key);

  @override
  ConsumerState<CollectionEntryScreen> createState() =>
      _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends ConsumerState<CollectionEntryScreen> {
  /// [_amountController]: Tutar alanı
  final _amountController = TextEditingController();

  /// [_notesController]: Not / açıklama alanı (çek-senet)
  final _notesController = TextEditingController();

  /// [_bankController]: Çek banka adı
  final _bankController = TextEditingController();

  /// [_branchController]: Çek şube adı
  final _branchController = TextEditingController();

  /// [_checkNoController]: Çek numarası
  final _checkNoController = TextEditingController();

  /// [_currencyController]: Nakit — işlem dövizi
  final _currencyController = TextEditingController();

  /// [_exchangeRateController]: Nakit — kur (seçilen → merkez)
  final _exchangeRateController = TextEditingController(text: '1');

  /// [_defaultCurrencyCode]: Merkez / firma varsayılan para birimi
  String _defaultCurrencyCode =
      CollectionCurrencyExchange.fallbackDefaultCode;

  /// [_rateMap]: Döviz kuru ekranından kod→kur
  Map<String, String> _rateMap = const {};

  /// [_documentNoController]: Nakit — evrak no
  final _documentNoController = TextEditingController();

  /// [_cashCodeController]: Nakit — kasa kodu
  final _cashCodeController = TextEditingController();

  /// [_descriptionController]: Nakit — açıklama
  final _descriptionController = TextEditingController();

  /// [_salespersonController]: Nakit — plasiyer
  final _salespersonController = TextEditingController();

  /// [_specialCodeController]: Nakit — özelkod 1
  final _specialCodeController = TextEditingController();

  /// [_endorsementController]: Çek — ciro
  final _endorsementController = TextEditingController();

  /// [_originalDebtorController]: Çek — asıl borçlu
  final _originalDebtorController = TextEditingController();

  /// [_workplaceController]: Çek — işyeri
  final _workplaceController = TextEditingController();

  /// [_accountNoController]: Çek — hesap no
  final _accountNoController = TextEditingController();

  /// [_dueDate]: Çek vade tarihi
  DateTime? _dueDate;

  /// [_selectedPaymentType]: API ödeme tipi (cash / credit_card / …)
  late String _selectedPaymentType;

  /// [_missingCustomer]: Cari eksik — yönlendirme
  bool _missingCustomer = false;

  /// [_isCash]: Nakit tahsilat seçili mi
  bool get _isCash {
    final t = FinanceMovementType.fromStorage(_selectedPaymentType);
    return t == FinanceMovementType.cashCollection;
  }

  /// [_isCreditCard]: KK tahsilat dens alanları
  bool get _isCreditCard {
    return FinanceMovementType.fromStorage(_selectedPaymentType).isCreditCard;
  }

  /// [_hasUnsavedDraft]: Kullanıcı formu doldurduysa taslak uyarısı
  bool get _hasUnsavedDraft {
    return _amountController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _bankController.text.trim().isNotEmpty ||
        _branchController.text.trim().isNotEmpty ||
        _checkNoController.text.trim().isNotEmpty ||
        _documentNoController.text.trim().isNotEmpty ||
        _cashCodeController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _specialCodeController.text.trim().isNotEmpty ||
        _endorsementController.text.trim().isNotEmpty ||
        _originalDebtorController.text.trim().isNotEmpty ||
        _workplaceController.text.trim().isNotEmpty ||
        _accountNoController.text.trim().isNotEmpty ||
        _dueDate != null;
  }

  @override
  void initState() {
    super.initState();
    final parsed = FinanceMovementType.fromStorage(widget.initialPaymentType);
    _selectedPaymentType = parsed.kind == FinanceMovementKind.collection
        ? parsed.apiCode
        : FinanceMovementType.cashCollection.apiCode;
    _amountController.addListener(_onDraftFieldChanged);
    _notesController.addListener(_onDraftFieldChanged);
    _bankController.addListener(_onDraftFieldChanged);
    _branchController.addListener(_onDraftFieldChanged);
    _checkNoController.addListener(_onDraftFieldChanged);
    _documentNoController.addListener(_onDraftFieldChanged);
    _cashCodeController.addListener(_onDraftFieldChanged);
    _descriptionController.addListener(_onDraftFieldChanged);
    _specialCodeController.addListener(_onDraftFieldChanged);
    _endorsementController.addListener(_onDraftFieldChanged);
    _originalDebtorController.addListener(_onDraftFieldChanged);
    _workplaceController.addListener(_onDraftFieldChanged);
    _accountNoController.addListener(_onDraftFieldChanged);
    _amountController.addListener(_onCurrencyUiChanged);
    _exchangeRateController.addListener(_onCurrencyUiChanged);
    Future.microtask(() async {
      await _prefillDefaultCurrency();
      await _prefillSalespersonFromSession();
      if (!CollectionNotifier.isValidCustomerId(widget.customerId)) {
        if (!mounted) return;
        setState(() => _missingCustomer = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                'field_sales.collection_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CollectionCustomerSelectionScreen(
              purpose: CollectionSelectionPurpose.collection,
              initialPaymentType: _selectedPaymentType,
            ),
          ),
        );
      }
    });
  }

  /// {@template _onDraftFieldChanged}
  /// Form değişince UnsavedVoucherScope yeniden kurulur.
  /// {@endtemplate}
  void _onDraftFieldChanged() {
    if (mounted) setState(() {});
  }

  /// {@template _onCurrencyUiChanged}
  /// Kur / tutar değişince dens döviz özeti yenilenir.
  /// {@endtemplate}
  void _onCurrencyUiChanged() {
    if (mounted) setState(() {});
  }

  /// {@template _prefillDefaultCurrency}
  /// Merkez varsayılan dövizi + kur map ön-doldurur.
  /// {@endtemplate}
  Future<void> _prefillDefaultCurrency() async {
    try {
      final code = await const DefaultCurrencyResolver().resolve();
      final rates = await const CurrencyRateStore().load();
      if (!mounted) return;
      setState(() {
        _defaultCurrencyCode = code;
        _rateMap = rates.rates;
        if (_currencyController.text.trim().isEmpty) {
          _currencyController.text = code;
        }
        _applyRateForCurrency(_currencyController.text);
      });
    } catch (_) {
      if (!mounted) return;
      if (_currencyController.text.trim().isEmpty) {
        _currencyController.text =
            CollectionCurrencyExchange.fallbackDefaultCode;
      }
    }
  }

  /// {@template _applyRateForCurrency}
  /// Seçilen döviz için kur alanını doldurur.
  /// {@endtemplate}
  void _applyRateForCurrency(String code) {
    final rate = CollectionCurrencyExchange.resolveRate(
      currencyCode: code,
      defaultCurrency: _defaultCurrencyCode,
      rates: _rateMap,
    );
    _exchangeRateController.text = rate > 0
        ? CollectionCurrencyExchange.formatRate(rate)
        : (CollectionCurrencyExchange.isDefaultCurrency(
                code, _defaultCurrencyCode)
            ? '1'
            : '');
  }

  /// {@template _discardCollectionDraft}
  /// Kaydedilmemiş tahsilat formunu temizler (MBT Sil).
  /// {@endtemplate}
  void _discardCollectionDraft() {
    _amountController.clear();
    _notesController.clear();
    _bankController.clear();
    _branchController.clear();
    _checkNoController.clear();
    _documentNoController.clear();
    _cashCodeController.clear();
    _descriptionController.clear();
    _specialCodeController.clear();
    _endorsementController.clear();
    _originalDebtorController.clear();
    _workplaceController.clear();
    _accountNoController.clear();
    _dueDate = null;
    _currencyController.text = _defaultCurrencyCode;
    _exchangeRateController.text = '1';
  }

  /// {@template _prefillSalespersonFromSession}
  /// Nakit PLASIYER alanını oturum / kullanıcı kodundan ön-doldurur.
  /// Dolu controller ezilmez; yalnızca boşsa yazılır.
  /// {@endtemplate}
  Future<void> _prefillSalespersonFromSession() async {
    if (_salespersonController.text.trim().isNotEmpty) return;

    final injected = widget.initialSalespersonCode?.trim();
    if (injected != null && injected.isNotEmpty) {
      _salespersonController.text = injected;
      return;
    }

    try {
      final db = await DatabaseService.getInstance();
      final session = await db.getUserSession();
      final code = resolveSalespersonCodeFromSession(session);
      if (!mounted) return;
      if (code != null &&
          code.isNotEmpty &&
          _salespersonController.text.trim().isEmpty) {
        _salespersonController.text = code;
      }
    } catch (_) {
      // Oturum yoksa dens alan boş kalır; kayıtta opsiyonel
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onDraftFieldChanged);
    _notesController.removeListener(_onDraftFieldChanged);
    _bankController.removeListener(_onDraftFieldChanged);
    _branchController.removeListener(_onDraftFieldChanged);
    _checkNoController.removeListener(_onDraftFieldChanged);
    _documentNoController.removeListener(_onDraftFieldChanged);
    _cashCodeController.removeListener(_onDraftFieldChanged);
    _descriptionController.removeListener(_onDraftFieldChanged);
    _specialCodeController.removeListener(_onDraftFieldChanged);
    _endorsementController.removeListener(_onDraftFieldChanged);
    _originalDebtorController.removeListener(_onDraftFieldChanged);
    _workplaceController.removeListener(_onDraftFieldChanged);
    _accountNoController.removeListener(_onDraftFieldChanged);
    _amountController.removeListener(_onCurrencyUiChanged);
    _exchangeRateController.removeListener(_onCurrencyUiChanged);
    _amountController.dispose();
    _notesController.dispose();
    _bankController.dispose();
    _branchController.dispose();
    _checkNoController.dispose();
    _currencyController.dispose();
    _exchangeRateController.dispose();
    _documentNoController.dispose();
    _cashCodeController.dispose();
    _descriptionController.dispose();
    _salespersonController.dispose();
    _specialCodeController.dispose();
    _endorsementController.dispose();
    _originalDebtorController.dispose();
    _workplaceController.dispose();
    _accountNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collectionProvider);
    final l10n = AppLocalization.of(context);
    if (_missingCustomer) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return UnsavedVoucherScope(
      hasUnsaved: _hasUnsavedDraft,
      onDiscard: _discardCollectionDraft,
      child: Scaffold(
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
          l10n.translate('field_sales.collection_entry_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildAmountCard(l10n),
            const SizedBox(height: 12),
            _buildPaymentTypeCard(l10n),
            if (_isCash) ...[
              const SizedBox(height: 12),
              _buildCashMbtCard(),
            ],
            if (!_isCash) ...[
              const SizedBox(height: 12),
              _buildNotesCard(l10n),
            ],
            if (_isCreditCard) ...[
              const SizedBox(height: 12),
              _buildCreditCardDetailsCard(l10n),
            ],
            if (_selectedPaymentType ==
                    FinanceMovementType.checkCollection.apiCode ||
                _selectedPaymentType == 'Check') ...[
              const SizedBox(height: 12),
              _buildCheckDetailsCard(l10n),
            ],
            if (_selectedPaymentType ==
                    FinanceMovementType.noteCollection.apiCode ||
                _selectedPaymentType == 'Note') ...[
              const SizedBox(height: 12),
              _buildNoteDetailsCard(l10n),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: state.isLoading ? null : _handleSave,
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        l10n.translate('field_sales.collection_confirm'),
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

  /// {@template _buildCashMbtCard}
  /// Nakit MBT dens alan kartı.
  /// {@endtemplate}
  Widget _buildCashMbtCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CollectionCashMbtFields(
        currencyController: _currencyController,
        exchangeRateController: _exchangeRateController,
        defaultCurrencyCode: _defaultCurrencyCode,
        documentNoController: _documentNoController,
        cashCodeController: _cashCodeController,
        descriptionController: _descriptionController,
        amountController: _amountController,
        salespersonController: _salespersonController,
        specialCodeController: _specialCodeController,
        showAmountField: true,
        onCurrencyChanged: (code) {
          setState(() => _applyRateForCurrency(code));
        },
      ),
    );
  }

  Widget _buildAmountCard(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.translate('field_sales.amount_to_collect'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0.00',
              suffixText: '',
              suffixStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A8E8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeCard(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('field_sales.payment_type_label'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          _buildPaymentTypeSelector(l10n),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector(AppLocalization l10n) {
    // Senet (payment_note) MBT §6.5 — 4. tip; layout aynı Expanded satır
    final types = [
      {
        'val': FinanceMovementType.cashCollection.apiCode,
        'label': l10n.translate('field_sales.payment_cash'),
        'icon': Icons.money,
      },
      {
        'val': FinanceMovementType.creditCardCollection.apiCode,
        'label': l10n.translate('field_sales.payment_credit_short'),
        'icon': Icons.credit_card,
      },
      {
        'val': FinanceMovementType.checkCollection.apiCode,
        'label': l10n.translate('field_sales.payment_check'),
        'icon': Icons.description,
      },
      {
        'val': FinanceMovementType.noteCollection.apiCode,
        'label': l10n.translate('field_sales.payment_note'),
        'icon': Icons.note_alt,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: types.map((t) {
        final isSelected = _selectedPaymentType == t['val'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () =>
                  setState(() => _selectedPaymentType = t['val'] as String),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00A8E8)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00A8E8)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesCard(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('field_sales.notes_optional'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.all(10),
              hintText: l10n.translate('field_sales.collection_notes_hint'),
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  /// {@template _buildCreditCardDetailsCard}
  /// Kredi kartı dens alanları — EVRAK NO + POS/Kasa (nakit dens parity).
  /// {@endtemplate}
  Widget _buildCreditCardDetailsCard(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('field_sales.cc_details'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _documentNoController,
            l10n.translate('field_sales.cc_document_no'),
            Icons.receipt_long,
          ),
          const SizedBox(height: 8),
          CashCardCodeField(
            controller: _cashCodeController,
            label: l10n.translate('field_sales.cc_pos_code'),
            prefixIcon: Icons.point_of_sale,
            prefixIconColor: const Color(0xFF375A7F),
            fillColor: const Color(0xFFF8F9FD),
            labelAsHint: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckDetailsCard(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('field_sales.check_details'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          CheckCollectionMbtFields(
            documentNoController: _documentNoController,
            endorsementController: _endorsementController,
            originalDebtorController: _originalDebtorController,
            bankController: _bankController,
            branchController: _branchController,
            workplaceController: _workplaceController,
            checkNoController: _checkNoController,
            accountNoController: _accountNoController,
            dueDate: _dueDate,
            onDueDateTap: _selectDueDate,
          ),
        ],
      ),
    );
  }

  /// {@template _buildNoteDetailsCard}
  /// Senet (Note) için çek formuna benzer minimal alanlar.
  /// {@endtemplate}
  Widget _buildNoteDetailsCard(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('field_sales.note_details'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _checkNoController,
            l10n.translate('field_sales.note_number'),
            Icons.confirmation_number,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            _bankController,
            l10n.translate('field_sales.note_bank_name'),
            Icons.account_balance,
          ),
          const SizedBox(height: 8),
          _buildDueDateField(
            l10n,
            emptyLabel: l10n.translate('field_sales.note_due_date'),
          ),
        ],
      ),
    );
  }

  /// {@template _buildDueDateField}
  /// Vade tarihi seçici (çek / senet ortak).
  /// {@endtemplate}
  Widget _buildDueDateField(
    AppLocalization l10n, {
    required String emptyLabel,
  }) {
    return InkWell(
      onTap: _selectDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF00A8E8),
            ),
            const SizedBox(width: 10),
            Text(
              _dueDate == null
                  ? emptyLabel
                  : l10n.translate(
                      'field_sales.due_date_prefix',
                      args: {
                        'date':
                            '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}',
                      },
                    ),
              style: TextStyle(
                color: _dueDate == null ? Colors.grey.shade600 : Colors.black,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF375A7F)),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _handleSave() async {
    final l10n = AppLocalization.of(context);
    final amount = CollectionCurrencyExchange.parseRate(
          _amountController.text,
        ) ??
        0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('target.enter_amount_error')),
        ),
      );
      return;
    }

    final type = FinanceMovementType.fromStorage(_selectedPaymentType);
    final isCheck = type.isCheck;
    final isNote = type.isNote;
    final isCard = type.isCreditCard;
    final notes = _isCash
        ? _descriptionController.text.trim()
        : _notesController.text;

    final exchangeRate = _isCash
        ? CollectionCurrencyExchange.parseRate(
            _exchangeRateController.text,
          )
        : null;
    final baseAmount = (_isCash &&
            exchangeRate != null &&
            exchangeRate > 0)
        ? CollectionCurrencyExchange.toBaseAmount(
            amountInCurrency: amount,
            exchangeRate: exchangeRate,
          )
        : null;

    final success = await ref.read(collectionProvider.notifier).saveCollection(
          customerId: widget.customerId,
          amount: amount,
          paymentType: FinanceMovementType.normalizeApiCode(
            _selectedPaymentType,
          ),
          notes: notes,
          bankName: (isCheck || isNote) ? _bankController.text : null,
          branchName: isCheck ? _branchController.text : null,
          checkNumber: (isCheck || isNote) ? _checkNoController.text : null,
          dueDate: (isCheck || isNote) ? _dueDate : null,
          cashCode: (_isCash || isCard) ? _cashCodeController.text : null,
          documentNo:
              (_isCash || isCheck || isCard) ? _documentNoController.text : null,
          currencyCode: _isCash
              ? CollectionCurrencyExchange.normalize(
                  _currencyController.text,
                )
              : null,
          exchangeRate: exchangeRate,
          baseAmount: (baseAmount != null && baseAmount > 0) ? baseAmount : null,
          baseCurrencyCode: _isCash ? _defaultCurrencyCode : null,
          salespersonCode: _isCash ? _salespersonController.text : null,
          specialCode1: _isCash ? _specialCodeController.text : null,
          endorsement: isCheck ? _endorsementController.text : null,
          originalDebtor: isCheck ? _originalDebtorController.text : null,
          workplace: isCheck ? _workplaceController.text : null,
          accountNumber: isCheck ? _accountNoController.text : null,
        );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.collection_saved')),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(collectionProvider).error;
      final message = (error != null && error.startsWith('field_sales.'))
          ? l10n.translate(error)
          : '${l10n.translate('common.error')}: ${error ?? ''}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
