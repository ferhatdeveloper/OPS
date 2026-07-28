// Dosya Adı: bank_card_list_screen.dart
// Açıklama: Banka Kart Listesi dens — SQLite CRUD (create·update·soft delete)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/bank_card_master.dart';
import '../viewmodel/bank_card_store.dart';

/// {@template bank_card_list_screen}
/// Banka kart listesi dens — ara · kod/bakiye/ünvan · CRUD.
/// Route: `/field-sales/bank-cards`
/// {@endtemplate}
class BankCardListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/bank-cards';

  /// Opsiyonel satır enjeksiyonu (test)
  final List<BankCardOption>? rows;

  /// Store enjeksiyonu (test)
  final BankCardStore? store;

  /// {@macro bank_card_list_screen}
  const BankCardListScreen({Key? key, this.rows, this.store}) : super(key: key);

  @override
  State<BankCardListScreen> createState() => _BankCardListScreenState();
}

class _BankCardListScreenState extends State<BankCardListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<BankCardOption> _all;
  late List<BankCardOption> _filtered;
  List<BankCardRecord> _records = const [];
  bool _loading = false;

  BankCardStore get _store => widget.store ?? const BankCardStore();

  @override
  void initState() {
    super.initState();
    _all = List<BankCardOption>.from(
      widget.rows ?? BankCardMaster.options,
    );
    _filtered = List<BankCardOption>.from(_all);
    if (widget.rows == null) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _store.ensureReady();
      final rows = await _store.listActive();
      if (!mounted) return;
      setState(() {
        _records = rows;
        if (rows.isNotEmpty) {
          _all = rows.map((r) => r.toOption()).toList(growable: false);
          _applyFilter(_searchController.text);
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter(String query) {
    final l10n = AppLocalization.of(context);
    setState(() {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        _filtered = List<BankCardOption>.from(_all);
      } else {
        _filtered = _all
            .where(
              (o) =>
                  o.code.toLowerCase().contains(q) ||
                  o.label(l10n).toLowerCase().contains(q),
            )
            .toList(growable: false);
      }
    });
  }

  BankCardRecord? _recordOf(BankCardOption option) {
    for (final r in _records) {
      if (r.code == option.code) return r;
    }
    return null;
  }

  Future<void> _showEditor({BankCardRecord? existing}) async {
    final l10n = AppLocalization.of(context);
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(
      text: existing?.nameKey.trim().isNotEmpty == true
          ? existing!.name
          : (existing?.name ?? ''),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            existing == null
                ? l10n.translate('field_sales.bank_card_create')
                : l10n.translate('field_sales.bank_card_edit'),
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                enabled: existing == null,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.translate('field_sales.bank_card_code'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.translate('field_sales.bank_card_name'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.translate('common.save')),
            ),
          ],
        );
      },
    );
    if (saved != true || !mounted) {
      codeCtrl.dispose();
      nameCtrl.dispose();
      return;
    }
    final code = codeCtrl.text.trim();
    final name = nameCtrl.text.trim();
    codeCtrl.dispose();
    nameCtrl.dispose();
    if (code.isEmpty || name.isEmpty) return;
    try {
      if (existing == null) {
        await _store.create(code: code, name: name);
      } else {
        await _store.update(
          BankCardRecord(
            id: existing.id,
            code: existing.code,
            name: name,
            nameKey: '',
            balanceTl: existing.balanceTl,
            balanceUsd: existing.balanceUsd,
            balanceIqd: existing.balanceIqd,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.bank_card_save_failed')),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BankCardRecord record) async {
    final l10n = AppLocalization.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.bank_card_delete'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          l10n.translate(
            'field_sales.bank_card_delete_confirm',
            args: {'code': record.code},
          ),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('common.delete')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _store.softDelete(record.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.bank_card_list'),
        backgroundColor: primary,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('field_sales.bank_card_create'),
            onPressed: () => _showEditor(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('common.search'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: _applyFilter,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('field_sales.bank_card_empty'),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final row = _filtered[index];
                          final record = _recordOf(row);
                          return InkWell(
                            onTap: record == null
                                ? null
                                : () => _showEditor(existing: record),
                            onLongPress: record == null
                                ? null
                                : () => _confirmDelete(record),
                            child: _BankCardDensTile(
                              option: row,
                              label: row.label(l10n),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// {@template bank_card_dens_tile}
/// Banka dens kartı — kod · ünvan · TL/USD/IQD bakiyeler.
/// {@endtemplate}
class _BankCardDensTile extends StatelessWidget {
  final BankCardOption option;
  final String label;

  const _BankCardDensTile({
    required this.option,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Text(
                BankCardOption.formatAmount(option.balanceTl),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.translate('field_sales.balance_tl')}: '
            '${BankCardOption.formatAmount(option.balanceTl)}  ·  '
            '${l10n.translate('field_sales.balance_usd')}: '
            '${BankCardOption.formatAmount(option.balanceUsd)}  ·  '
            '${l10n.translate('field_sales.balance_iqd')}: '
            '${BankCardOption.formatAmount(option.balanceIqd)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
