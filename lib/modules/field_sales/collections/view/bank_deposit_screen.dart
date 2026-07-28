// Dosya Adı: bank_deposit_screen.dart
// Açıklama: Banka yatırma dens form — Kaydet → bank_deposits + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../model/bank_deposit_record.dart';
import '../model/cash_card_master.dart';
import '../viewmodel/bank_deposit_service.dart';
import 'cash_card_list_screen.dart';

/// {@template bank_deposit_screen}
/// Banka yatırma dens form (Kasa · Banka · Tutar · Evrak · Kaydet).
/// Kaydet: yerel `bank_deposits` + `sync_queue` (cari yok).
///
/// Route: `/field-sales/bank-deposit`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, BankDepositScreen.routeName);
/// ```
/// {@endtemplate}
class BankDepositScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/bank-deposit`
  static const String routeName = '/field-sales/bank-deposit';

  const BankDepositScreen({Key? key}) : super(key: key);

  @override
  State<BankDepositScreen> createState() => _BankDepositScreenState();
}

class _BankDepositScreenState extends State<BankDepositScreen> {
  /// [_cashCode]: Kaynak kasa kodu
  String _cashCode = CashCardMaster.defaultCode;

  /// [_bankCode]: Hedef banka hesap kodu
  String _bankCode = '';

  /// [_depositDate]: Yatırma tarihi
  DateTime _depositDate = DateTime.now();

  /// [_amountController]: Tutar
  final TextEditingController _amountController = TextEditingController();

  /// [_documentController]: Evrak no
  final TextEditingController _documentController = TextEditingController();

  /// [_notesController]: Açıklama
  final TextEditingController _notesController = TextEditingController();

  /// [_saving]: Kaydet devam ediyor
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _documentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _depositDate,
      firstDate: DateTime(_depositDate.year - 1),
      lastDate: DateTime(_depositDate.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() => _depositDate = picked);
  }

  Future<void> _openCashPicker({required bool forBank}) async {
    final selected = await Navigator.of(context).push<CashCardOption>(
      MaterialPageRoute(
        builder: (_) => CashCardListScreen(
          selectionMode: true,
          initialCode: forBank
              ? (_bankCode.isEmpty ? null : _bankCode)
              : _cashCode,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (forBank) {
        _bankCode = selected.code;
      } else {
        _cashCode = selected.code;
      }
    });
  }

  /// {@template bank_deposit_on_save}
  /// Guard → yerel kaydet + sync_queue; kuyruk işlemeyi tetikler.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    final l10n = AppLocalization.of(context);
    final amount = BankDepositRecord.parseAmount(_amountController.text);
    final guard = BankDepositRecord.validateGuard(
      cashCode: _cashCode,
      bankCode: _bankCode,
      amount: amount,
    );
    if (guard != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate(guard))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final notes = _notesController.text.trim();
      final doc = _documentController.text.trim();
      final record = BankDepositRecord(
        id: const Uuid().v4(),
        cashCode: _cashCode.trim(),
        bankCode: _bankCode.trim(),
        amount: amount!,
        documentNo: doc.isEmpty ? null : doc,
        depositDate: _depositDate,
        notes: notes.isEmpty ? null : notes,
        onay: 1,
        isSynced: false,
        createdAt: now,
        updatedAt: now,
      );

      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await BankDepositService.saveLocalAndQueue(db: db, record: record);
      // ignore: unawaited_futures
      JobQueueService().processQueue();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.bank_deposit.queued'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.bank_deposit.save_error'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) {
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
    final bankDisplay = _bankCode.isEmpty
        ? l10n.translate('field_sales.bank_deposit.bank_hint')
        : CashCardMaster.displayOf(l10n, _bankCode);

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
          l10n.translate('field_sales.stubs.bank_deposit'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                Text(
                  l10n.translate('field_sales.bank_deposit.hint'),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _openCashPicker(forBank: false),
                  child: InputDecorator(
                    decoration: _decoration(
                      l10n.translate('field_sales.bank_deposit.cash_code'),
                    ).copyWith(
                      suffixIcon: const Icon(Icons.arrow_drop_down, size: 22),
                    ),
                    child: Text(
                      CashCardMaster.displayOf(l10n, _cashCode),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openCashPicker(forBank: true),
                  child: InputDecorator(
                    decoration: _decoration(
                      l10n.translate('field_sales.bank_deposit.bank_code'),
                    ).copyWith(
                      suffixIcon: const Icon(Icons.arrow_drop_down, size: 22),
                    ),
                    child: Text(
                      bankDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        color: _bankCode.isEmpty
                            ? Colors.grey.shade500
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: _decoration(
                      l10n.translate('field_sales.bank_deposit.date'),
                    ),
                    child: Text(
                      '${_depositDate.day.toString().padLeft(2, '0')}.'
                      '${_depositDate.month.toString().padLeft(2, '0')}.'
                      '${_depositDate.year}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  style: const TextStyle(fontSize: 13),
                  decoration: _decoration(
                    l10n.translate('field_sales.bank_deposit.amount'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _documentController,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 13),
                  decoration: _decoration(
                    l10n.translate('field_sales.bank_deposit.document_no'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 13),
                  decoration: _decoration(
                    l10n.translate('field_sales.bank_deposit.notes'),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375A7F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
