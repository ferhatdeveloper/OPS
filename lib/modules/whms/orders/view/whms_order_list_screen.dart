// Dosya Adı: whms_order_list_screen.dart
// Açıklama: WHMS /whms/orders dens emir listesi — tip/durum chip + store
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../contract/whms_route_map.dart';
import '../../viewmodel/whms_order_store.dart';
import '../model/whms_order.dart';
import 'whms_order_create_screen.dart';
import 'whms_order_detail_screen.dart';
import 'widgets/whms_order_empty_state.dart';
import 'widgets/whms_order_list_tile.dart';

/// Dönem preset (Bugün / Bu Hafta / Bu Ay / Bu Yıl).
enum WhmsOrderPeriod {
  /// [today]: Bugün
  today,

  /// [thisWeek]: Bu hafta
  thisWeek,

  /// [thisMonth]: Bu ay
  thisMonth,

  /// [thisYear]: Bu yıl
  thisYear,
}

/// {@template whms_order_list_screen}
/// Merkez depo emir dens listesi.
/// Route: `/whms/orders`
///
/// Filtre: tip + durum (+ dönem) — tek tip dens chip.
/// Kaynak: [WhmsOrderListSource] → [WhmsOrderStore].
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsOrderListScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsOrderListScreen extends StatefulWidget {
  /// Named route — [WhmsRouteMap.whmsOrders]
  static const String routeName = WhmsRouteMap.whmsOrders;

  /// Tek liste kaynağı (test inject)
  final WhmsOrderListSource? source;

  /// Store inject (source yoksa sarılır)
  final WhmsOrderStore? store;

  /// Test satırları (loader atlanır)
  final List<WhmsOrderDto>? initialRows;

  /// {@macro whms_order_list_screen}
  const WhmsOrderListScreen({
    super.key,
    this.source,
    this.store,
    this.initialRows,
  });

  @override
  State<WhmsOrderListScreen> createState() => _WhmsOrderListScreenState();
}

