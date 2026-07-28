// Dosya Adı: whms_warehouse_list_screen.dart
// Açıklama: WHMS /whms/warehouses — MultiWarehouse dens reuse + WHMS başlık
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../field_sales/stock/model/warehouse_dens_row.dart';
import '../../field_sales/stock/viewmodel/warehouse_master_store.dart';
import '../contract/whms_route_map.dart';

/// {@template whms_warehouse_list_screen}
/// Merkez ambar dens listesi — mevcut `warehouses` store (ERP zorunlu değil).
/// Route: `/whms/warehouses`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsWarehouseListScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsWarehouseListScreen extends StatefulWidget {
  /// Named route — `/whms/warehouses`
  static const String routeName = WhmsRouteMap.whmsMultiWarehouse;

  /// Opsiyonel satır enjeksiyonu (test)
  final List<WarehouseDensRow>? rows;

  /// Store enjeksiyonu (test)
  final WarehouseMasterStore? store;

  /// {@macro whms_warehouse_list_screen}
  const WhmsWarehouseListScreen({
    super.key,
    this.rows,
    this.store,
  });

  @override
  State<WhmsWarehouseListScreen> createState() =>
      _WhmsWarehouseListScreenState();
}

class _WhmsWarehouseListScreenState extends State<WhmsWarehouseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WarehouseDensRow> _all = const [];
  List<WarehouseDensRow> _filtered = const [];
  bool _loading = true;

  WarehouseMasterStore get _store =>
      widget.store ?? const WarehouseMasterStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WarehouseDensRow>.from(widget.rows!);
      _filtered = List<WarehouseDensRow>.from(_all);
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

  /// {@template whms_warehouse_list_screen_load}
  /// Ambar dens satırlarını yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _store.ensureReady();
      final records = await _store.listActive();
      final rows = records.map((r) => r.toDensRow()).toList(growable: false);
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

  /// {@template whms_warehouse_list_screen_apply_filter}
  /// Kod / ad araması.
  ///
  /// Parametreler:
  /// - [q]: Arama metni
  /// {@endtemplate}
  void _applyFilter(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) {
      _filtered = List<WarehouseDensRow>.from(_all);
      return;
    }
    _filtered = _all.where((r) {
      final hay = '${r.code} ${r.name} ${r.type}'.toLowerCase();
      return hay.contains(needle);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.menu.sub_whms_warehouses'),
        showCalculatorHome: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _applyFilter(v)),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('whms.warehouses.search_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
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
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                        child: Text(
                          l10n.translate('whms.warehouses.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: FieldSalesDensTheme.muted(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final r = _filtered[index];
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
                                        r.code,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: FieldSalesDensTheme.title(context),
                                        ),
                                      ),
                                      Text(
                                        r.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: FieldSalesDensTheme.muted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  l10n.translate(r.typeNameKey),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: FieldSalesDensTheme.muted(context),
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
