// Dosya Adı: whms_count_screen.dart
// Açıklama: Merkez sayım emirleri dens liste (SQLite store)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/stock/model/warehouse_master_seed.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_count_order.dart';
import '../viewmodel/whms_count_order_store.dart';
import 'whms_count_execute_screen.dart';

/// {@template whms_count_screen}
/// `/whms/count` — sayım emir dens listesi; satır → yürütme.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsCountScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsCountScreen extends StatefulWidget {
  /// Named route — `/whms/count`
  static const String routeName = WhmsRouteMap.whmsCount;

  /// Opsiyonel satır enjeksiyonu (test)
  final List<WhmsCountOrder>? rows;

  /// Store enjeksiyonu (test)
  final WhmsCountOrderStore? store;

  /// {@macro whms_count_screen}
  const WhmsCountScreen({
    Key? key,
    this.rows,
    this.store,
  }) : super(key: key);

  @override
  State<WhmsCountScreen> createState() => _WhmsCountScreenState();
}

class _WhmsCountScreenState extends State<WhmsCountScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsCountOrder> _all = const [];
  List<WhmsCountOrder> _filtered = const [];
  bool _loading = true;

  WhmsCountOrderStore get _store =>
      widget.store ?? const WhmsCountOrderStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WhmsCountOrder>.from(widget.rows!);
      _filtered = List<WhmsCountOrder>.from(_all);
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

  Future<void> _load() async {
    try {
      await _store.ensureReady();
      final rows = await _store.list();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _applyFilter(_searchController.text, notify: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter(String query, {bool notify = true}) {
    final q = query.trim().toLowerCase();
    final next = q.isEmpty
        ? List<WhmsCountOrder>.from(_all)
        : _all
            .where((o) {
              return o.id.toLowerCase().contains(q) ||
                  o.warehouseCode.toLowerCase().contains(q) ||
                  (o.locationCode ?? '').toLowerCase().contains(q) ||
                  o.status.name.toLowerCase().contains(q);
            })
            .toList(growable: false);
    if (notify) {
      setState(() => _filtered = next);
    } else {
      _filtered = next;
    }
  }

  Future<void> _createDraft() async {
    final l10n = AppLocalization.of(context);
    final whCtrl = TextEditingController(
      text: WarehouseMasterSeed.defaultRows.first.code,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.translate('whms.count.create'),
            style: const TextStyle(fontSize: 16),
          ),
          content: TextField(
            controller: whCtrl,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.translate('whms.count.warehouse'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
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
        );
      },
    );

    final wh = whCtrl.text.trim();
    whCtrl.dispose();

    if (saved != true || !mounted || wh.isEmpty) return;

    try {
      final order = await _store.insertDraft(warehouseCode: wh);
      await _load();
      if (!mounted) return;
      await _openExecute(order);
    } catch (_) {}
  }

  Future<void> _openExecute(WhmsCountOrder order) async {
    final changed = await Navigator.pushNamed(
      context,
      WhmsCountExecuteScreen.routeName,
      arguments: order,
    );
    if (changed == true || changed == null) {
      await _load();
    }
  }

  Future<void> _softDelete(WhmsCountOrder order) async {
    await _store.softDelete(order.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('whms.count.title');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('whms.count.create'),
            onPressed: _loading ? null : _createDraft,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _applyFilter,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('whms.count.search_hint'),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('whms.count.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                FieldSalesDensTheme.muted(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final order = _filtered[index];
                          return _CountOrderRow(
                            order: order,
                            statusLabel:
                                l10n.translate('whms.count.status'),
                            onOpen: () => _openExecute(order),
                            onDelete: () => _softDelete(order),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CountOrderRow extends StatelessWidget {
  final WhmsCountOrder order;
  final String statusLabel;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const _CountOrderRow({
    required this.order,
    required this.statusLabel,
    this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = order.locationCode;
    final subtitle = loc == null || loc.isEmpty
        ? order.warehouseCode
        : '${order.warehouseCode} · $loc';
    final date = order.orderDate.toIso8601String().split('T').first;

    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FieldSalesDensTheme.title(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$date · $statusLabel: ${order.status.name}'
                      ' · ONAY=${order.approval.name}',
                      style: TextStyle(
                        fontSize: 11,
                        color: FieldSalesDensTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: FieldSalesDensTheme.muted(context),
              ),
              if (onDelete != null)
                FieldSalesDensAppBar.densIconButton(
                  icon: Icons.delete_outline,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
