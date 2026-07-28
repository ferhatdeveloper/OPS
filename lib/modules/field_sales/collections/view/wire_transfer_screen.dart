// Dosya Adı: wire_transfer_screen.dart
// Açıklama: Havale/EFT dens formu — cari-önce + SQLite Kaydet
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../viewmodel/collection_provider.dart';
import 'collection_customer_selection_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template wire_transfer_screen}
/// Havale/EFT dens flat form (MBT FİNANS → Havale/EFT).
/// Route: `/field-sales/wire-transfer`
///
/// Kullanım örneği:
/// ```dart
/// WireTransferScreen(customerId: 'C001');
/// Navigator.pushNamed(context, WireTransferScreen.routeName);
/// ```
/// {@endtemplate}
class WireTransferScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/wire-transfer`
  static const String routeName = '/field-sales/wire-transfer';

  /// [customerId]: Seçili cari (yoksa cari seçime yönlendirir)
  final String? customerId;

  /// {@macro wire_transfer_screen}
  const WireTransferScreen({Key? key, this.customerId}) : super(key: key);

  @override
  ConsumerState<WireTransferScreen> createState() => _WireTransferScreenState();
}

class _WireTransferScreenState extends ConsumerState<WireTransferScreen> {
  /// [_amountController]: Tutar
  final _amountController = TextEditingController();

  /// [_documentNoController]: Evrak no
  final _documentNoController = TextEditingController();

  /// [_bankCodeController]: Banka / hesap kodu (safe_code)
  final _bankCodeController = TextEditingController();

  /// [_bankNameController]: Banka adı
  final _bankNameController = TextEditingController();

  /// [_accountController]: IBAN / hesap no
  final _accountController = TextEditingController();

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
                'field_sales.wire_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CollectionCustomerSelectionScreen(
              purpose: CollectionSelectionPurpose.wireTransfer,
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
    _bankCodeController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// {@template _handleSave}
  /// Havale/EFT — collectionProvider.saveWireTransfer → SQLite.
  /// {@endtemplate}
  Future<void> _handleSave() async {
    final l10n = AppLocalization.of(context);
    final customerId = widget.customerId?.trim() ?? '';
    if (!CollectionNotifier.isValidCustomerId(customerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.wire_requires_customer')),
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
    final bankCode = _bankCodeController.text.trim();
    if (bankCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.wire_requires_bank_code')),
        ),
      );
      return;
    }

    final notes = _notesController.text.trim();
    final bankName = _bankNameController.text.trim();
    final account = _accountController.text.trim();
    final docNo = _documentNoController.text.trim();

    final success =
        await ref.read(collectionProvider.notifier).saveWireTransfer(
              customerId: customerId,
              amount: amount,
              bankCode: bankCode,
              bankName: bankName.isEmpty ? null : bankName,
              accountNumber: account.isEmpty ? null : account,
              documentNo: docNo.isEmpty ? null : docNo,
              notes: notes.isEmpty ? null : notes,
            );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('field_sales.wire_saved'))),
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
          l10n.translate('field_sales.wire_entry_title'),
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
                    l10n.translate('field_sales.wire_details'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _documentNoController,
                    l10n.translate('field_sales.wire_document_no'),
                    Icons.receipt_long,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _bankCodeController,
                    l10n.translate('field_sales.wire_bank_code'),
                    Icons.account_balance,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _bankNameController,
                    l10n.translate('field_sales.wire_bank_name'),
                    Icons.business,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _accountController,
                    l10n.translate('field_sales.wire_account_no'),
                    Icons.numbers,
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
                      hintText: l10n.translate('field_sales.wire_notes_hint'),
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
                        l10n.translate('field_sales.wire_confirm'),
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

  /// {@template _card}
  /// Dens flat kart yüzeyi.
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
}
