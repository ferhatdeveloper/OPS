// Dosya Adı: payment_entry_screen.dart
// Açıklama: Nakit / KK ödeme dens formu — cari-önce + SQLite kayıt
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../currency/engine/collection_currency_exchange.dart';
import '../../currency/viewmodel/currency_rate_store.dart';
import '../../currency/viewmodel/default_currency_resolver.dart';
import '../model/finance_movement_type.dart';
import '../viewmodel/collection_provider.dart';
import '../widgets/cash_card_code_field.dart';
import '../widgets/collection_cash_mbt_fields.dart';
import 'collection_customer_selection_screen.dart';

/// {@template payment_entry_screen}
/// MBT NAKIT ÖDEME / KREDI KARTI İLE ÖDEME — dens flat form + SQLite.
/// Route: `/field-sales/payment-entry`
///
/// Kullanım örneği:
/// ```dart
/// PaymentEntryScreen(customerId: 'C001');
/// PaymentEntryScreen(
///   customerId: 'C001',
///   initialPaymentType: 'CashOut',
/// );
/// ```
/// {@endtemplate}
class PaymentEntryScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/payment-entry`
  static const String routeName = '/field-sales/payment-entry';

  /// [customerId]: Seçili cari kimliği
  final String customerId;

  /// [initialPaymentType]: CashOut | CreditCardOut (opsiyonel)
  final String? initialPaymentType;

  /// {@macro payment_entry_screen}
  const PaymentEntryScreen({
    Key? key,
    required this.customerId,
    this.initialPaymentType,
  }) : super(key: key);

  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen> {
  /// [_amountController]: Ödeme tutarı
  final _amountController = TextEditingController();

  /// [_notesController]: KK açıklama (nakitte dens açıklama kullanılır)
  final _notesController = TextEditingController();

  /// [_cashCodeController]: Kasa / POS kodu
  final _cashCodeController = TextEditingController();

  /// [_currencyController]: İşlem dövizi (nakit dens)
  final _currencyController = TextEditingController();

  /// [_exchangeRateController]: Kur (seçilen → merkez)
  final _exchangeRateController = TextEditingController(text: '1');

  /// [_defaultCurrencyCode]: Merkez varsayılan
  String _defaultCurrencyCode =
      CollectionCurrencyExchange.fallbackDefaultCode;

  /// [_rateMap]: Kur haritası
  Map<String, String> _rateMap = const {};

  /// [_documentNoController]: Evrak no
  final _documentNoController = TextEditingController();

  /// [_descriptionController]: Nakit dens açıklama
  final _descriptionController = TextEditingController();

  /// [_salespersonController]: Plasiyer
  final _salespersonController = TextEditingController();

  /// [_specialCodeController]: Özelkod 1
  final _specialCodeController = TextEditingController();

  /// [_selectedType]: CashOut | CreditCardOut
  late FinanceMovementType _selectedType;

  /// [_missingCustomer]: Cari eksik — yönlendirme
  bool _missingCustomer = false;

  /// [_isCashOut]: Nakit ödeme dens alanları
  bool get _isCashOut => _selectedType == FinanceMovementType.cashOut;

  /// [_isCardOut]: KK ödeme dens alanları
  bool get _isCardOut => _selectedType == FinanceMovementType.creditCardOut;

  @override
  void initState() {
    super.initState();
    final parsed = FinanceMovementType.fromStorage(widget.initialPaymentType);
    _selectedType = parsed.kind == FinanceMovementKind.payment
        ? parsed
        : FinanceMovementType.cashOut;
    _amountController.addListener(_onCurrencyUiChanged);
    _exchangeRateController.addListener(_onCurrencyUiChanged);
    Future.microtask(() async {
      await _prefillDefaultCurrency();
      if (!CollectionNotifier.isValidCustomerId(widget.customerId)) {
        if (!mounted) return;
        setState(() => _missingCustomer = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                'field_sales.payment_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CollectionCustomerSelectionScreen(
              purpose: CollectionSelectionPurpose.payment,
              initialPaymentType: _selectedType.apiCode,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onCurrencyUiChanged);
    _exchangeRateController.removeListener(_onCurrencyUiChanged);
    _amountController.dispose();
    _notesController.dispose();
    _cashCodeController.dispose();
    _currencyController.dispose();
    _exchangeRateController.dispose();
    _documentNoController.dispose();
    _descriptionController.dispose();
    _salespersonController.dispose();
    _specialCodeController.dispose();
    super.dispose();
  }

  /// {@template payment_entry_on_currency_ui}
  /// Kur / tutar değişince dens özet yenilenir.
  /// {@endtemplate}
  void _onCurrencyUiChanged() {
    if (mounted) setState(() {});
  }

  /// {@template payment_entry_prefill_currency}
  /// Merkez varsayılan döviz + kur map.
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

  /// {@template payment_entry_apply_rate}
  /// Seçilen döviz için kur doldurur.
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

  /// {@template _handleSave}
  /// Ödeme kaydı — collectionProvider + CashOut / CreditCardOut.
  /// {@endtemplate}
  Future<void> _handleSave() async {
    final l10n = AppLocalization.of(context);
    if (!CollectionNotifier.isValidCustomerId(widget.customerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.payment_requires_customer')),
        ),
      );
      return;
    }
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.payment_invalid_amount')),
        ),
      );
      return;
    }

    final notes = _isCashOut
        ? _descriptionController.text.trim()
        : _notesController.text.trim();

    final exchangeRate = _isCashOut
        ? CollectionCurrencyExchange.parseRate(_exchangeRateController.text)
        : null;
    final baseAmount = (_isCashOut &&
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
          paymentType: _selectedType.apiCode,
          notes: notes.isEmpty ? null : notes,
          cashCode: _cashCodeController.text.trim(),
          documentNo: _documentNoController.text.trim(),
          currencyCode: _isCashOut
              ? CollectionCurrencyExchange.normalize(
                  _currencyController.text,
                )
              : null,
          exchangeRate: exchangeRate,
          baseAmount: (baseAmount != null && baseAmount > 0) ? baseAmount : null,
          baseCurrencyCode: _isCashOut ? _defaultCurrencyCode : null,
          salespersonCode:
              _isCashOut ? _salespersonController.text.trim() : null,
          specialCode1:
              _isCashOut ? _specialCodeController.text.trim() : null,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.payment_out_saved')),
        ),
      );
      Navigator.of(context).maybePop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final state = ref.watch(collectionProvider);
    if (_missingCustomer) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          l10n.translate('field_sales.payment_entry_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _card(
              child: Column(
                children: [
                  Text(
                    l10n.translate('field_sales.amount_to_pay'),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
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
                  const SizedBox(height: 8),
                  _buildTypeSelector(l10n),
                ],
              ),
            ),
            if (_isCashOut) ...[
              const SizedBox(height: 12),
              _card(
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
                  titleL10nKey: 'field_sales.payment_cash_fields_title',
                  onCurrencyChanged: (code) {
                    setState(() => _applyRateForCurrency(code));
                  },
                ),
              ),
            ],
            if (_isCardOut) ...[
              const SizedBox(height: 12),
              _card(
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
                    const SizedBox(height: 8),
                    _field(
                      _documentNoController,
                      l10n.translate('field_sales.cc_document_no'),
                      Icons.receipt_long,
                    ),
                    const SizedBox(height: 8),
                    CashCardCodeField(
                      controller: _cashCodeController,
                      label: l10n.translate('field_sales.cc_pos_code'),
                      prefixIcon: Icons.point_of_sale,
                      fillColor: const Color(0xFFF8F9FD),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
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
                        contentPadding: const EdgeInsets.all(10),
                        hintText: l10n
                            .translate('field_sales.payment_out_notes_hint'),
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
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
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.translate('field_sales.payment_out_confirm'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// {@template _buildTypeSelector}
  /// Nakit Ödeme / KK Ödeme seçici (2 sütun dens).
  /// {@endtemplate}
  Widget _buildTypeSelector(AppLocalization l10n) {
    final types = [
      {
        'val': FinanceMovementType.cashOut,
        'label': l10n.translate('field_sales.payment_cash_out'),
        'icon': Icons.money,
      },
      {
        'val': FinanceMovementType.creditCardOut,
        'label': l10n.translate('field_sales.payment_card_out'),
        'icon': Icons.credit_card,
      },
    ];

    return Row(
      children: types.map((t) {
        final type = t['val'] as FinanceMovementType;
        final isSelected = _selectedType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedType = type),
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

  /// {@template _field}
  /// Dens TextField (prefix ikon) — KK ödeme parity.
  /// {@endtemplate}
  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        prefixIcon: Icon(icon, size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  /// {@template _card}
  /// Dens flat kart.
  /// {@endtemplate}
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
