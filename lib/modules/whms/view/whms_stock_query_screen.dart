// Dosya Adı: whms_stock_query_screen.dart
// Açıklama: WHMS /whms/stock-query dens — yerel ambar bakiyesi (OPS ekranı değil)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../core/database/migrations/SqlQuerys.dart';
import '../../../core/localization/app_localization.dart';
import '../../../service/database_service.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import '../../field_sales/stock/model/warehouse_master_seed.dart';
import '../contract/stock_balance.dart';
import '../contract/whms_route_map.dart';
import '../data/local_warehouse_stock_balance_port.dart';

/// {@template whms_stock_query_screen}
/// Merkez stok sorgu dens — `warehouse_stocks` yerel bakiye.
/// Route: `/whms/stock-query`
/// {@endtemplate}
class WhmsStockQueryScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsStockQuery;

  /// [rows]: Test inject
  final List<StockBalance>? rows;

  /// {@macro whms_stock_query_screen}
  const WhmsStockQueryScreen({
    super.key,
    this.rows,
  });

  @override
  State<WhmsStockQueryScreen> createState() => _WhmsStockQueryScreenState();
}

class _WhmsStockQueryScreenState extends State<WhmsStockQueryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _warehouseCode = WarehouseMasterSeed.defaultRows.first.code;
  List<StockBalance> _all = const [];
  List<StockBalance> _filtered = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<StockBalance>.from(widget.rows!);
      _filtered = List<StockBalance>.from(_all);
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
      final svc = await DatabaseService.getInstance();
      final db = await svc.getDatabase();
      await db.execute(SqlQuerys.createWarehouseStocksTable);
      final port = LocalWarehouseStockBalancePort(db);
      final rows = await port.listByWarehouse(warehouseCode: _warehouseCode);
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
      _filtered = List<StockBalance>.from(_all);
      return;
    }
    _filtered = _all.where((b) {
      return b.productId.toLowerCase().contains(needle) ||
          b.warehouseCode.toLowerCase().contains(needle);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final chips = WarehouseMasterSeed.defaultRows
        .map(
          (s) => FieldSalesDensChipItem(
            label: s.code,
            selected: _warehouseCode == s.code,
            onTap: () {
              if (_warehouseCode == s.code) return;
              setState(() => _warehouseCode = s.code);
              _load();
            },
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.menu.sub_whms_query'),
        showCalculatorHome: false,
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(items: chips),
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
              onChanged: (q) => setState(() => _applyFilter(q)),
              decoration: InputDecoration(
                hintText: l10n.translate('whms.stock_query.search_hint'),
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
                          l10n.translate('whms.stock_query.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: FieldSalesDensTheme.muted(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final b = _filtered[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: FieldSalesDensTheme.surface(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.productId,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: FieldSalesDensTheme.title(context),
                                        ),
                                      ),
                                      Text(
                                        '${b.warehouseCode} · ${b.source}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: FieldSalesDensTheme.muted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  b.quantity.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        FieldSalesDensTheme.title(context),
                                  ),
                                ),
                              ],
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
