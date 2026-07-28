// Dosya Adı: credit_card_collection_screen.dart
// Açıklama: Kredi kartı tahsilat dens formu — cari-önce + EVRAK/POS CashCard
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../model/finance_movement_type.dart';
import '../viewmodel/collection_provider.dart';
import '../widgets/cash_card_code_field.dart';
import 'collection_customer_selection_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template credit_card_collection_screen}
/// Kredi kartı tahsilatı dens flat form (MBT KREDI KART TAHSILATI).
/// Route: `/field-sales/cc-collection`
///
/// Kullanım örneği:
/// ```dart
/// CreditCardCollectionScreen(customerId: 'C001');
/// ```
/// {@endtemplate}
class CreditCardCollectionScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/cc-collection`
  static const String routeName = '/field-sales/cc-collection';

  /// [customerId]: Seçili cari kimliği (yoksa cari seçime yönlendirir)
  final String? customerId;

  /// {@macro credit_card_collection_screen}
  const CreditCardCollectionScreen({Key? key, this.customerId})
      : super(key: key);

  @override
  ConsumerState<CreditCardCollectionScreen> createState() =>
      _CreditCardCollectionScreenState();
}

class _CreditCardCollectionScreenState
    extends ConsumerState<CreditCardCollectionScreen> {
  /// [_amountController]: Tutar
  final _amountController = TextEditingController();

  /// [_documentNoController]: Evrak no
  final _documentNoController = TextEditingController();

  /// [_safeCodeController]: POS / kasa kodu
  final _safeCodeController = TextEditingController();

  /// [_notesController]: Açıklama
  final _notesController = TextEditingController();

  /// [_missingCustomer]: Cari eksik — yönlendirme
  bool _missingCustomer = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!CollectionNotifier.isValidCustomerId(widget.customerId)) {
        if (!mounted) return;
        setState(() => _missingCustomer = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                'field_sales.cc_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CollectionCustomerSelectionScreen(
              purpose: CollectionSelectionPurpose.creditCard,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _documentNoController.dispose();
    _safeCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// {@template _handleSave}
  /// KK tahsilat kaydı — collectionProvider + CreditCard tipi.
  /// {@endtemplate}
  Future<void> _handleSave() async {
    final l10n = AppLocalization.of(context);
    final customerId = widget.customerId?.trim() ?? '';
    if (!CollectionNotifier.isValidCustomerId(customerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.cc_requires_customer')),
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

    final docNo = _documentNoController.text.trim();
    final baseNotes = _notesController.text.trim();

    final success = await ref.read(collectionProvider.notifier).saveCollection(
          customerId: customerId,
          amount: amount,
          paymentType: FinanceMovementType.creditCardCollection.apiCode,
          notes: baseNotes.isEmpty ? null : baseNotes,
          documentNo: docNo.isEmpty ? null : docNo,
          cashCode: _safeCodeController.text.trim(),
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.collection_saved')),
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          l10n.translate('field_sales.stubs.credit_card_collection'),
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
                    l10n.translate('field_sales.amount_to_collect'),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
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
                    controller: _safeCodeController,
                    label: l10n.translate('field_sales.cc_pos_code'),
                    prefixIcon: Icons.point_of_sale,
                    fillColor: FieldSalesDensTheme.surface(context),
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
                      fillColor: FieldSalesDensTheme.surface(context),
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
                      hintText:
                          l10n.translate('field_sales.collection_notes_hint'),
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
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
                        l10n.translate('field_sales.collection_confirm'),
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

  /// {@template _field}
  /// Dens TextField (prefix ikon).
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
        fillColor: FieldSalesDensTheme.surface(context),
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
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
