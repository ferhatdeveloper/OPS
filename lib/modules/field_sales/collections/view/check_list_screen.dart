// Dosya Adı: check_list_screen.dart
// Açıklama: MBT Çek Listesi dens — collections check tipi + durum sekmeleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/check_list_row.dart';
import '../model/check_list_seed.dart';
import '../model/check_list_status.dart';
import '../model/collection_model.dart';
import '../viewmodel/check_list_store.dart';

/// {@template check_list_screen}
/// Çek Listesi dens ekranı — `payment_type=check` collections.
///
/// MBT durum sekmeleri: teminata, tahsile, iade, tahsil edilen,
/// karşılıksız, tahsil edilemeyen, ödenen/verilen firma çekleri.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CheckListScreen.routeName);
/// // veya collections → dens:
/// CheckListScreen.fromCollections(models);
/// ```
/// {@endtemplate}
class CheckListScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/checks`
  static const String routeName = '/field-sales/checks';

  /// [rows]: Opsiyonel dens satırlar (null → [CheckListStore])
  final List<CheckListRow>? rows;

  /// Store enjeksiyonu (test)
  final CheckListStore? store;

  /// {@macro check_list_screen}
  const CheckListScreen({
    super.key,
    this.rows,
    this.store,
  });

  /// {@template check_list_screen_from_collections}
  /// Collections listesinden yalnızca check tipi dens ekranı.
  /// {@endtemplate}
  factory CheckListScreen.fromCollections(
    List<CollectionModel> collections, {
    Key? key,
  }) {
    return CheckListScreen(
      key: key,
      rows: CheckListRow.fromCollections(collections),
    );
  }

  @override
  State<CheckListScreen> createState() => _CheckListScreenState();
}

class _CheckListScreenState extends State<CheckListScreen>
    with SingleTickerProviderStateMixin {
  /// [_searchController]: Durum listesi arama alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_tabController]: Durum sekmeleri denetleyicisi
  late TabController _tabController;

  /// [_source]: Check tipi dens kaynak satırlar
  late List<CheckListRow> _source;

  CheckListStore get _store => widget.store ?? const CheckListStore();

  @override
  void initState() {
    super.initState();
    _source = List<CheckListRow>.from(
      widget.rows ?? CheckListSeed.defaultRows,
    );
    _tabController = TabController(
      length: CheckListStatus.tabs.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    if (widget.rows == null) {
      _loadFromStore();
    }
  }

  Future<void> _loadFromStore() async {
    try {
      final rows = await _store.listActive();
      if (!mounted || rows.isEmpty) return;
      setState(() => _source = List<CheckListRow>.from(rows));
    } catch (_) {
      // seed fallback
    }
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalization.of(context);
    final customerCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.check_create'),
          style: const TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
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
                  labelText: l10n.translate('field_sales.check_customer_id'),
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
                  labelText: l10n.translate('field_sales.check_number'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                textCapitalization: TextCapitalization.none,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.translate('field_sales.check_amount'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bankCtrl,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.translate('field_sales.check_bank'),
                ),
              ),
            ],
          ),
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
    final bank = bankCtrl.text.trim();
    customerCtrl.dispose();
    numberCtrl.dispose();
    amountCtrl.dispose();
    bankCtrl.dispose();
    if (ok != true || !mounted) return;
    if (customerId.isEmpty || number.isEmpty || amount <= 0) return;
    await _store.create(
      customerId: customerId,
      amount: amount,
      checkNumber: number,
      bankName: bank.isEmpty ? null : bank,
      status: _activeStatus,
    );
    await _loadFromStore();
  }

  Future<void> _softDelete(CheckListRow row) async {
    final l10n = AppLocalization.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.check_delete'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          l10n.translate(
            'field_sales.check_delete_confirm',
            args: {'no': row.checkNumber},
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
  void didUpdateWidget(covariant CheckListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _source = List<CheckListRow>.from(
        widget.rows ?? CheckListSeed.defaultRows,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// {@template _active_status}
  /// Seçili sekme durumu.
  /// {@endtemplate}
  CheckListStatus get _activeStatus {
    final i = _tabController.index.clamp(0, CheckListStatus.tabs.length - 1);
    return CheckListStatus.tabs[i];
  }

  /// {@template _filtered}
  /// Aktif durum + arama süzgeçli dens satırlar.
  /// {@endtemplate}
  List<CheckListRow> get _filtered {
    return CheckListRow.filter(
      _source,
      status: _activeStatus,
      query: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color appBarBlue = Color(0xFF375A7F);
    final filtered = _filtered;
    final totalText = CheckListRow.formatAmount(
      CheckListRow.totalAmount(filtered),
    );
    final countText = '${filtered.length}';

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.check_list'),
        backgroundColor: appBarBlue,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('field_sales.check_create'),
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
              for (final status in CheckListStatus.tabs)
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
                for (final status in CheckListStatus.tabs)
                  _buildStatusBody(l10n, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// {@template _buildStatusBody}
  /// Durum sekmesi dens liste veya boş durum.
  /// {@endtemplate}
  Widget _buildStatusBody(AppLocalization l10n, CheckListStatus status) {
    final rows = CheckListRow.filter(
      _source,
      status: status,
      query: _searchController.text,
    );
    if (rows.isEmpty) {
      return _buildStatusEmpty(l10n, status);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final row = rows[index];
        return InkWell(
          onLongPress:
              widget.rows == null ? () => _softDelete(row) : null,
          child: _CheckDensTile(row: row),
        );
      },
    );
  }

  /// {@template _buildStatusEmpty}
  /// Seçili durum için boş dens görünümü.
  /// {@endtemplate}
  Widget _buildStatusEmpty(AppLocalization l10n, CheckListStatus status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate(status.l10nKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('field_sales.check_list_empty'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('field_sales.check_list_stub_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate(
                'field_sales.check_total_label',
                args: {'amount': '0,00'},
              ),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              l10n.translate(
                'field_sales.check_count_label',
                args: {'count': '0'},
              ),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template _check_dens_tile}
/// Çek dens satır kartı (çek no · banka · tutar · vade).
/// {@endtemplate}
class _CheckDensTile extends StatelessWidget {
  /// [row]: Dens satır
  final CheckListRow row;

  /// {@macro _check_dens_tile}
  const _CheckDensTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final due = row.dueDate;
    final dueText = due == null
        ? ''
        : '${due.day.toString().padLeft(2, '0')}.'
            '${due.month.toString().padLeft(2, '0')}.'
            '${due.year}';
    final subtitleParts = <String>[
      if ((row.bankName ?? '').isNotEmpty) row.bankName!,
      if ((row.customerName ?? row.customerId).isNotEmpty)
        (row.customerName ?? row.customerId),
      if (dueText.isNotEmpty)
        l10n.translate(
          'field_sales.due_date_prefix',
          args: {'date': dueText},
        ),
    ];

    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.checkNumber.isEmpty
                          ? (row.documentNo ?? row.id)
                          : row.checkNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
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
                CheckListRow.formatAmount(row.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
