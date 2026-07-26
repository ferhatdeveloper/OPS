// Dosya Adı: cash_count_screen.dart
// Açıklama: Kasa sayımı dens form — Kaydet → cash_counts + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../model/cash_card_master.dart';
import '../model/cash_count_record.dart';
import '../viewmodel/cash_count_service.dart';
import 'cash_card_list_screen.dart';

/// {@template cash_count_screen}
/// Kasa sayımı dens form (Kasa · Tarih · Sistem/Sayılan · Küpür · Kaydet).
/// Kaydet: yerel `cash_counts` + `sync_queue`.
///
/// Route: `/field-sales/cash-count`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CashCountScreen.routeName);
/// ```
/// {@endtemplate}
class CashCountScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/cash-count`
  static const String routeName = '/field-sales/cash-count';

  const CashCountScreen({Key? key}) : super(key: key);

  @override
  State<CashCountScreen> createState() => _CashCountScreenState();
}

class _CashCountScreenState extends State<CashCountScreen> {
  /// [_cashCode]: Seçili safe_code
  String _cashCode = CashCardMaster.defaultCode;

  /// [_countDate]: Sayım tarihi
  DateTime _countDate = DateTime.now();

  /// [_expectedController]: Sistem bakiyesi
  final TextEditingController _expectedController = TextEditingController();

  /// [_countedController]: Sayılan tutar
  final TextEditingController _countedController = TextEditingController();

  /// [_notesController]: Açıklama
  final TextEditingController _notesController = TextEditingController();

  /// [_lines]: Küpür satır iskeleti
  final List<_CashCountLineDraft> _lines = [];

  /// [_saving]: Kaydet devam ediyor
  bool _saving = false;

  @override
  void dispose() {
    _expectedController.dispose();
    _countedController.dispose();
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  /// {@template _parse_amount}
  /// Tutar metnini double'a çevirir.
  /// {@endtemplate}
  double? _parseAmount(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    return double.tryParse(t);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _countDate,
      firstDate: DateTime(_countDate.year - 1),
      lastDate: DateTime(_countDate.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() => _countDate = picked);
  }

  Future<void> _openCashCardPicker() async {
    final selected = await Navigator.of(context).push<CashCardOption>(
      MaterialPageRoute(
        builder: (_) => CashCardListScreen(
          selectionMode: true,
          initialCode: _cashCode,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _cashCode = selected.code);
  }

  void _addLine(AppLocalization l10n) {
    setState(() {
      _lines.add(
        _CashCountLineDraft(
          denomination: TextEditingController(
            text: l10n.translate('field_sales.cash_count.denom_sample'),
          ),
          qty: TextEditingController(text: '0'),
        ),
      );
    });
  }

  /// {@template cash_count_on_save}
  /// Yerel kaydet + sync_queue; ardından kuyruk işlemeyi tetikler.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    final l10n = AppLocalization.of(context);

    if (_cashCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.cash_count.requires_cash_code'),
          ),
        ),
      );
      return;
    }

    final expected = _parseAmount(_expectedController.text);
    final counted = _parseAmount(_countedController.text);
    if (expected == null || counted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.cash_count.invalid_amount'),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final notes = _notesController.text.trim();
      final record = CashCountRecord(
        id: const Uuid().v4(),
        cashCode: _cashCode.trim(),
        countDate: _countDate,
        expectedAmount: expected,
        countedAmount: counted,
        notes: notes.isEmpty ? null : notes,
        lines: _lines
            .map(
              (l) => CashCountLine(
                denomination: l.denomination.text.trim(),
                qty: l.qty.text.trim().isEmpty ? '0' : l.qty.text.trim(),
              ),
            )
            .where((l) => l.denomination.isNotEmpty)
            .toList(),
        onay: 1,
        isSynced: false,
        createdAt: now,
        updatedAt: now,
      );

      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await CashCountService.saveLocalAndQueue(db: db, record: record);
      // ignore: unawaited_futures
      JobQueueService().processQueue();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.cash_count.queued'),
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
            l10n.translate('field_sales.cash_count.save_error'),
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
      fillColor: Colors.white,
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
    final expected = _parseAmount(_expectedController.text) ?? 0;
    final counted = _parseAmount(_countedController.text) ?? 0;
    final diff = counted - expected;

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
          l10n.translate('field_sales.stubs.cash_count'),
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
                  l10n.translate('field_sales.cash_count.hint'),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _openCashCardPicker,
                  child: InputDecorator(
                    decoration: _decoration(
                      l10n.translate('field_sales.payment_cash_code'),
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
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: _decoration(
                      l10n.translate('field_sales.cash_count.date'),
                    ),
                    child: Text(
                      '${_countDate.day.toString().padLeft(2, '0')}.'
                      '${_countDate.month.toString().padLeft(2, '0')}.'
                      '${_countDate.year}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _expectedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: _decoration(
                    l10n.translate('field_sales.cash_count.expected'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _countedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: _decoration(
                    l10n.translate('field_sales.cash_count.counted'),
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: _decoration(
                    l10n.translate('field_sales.cash_count.difference'),
                  ),
                  child: Text(
                    diff.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: diff == 0
                          ? const Color(0xFF2C3E50)
                          : (diff < 0 ? Colors.red.shade700 : Colors.green.shade700),
                    ),
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
                    l10n.translate('field_sales.cash_count.notes'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('field_sales.cash_count.lines'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addLine(l10n),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        l10n.translate('field_sales.cash_count.add_line'),
                      ),
                    ),
                  ],
                ),
                if (_lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.translate('field_sales.cash_count.lines_empty'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ..._lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: line.denomination,
                            style: const TextStyle(fontSize: 13),
                            textCapitalization: TextCapitalization.characters,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration(
                              l10n.translate(
                                'field_sales.cash_count.denomination',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: line.qty,
                            style: const TextStyle(fontSize: 13),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.none,
                            decoration: _decoration(
                              l10n.translate('field_sales.cash_count.qty'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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

/// {@template cash_count_line_draft}
/// Dens form küpür satırı controller çifti.
/// {@endtemplate}
class _CashCountLineDraft {
  /// [denomination]: Küpür alanı
  final TextEditingController denomination;

  /// [qty]: Adet alanı
  final TextEditingController qty;

  _CashCountLineDraft({
    required this.denomination,
    required this.qty,
  });

  /// {@template cash_count_line_draft_dispose}
  /// Controller'ları serbest bırakır.
  /// {@endtemplate}
  void dispose() {
    denomination.dispose();
    qty.dispose();
  }
}
