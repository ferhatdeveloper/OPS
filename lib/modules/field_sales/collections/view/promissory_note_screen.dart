// Dosya Adı: promissory_note_screen.dart
// Açıklama: Senet tahsilat dens formu — cari-önce + no/banka/vade
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../model/finance_movement_type.dart';
import '../viewmodel/collection_provider.dart';
import 'collection_customer_selection_screen.dart';

/// {@template promissory_note_screen}
/// Senet tahsilatı dens flat form (MBT SENET TAHSILATI).
/// Route: `/field-sales/promissory`
///
/// Kullanım örneği:
/// ```dart
/// PromissoryNoteScreen(customerId: 'C001');
/// ```
/// {@endtemplate}
class PromissoryNoteScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/promissory`
  static const String routeName = '/field-sales/promissory';

  /// [customerId]: Seçili cari kimliği (yoksa cari seçime yönlendirir)
  final String? customerId;

  /// {@macro promissory_note_screen}
  const PromissoryNoteScreen({Key? key, this.customerId}) : super(key: key);

  @override
  ConsumerState<PromissoryNoteScreen> createState() =>
      _PromissoryNoteScreenState();
}

class _PromissoryNoteScreenState extends ConsumerState<PromissoryNoteScreen> {
  /// [_amountController]: Tutar
  final _amountController = TextEditingController();

  /// [_noteNoController]: Senet numarası
  final _noteNoController = TextEditingController();

  /// [_bankController]: Banka adı
  final _bankController = TextEditingController();

  /// [_notesController]: Açıklama
  final _notesController = TextEditingController();

  /// [_dueDate]: Vade tarihi
  DateTime? _dueDate;

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
                'field_sales.promissory_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CollectionCustomerSelectionScreen(
              purpose: CollectionSelectionPurpose.promissory,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteNoController.dispose();
    _bankController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// {@template _selectDueDate}
  /// Senet vade tarihi seçici.
  /// {@endtemplate}
  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  /// {@template _handleSave}
  /// Senet tahsilat kaydı — collectionProvider + Note tipi.
  /// {@endtemplate}
  Future<void> _handleSave() async {
    final l10n = AppLocalization.of(context);
    final customerId = widget.customerId?.trim() ?? '';
    if (!CollectionNotifier.isValidCustomerId(customerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.promissory_requires_customer'),
          ),
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

    final baseNotes = _notesController.text.trim();
    final success = await ref.read(collectionProvider.notifier).saveCollection(
          customerId: customerId,
          amount: amount,
          paymentType: FinanceMovementType.noteCollection.apiCode,
          notes: baseNotes.isEmpty ? null : baseNotes,
          bankName: _bankController.text.trim(),
          checkNumber: _noteNoController.text.trim(),
          dueDate: _dueDate,
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
          l10n.translate('field_sales.stubs.promissory_note'),
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
                    l10n.translate('field_sales.note_details'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _noteNoController,
                    l10n.translate('field_sales.note_number'),
                    Icons.confirmation_number,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _bankController,
                    l10n.translate('field_sales.note_bank_name'),
                    Icons.account_balance,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
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
                                ? l10n.translate('field_sales.note_due_date')
                                : l10n.translate(
                                    'field_sales.due_date_prefix',
                                    args: {
                                      'date':
                                          '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}',
                                    },
                                  ),
                            style: TextStyle(
                              color: _dueDate == null
                                  ? Colors.grey.shade600
                                  : Colors.black,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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
