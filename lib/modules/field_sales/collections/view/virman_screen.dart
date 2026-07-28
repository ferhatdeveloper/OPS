// Dosya Adı: virman_screen.dart
// Açıklama: Virman fişi minimal form (MBT FİNANS → VIRMAN FIŞI)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../model/cash_card_master.dart';
import '../view/cash_card_list_screen.dart';
import '../viewmodel/collection_provider.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template virman_screen}
/// Kasa/banka arası virman fişi — dens flat minimal form.
/// Route: `/field-sales/virman`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VirmanScreen.routeName);
/// ```
/// {@endtemplate}
class VirmanScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/virman`
  static const String routeName = '/field-sales/virman';

  /// {@macro virman_screen}
  const VirmanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VirmanScreen> createState() => _VirmanScreenState();
}

class _VirmanScreenState extends ConsumerState<VirmanScreen> {
  /// [_fromController]: Kaynak kasa/hesap kodu
  final _fromController = TextEditingController();

  /// [_toController]: Hedef kasa/hesap kodu
  final _toController = TextEditingController();

  /// [_amountController]: Tutar
  final _amountController = TextEditingController();

  /// [_notesController]: Açıklama
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// {@template _handleSave}
  /// Virman fişi — SQLite + kuyruk (`payment_type=virman`).
  /// {@endtemplate}
  Future<void> _handleSave() async {
    final l10n = AppLocalization.of(context);
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.virman_requires_accounts')),
        ),
      );
      return;
    }
    if (from == to) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.virman_same_account')),
        ),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.payment_invalid_amount')),
        ),
      );
      return;
    }

    final notes = _notesController.text.trim();
    final success = await ref.read(collectionProvider.notifier).saveVirman(
          fromSafeCode: from,
          toSafeCode: to,
          amount: amount,
          notes: notes.isEmpty ? null : notes,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('field_sales.virman_saved'))),
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
    final saving = ref.watch(collectionProvider).isLoading;

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
          l10n.translate('field_sales.virman_entry_title'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('field_sales.virman_accounts_label'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _cashCardField(
                    context,
                    l10n,
                    controller: _fromController,
                    label: l10n.translate('field_sales.virman_from_account'),
                    icon: Icons.account_balance_wallet,
                  ),
                  const SizedBox(height: 8),
                  _cashCardField(
                    context,
                    l10n,
                    controller: _toController,
                    label: l10n.translate('field_sales.virman_to_account'),
                    icon: Icons.account_balance,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  Text(
                    l10n.translate('field_sales.virman_amount_label'),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
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
                          l10n.translate('field_sales.virman_notes_hint'),
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
                onPressed: saving ? null : _handleSave,
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.translate('field_sales.virman_confirm'),
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

  /// {@template _open_cash_card_picker}
  /// Kasa Kart Listesi dens seçici — sonucu [controller]'a yazar.
  ///
  /// Parametreler:
  /// - [context]: Navigator bağlamı
  /// - [controller]: Kaynak veya hedef safe_code alanı
  /// {@endtemplate}
  Future<void> _openCashCardPicker(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final selected = await Navigator.of(context).push<CashCardOption>(
      MaterialPageRoute(
        builder: (_) => CashCardListScreen(
          selectionMode: true,
          initialCode: controller.text.trim().isEmpty
              ? CashCardMaster.defaultCode
              : controller.text.trim(),
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      controller.text = selected.code;
    });
  }

  /// {@template _cash_card_field}
  /// Kaynak/hedef kasa dens seçici (readOnly → CashCardMaster).
  ///
  /// Parametreler:
  /// - [context]: BuildContext
  /// - [l10n]: Yerelleştirme
  /// - [controller]: safe_code controller
  /// - [label]: Alan etiketi
  /// - [icon]: Prefix ikon
  /// {@endtemplate}
  Widget _cashCardField(
    BuildContext context,
    AppLocalization l10n, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onTap: () => _openCashCardPicker(context, controller),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        prefixIcon: Icon(icon, size: 20),
        hintText: l10n.translate('field_sales.cash_card_select_hint'),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey.shade600,
        ),
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
