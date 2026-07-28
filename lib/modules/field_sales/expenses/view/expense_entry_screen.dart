// Dosya Adı: expense_entry_screen.dart
// Açıklama: Masraf girişi dens form — Kaydet → SQLite expenses
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/expense_record.dart';
import '../viewmodel/expense_entry_service.dart';
import '../widgets/expense_entry_mbt_fields.dart';

/// {@template expense_entry_screen}
/// Masraf girişi dens ekranı (tip · tutar · not · Kaydet → SQLite).
/// Route: `/field-sales/expense-entry`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ExpenseEntryScreen.routeName);
/// ```
/// {@endtemplate}
class ExpenseEntryScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/expense-entry`
  static const String routeName = '/field-sales/expense-entry';

  /// {@template expense_entry_screen_constructor}
  /// Masraf girişi dens ekranını oluşturur.
  /// {@endtemplate}
  const ExpenseEntryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  /// [_amountController]: Tutar
  final TextEditingController _amountController = TextEditingController();

  /// [_noteController]: Açıklama
  final TextEditingController _noteController = TextEditingController();

  /// [_type]: Masraf tipi
  ExpenseType _type = ExpenseType.fuel;

  /// [_saving]: Kaydet durumu
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// {@template expense_entry_on_save}
  /// Formu doğrular ve yerel `expenses` tablosuna yazar.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    final l10n = AppLocalization.of(context);
    final amount = ExpenseRecord.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.expense.amount_required'),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final record = ExpenseRecord(
        id: const Uuid().v4(),
        type: _type,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await ExpenseEntryService.saveLocal(db: db, record: record);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.expense.saved')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.expense.save_failed')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.expense_entry');

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
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: ExpenseEntryMbtFields(
                type: _type,
                onTypeChanged: (v) => setState(() => _type = v),
                amountController: _amountController,
                noteController: _noteController,
              ),
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
