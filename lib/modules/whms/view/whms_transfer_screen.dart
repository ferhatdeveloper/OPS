// Dosya Adı: whms_transfer_screen.dart
// Açıklama: WHMS /whms/transfer dens — yerel transfer emirleri (OPS ekranı değil)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import '../model/whms_order_dto.dart';
import '../model/whms_order_type.dart';
import '../orders/view/whms_order_detail_screen.dart';
import '../orders/view/widgets/whms_order_list_tile.dart';
import '../viewmodel/whms_order_store.dart';
import 'whms_transfer_create_screen.dart';

/// {@template whms_transfer_screen}
/// Merkez depo transfer emir dens listesi — `WhmsOrderType.transfer`.
/// Route: `/whms/transfer` (field_sales transfer ekranına gitmez).
/// {@endtemplate}
class WhmsTransferScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsTransfer;

  /// [store]: Test
  final WhmsOrderStore? store;

  /// [rows]: Test
  final List<WhmsOrderDto>? rows;

  /// {@macro whms_transfer_screen}
  const WhmsTransferScreen({
    super.key,
    this.store,
    this.rows,
  });

  @override
  State<WhmsTransferScreen> createState() => _WhmsTransferScreenState();
}

class _WhmsTransferScreenState extends State<WhmsTransferScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsOrderDto> _all = const [];
  List<WhmsOrderDto> _filtered = const [];
  bool _loading = true;

  WhmsOrderStore get _store => widget.store ?? const WhmsOrderStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WhmsOrderDto>.from(widget.rows!);
      _filtered = List<WhmsOrderDto>.from(_all);
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
    setState(() => _loading = true);
    try {
      final rows = await _store.list(type: WhmsOrderType.transfer);
      if (!mounted) return;
      setState(() {
        _all = rows;
        _applyFilter(_searchController.text);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = const [];
        _filtered = const [];
        _loading = false;
      });
    }
  }

  void _applyFilter(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) {
      _filtered = List<WhmsOrderDto>.from(_all);
      return;
    }
    _filtered = _all.where((o) {
      final hay = [
        o.id,
        o.referenceNo ?? '',
        o.fromWarehouseCode ?? '',
        o.toWarehouseCode ?? '',
        o.warehouseCode ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(needle);
    }).toList(growable: false);
  }

  Future<void> _createDraft() async {
    final order = await Navigator.of(context).push<WhmsOrderDto>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WhmsTransferCreateScreen(store: widget.store),
      ),
    );
    if (!mounted || order == null) return;
    await Navigator.pushNamed(
      context,
      WhmsOrderDetailScreen.routeName,
      arguments: order,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.menu.sub_whms_transfer'),
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('whms.transfer.create'),
            onPressed: _createDraft,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              onChanged: (q) => setState(() => _applyFilter(q)),
              decoration: InputDecoration(
                hintText: l10n.translate('whms.transfer.search_hint'),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
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
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('whms.transfer.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final o = _filtered[i];
                          return WhmsOrderListTile(
                            order: o,
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                WhmsOrderDetailScreen.routeName,
                                arguments: o.id,
                              );
                              await _load();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
