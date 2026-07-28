// Dosya Adı: warehouse_stock_query_screen.dart
// Açıklama: Ambar stok sorgu dens — yerel bakiye port + chip filtre
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/warehouse_master_seed.dart';
import '../viewmodel/warehouse_stock_query_store.dart';

/// {@template warehouse_stock_query_screen}
/// Ambar stok sorgulama dens listesi — `warehouse_stocks` / `vehicle_stocks`.
///
/// Rota: `/field-sales/warehouse-stock-query`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WarehouseStockQueryScreen.routeName,
/// );
/// ```
/// {@endtemplate}
class WarehouseStockQueryScreen extends StatefulWidget {
  /// [routeName]: Named route yolu
  static const String routeName = '/field-sales/warehouse-stock-query';

  /// [store]: Test enjeksiyonu
  final WarehouseStockQueryStore? store;

  /// [initialRows]: Test / senkron dens satırlar
  final List<WarehouseStockQueryRow>? initialRows;

  /// [initialWarehouseCode]: İlk seçili ambar
  final String? initialWarehouseCode;

  /// {@macro warehouse_stock_query_screen}
  const WarehouseStockQueryScreen({
    Key? key,
    this.store,
    this.initialRows,
    this.initialWarehouseCode,
  }) : super(key: key);

  @override
  State<WarehouseStockQueryScreen> createState() =>
      _WarehouseStockQueryScreenState();
}

class _WarehouseStockQueryScreenState extends State<WarehouseStockQueryScreen> {
  late String _warehouseCode;
  final TextEditingController _searchCtrl = TextEditingController();
  List<WarehouseStockQueryRow> _allRows = const [];
  List<WarehouseStockQueryRow> _rows = const [];
  bool _loading = true;

  WarehouseStockQueryStore get _store =>
      widget.store ?? const WarehouseStockQueryStore();

  @override
  void initState() {
    super.initState();
    _warehouseCode = (widget.initialWarehouseCode ??
            WarehouseMasterSeed.defaultRows.first.code)
        .trim()
        .toUpperCase();
    final injected = widget.initialRows;
    if (injected != null) {
      _allRows = injected;
      _rows = _filter(injected, _searchCtrl.text);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WarehouseStockQueryRow> _filter(
    List<WarehouseStockQueryRow> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((r) {
          final hay =
              '${r.productCode} ${r.productName} ${r.productId}'.toLowerCase();
          return hay.contains(q);
        })
        .toList(growable: false);
  }

  void _applySearch() {
    setState(() => _rows = _filter(_allRows, _searchCtrl.text));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _store.listForWarehouse(_warehouseCode);
      if (!mounted) return;
      setState(() {
        _allRows = rows;
        _rows = _filter(rows, _searchCtrl.text);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allRows = const [];
        _rows = const [];
        _loading = false;
      });
    }
  }

  String _warehouseLabel(AppLocalization l10n, String code) {
    final seed = WarehouseMasterSeed.byCode(code);
    if (seed != null) return l10n.translate(seed.nameKey);
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final codes = _store.warehouseCodes();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.warehouse_stock_query'),
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              items: [
                for (final code in codes)
                  FieldSalesDensChipItem(
                    label: _warehouseLabel(l10n, code),
                    selected: _warehouseCode == code,
                    onTap: () {
                      if (_warehouseCode == code) return;
                      setState(() => _warehouseCode = code);
                      _load();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              onChanged: (_) => _applySearch(),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('field_sales.stock_query.search_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('field_sales.stock_slip.code'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    l10n.translate('field_sales.stock_query.qty'),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.translate('field_sales.stock_query.empty'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F1B24)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: FieldSalesDensAppBar.primaryColor
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.productCode,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        row.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  row.quantity.toStringAsFixed(
                                    row.quantity == row.quantity.roundToDouble()
                                        ? 0
                                        : 2,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