class _WhmsOrderListScreenState extends State<WhmsOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final WhmsOrderListSource _source = widget.source ??
      WhmsOrderListSource(
        store: widget.store ?? const WhmsOrderStore(),
      );

  WhmsOrderType? _typeFilter;
  WhmsOrderStatus? _statusFilter;
  WhmsOrderPeriod _period = WhmsOrderPeriod.thisMonth;

  List<WhmsOrderDto> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRows != null) {
      _rows = _applyLocal(widget.initialRows!);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  (DateTime from, DateTime to) _periodRange(WhmsOrderPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    switch (period) {
      case WhmsOrderPeriod.today:
        return (today, end);
      case WhmsOrderPeriod.thisWeek:
        final from = today.subtract(Duration(days: today.weekday - 1));
        return (from, end);
      case WhmsOrderPeriod.thisMonth:
        return (DateTime(today.year, today.month, 1), end);
      case WhmsOrderPeriod.thisYear:
        return (DateTime(today.year, 1, 1), end);
    }
  }

  List<WhmsOrderDto> _applyLocal(List<WhmsOrderDto> source) {
    final range = _periodRange(_period);
    final q = _searchController.text.trim().toLowerCase();
    return source.where((o) {
      final parsed = DateTime.tryParse(o.orderDate.trim());
      if (parsed != null) {
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isBefore(range.$1) || day.isAfter(range.$2)) return false;
      }
      if (q.isEmpty) return true;
      final code = WhmsOrderListTile.displayCode(o).toLowerCase();
      final wh = (o.warehouseCode ?? '').toLowerCase();
      final notes = (o.notes ?? '').toLowerCase();
      return code.contains(q) || wh.contains(q) || notes.contains(q);
    }).toList(growable: false);
  }

  /// {@template whms_order_list_load}
  /// Tip/durum store’dan; dönem + arama yerelde.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    final range = _periodRange(_period);
    try {
      final list = await _source.list(
        type: _typeFilter,
        status: _statusFilter,
        from: range.$1,
        to: range.$2,
        query: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    if (widget.initialRows != null) {
      setState(() => _rows = _applyLocal(widget.initialRows!));
      return;
    }
    _load();
  }

  void _openDetail(WhmsOrderDto order) {
    if (order.orderType == WhmsOrderType.pick) {
      Navigator.pushNamed(
        context,
        WhmsRouteMap.whmsPick,
        arguments: order.id,
      );
      return;
    }
    Navigator.pushNamed(
      context,
      WhmsOrderDetailScreen.routeName,
      arguments: order.id,
    );
  }

  Future<void> _openCreate() async {
    await Navigator.pushNamed(
      context,
      WhmsOrderCreateScreen.routeName,
    );
    if (!mounted) return;
    if (widget.initialRows == null) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterBg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF8F9FD);

    final typeItems = <FieldSalesDensChipItem>[
      FieldSalesDensChipItem(
        label: l10n.translate('whms.orders.filter_all'),
        selected: _typeFilter == null,
        onTap: () {
          if (_typeFilter == null) return;
          setState(() => _typeFilter = null);
          _load();
        },
      ),
      for (final t in const [
        WhmsOrderType.malKabul,
        WhmsOrderType.pick,
        WhmsOrderType.sevk,
        WhmsOrderType.transfer,
      ])
        FieldSalesDensChipItem(
          label: l10n.translate(t.l10nKey),
          selected: _typeFilter == t,
          onTap: () {
            if (_typeFilter == t) return;
            setState(() => _typeFilter = t);
            _load();
          },
        ),
    ];

    final statusItems = <FieldSalesDensChipItem>[
      FieldSalesDensChipItem(
        label: l10n.translate('whms.orders.filter_all_status'),
        selected: _statusFilter == null,
        onTap: () {
          if (_statusFilter == null) return;
          setState(() => _statusFilter = null);
          _load();
        },
      ),
      for (final s in const [
        WhmsOrderStatus.draft,
        WhmsOrderStatus.inProgress,
        WhmsOrderStatus.done,
      ])
        FieldSalesDensChipItem(
          label: l10n.translate(s.l10nKey),
          selected: _statusFilter == s,
          onTap: () {
            if (_statusFilter == s) return;
            setState(() => _statusFilter = s);
            _load();
          },
        ),
    ];

    final periodEntries = <(WhmsOrderPeriod, String)>[
      (WhmsOrderPeriod.today, 'field_sales.period_today'),
      (WhmsOrderPeriod.thisWeek, 'field_sales.period_this_week'),
      (WhmsOrderPeriod.thisMonth, 'field_sales.period_this_month'),
      (WhmsOrderPeriod.thisYear, 'field_sales.period_this_year'),
    ];

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.orders.title'),
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('whms.orders.create'),
            onPressed: _loading ? null : _openCreate,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            tooltip: l10n.translate('common.reload'),
            onPressed: _loading ? null : _load,
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          backgroundColor: filterBg,
          children: [
            FieldSalesDensChipRow(
              fontSize: 11,
              items: typeItems,
            ),
            FieldSalesDensChipRow(
              fontSize: 11,
              items: statusItems,
            ),
            FieldSalesDensChipRow(
              fontSize: 11,
              items: [
                for (final entry in periodEntries)
                  FieldSalesDensChipItem(
                    label: l10n.translate(entry.$2),
                    selected: _period == entry.$1,
                    onTap: () {
                      if (_period == entry.$1) return;
                      setState(() => _period = entry.$1);
                      if (widget.initialRows != null) {
                        setState(
                          () => _rows = _applyLocal(widget.initialRows!),
                        );
                      } else {
                        _load();
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('whms.orders.search_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
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
                : _rows.isEmpty
                    ? const WhmsOrderEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return WhmsOrderListTile(
                            order: row,
                            onTap: () => _openDetail(row),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
