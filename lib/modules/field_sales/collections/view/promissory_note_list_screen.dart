// Dosya Adı: promissory_note_list_screen.dart
// Açıklama: MBT Senet Listesi dens — portföy kategorileri Toplam/Adet
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/promissory_list_row.dart';
import '../model/promissory_list_seed.dart';
import '../model/promissory_list_status.dart';
import '../viewmodel/promissory_list_store.dart';

/// {@template promissory_note_list_screen}
/// Senet Listesi dens ekranı — çek listesi ile parity.
/// Route: `/field-sales/promissory-list`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, PromissoryNoteListScreen.routeName);
/// ```
/// {@endtemplate}
class PromissoryNoteListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/promissory-list';

  /// Opsiyonel dens satırlar (null → store)
  final List<PromissoryListRow>? rows;

  /// Store enjeksiyonu (test)
  final PromissoryListStore? store;

  /// {@macro promissory_note_list_screen}
  const PromissoryNoteListScreen({
    super.key,
    this.rows,
    this.store,
  });

  @override
  State<PromissoryNoteListScreen> createState() =>
      _PromissoryNoteListScreenState();
}

class _PromissoryNoteListScreenState extends State<PromissoryNoteListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late List<PromissoryListRow> _source;

  PromissoryListStore get _store =>
      widget.store ?? const PromissoryListStore();

  @override
  void initState() {
    super.initState();
    _source = List<PromissoryListRow>.from(
      widget.rows ?? PromissoryListSeed.defaultRows,
    );
    _tabController = TabController(
      length: PromissoryListStatus.tabs.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    if (widget.rows == null) {
      _loadFromStore();
    }
  }

  Future<void> _loadFromStore() async {
    try {
      final rows = await _store.listActive();
      if (!mounted || rows.isEmpty) return;
      setState(() => _source = List<PromissoryListRow>.from(rows));
    } catch (_) {}
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalization.of(context);
    final customerCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.promissory_create'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerCtrl,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.translate('field_sales.promissory_customer_id'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: numberCtrl,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.translate('field_sales.promissory_number'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              textCapitalization: TextCapitalization.none,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.translate('field_sales.promissory_amount'),
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
      ),
    );
    final customerId = customerCtrl.text.trim();
    final number = numberCtrl.text.trim();
    final amount = double.tryParse(
          amountCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    customerCtrl.dispose();
    numberCtrl.dispose();
    amountCtrl.dispose();
    if (ok != true || !mounted) return;
    if (customerId.isEmpty || number.isEmpty || amount <= 0) return;
    await _store.create(
      customerId: customerId,
      amount: amount,
      noteNumber: number,
      status: _activeStatus,
    );
    await _loadFromStore();
  }

  Future<void> _softDelete(PromissoryListRow row) async {
    final l10n = AppLocalization.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.promissory_delete'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          l10n.translate(
            'field_sales.promissory_delete_confirm',
            args: {'no': row.noteNumber},
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
    await _store.softDelete(row.id);
    await _loadFromStore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  PromissoryListStatus get _activeStatus {
    final i = _tabController.index.clamp(
      0,
      PromissoryListStatus.tabs.length - 1,
    );
    return PromissoryListStatus.tabs[i];
  }

  List<PromissoryListRow> get _filtered {
    return PromissoryListRow.filter(
      _source,
      status: _activeStatus,
      query: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color appBarBlue = FieldSalesDensAppBar.primaryColor;
    final filtered = _filtered;
    final totalText = PromissoryListRow.formatAmount(
      PromissoryListRow.totalAmount(filtered),
    );
    final countText = '${filtered.length}';

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.promissory_list'),
        backgroundColor: appBarBlue,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('field_sales.promissory_create'),
            onPressed: widget.rows == null ? _showCreateDialog : null,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 11,
            ),
            tabs: [
              for (final status in PromissoryListStatus.tabs)
                Tab(
                  height: 32,
                  text: l10n.translate(status.l10nKey),
                ),
            ],
          ),
        ),
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
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 32,
                ),
                filled: true,
                fillColor: FieldSalesDensTheme.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate(
                      'field_sales.check_total_label',
                      args: {'amount': totalText},
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Text(
                  l10n.translate(
                    'field_sales.check_count_label',
                    args: {'count': countText},
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final status in PromissoryListStatus.tabs)
                  _buildStatusBody(l10n, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBody(
    AppLocalization l10n,
    PromissoryListStatus status,
  ) {
    final rows = PromissoryListRow.filter(
      _source,
      status: status,
      query: _searchController.text,
    );
    if (rows.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('field_sales.promissory_list_empty'),
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final row = rows[index];
        final due = row.dueDate;
        final dueText = due == null
            ? ''
            : '${due.day.toString().padLeft(2, '0')}.'
                '${due.month.toString().padLeft(2, '0')}.'
                '${due.year}';
        final subtitle = <String>[
          if ((row.bankName ?? '').isNotEmpty) row.bankName!,
          if ((row.customerName ?? row.customerId).isNotEmpty)
            (row.customerName ?? row.customerId),
          if (dueText.isNotEmpty) dueText,
        ].join(' · ');

        return InkWell(
          onLongPress:
              widget.rows == null ? () => _softDelete(row) : null,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: FieldSalesDensTheme.surface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.noteNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                PromissoryListRow.formatAmount(row.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }
}
