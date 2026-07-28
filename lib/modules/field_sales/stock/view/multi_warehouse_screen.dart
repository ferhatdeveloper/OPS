// Dosya Adı: multi_warehouse_screen.dart
// Açıklama: Çoklu ambar dens listesi — SQLite CRUD + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/warehouse_dens_row.dart';
import '../model/warehouse_master_seed.dart';
import '../viewmodel/warehouse_master_store.dart';

/// {@template multi_warehouse_screen}
/// Çoklu ambar dens listesi — SQLite `warehouses` CRUD (WHMS değil).
///
/// Dens alanlar: Kod · Ad · Tip. Create / Update / Soft-delete.
/// Rota: `/field-sales/multi-warehouse`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, MultiWarehouseScreen.routeName);
/// MultiWarehouseScreen(rows: WarehouseDensRow.fromSeed());
/// ```
/// {@endtemplate}
class MultiWarehouseScreen extends StatefulWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/multi-warehouse';

  /// [rows]: Opsiyonel dens satırlar (null → SQLite / seed)
  final List<WarehouseDensRow>? rows;

  /// [store]: Test enjeksiyonu
  final WarehouseMasterStore? store;

  const MultiWarehouseScreen({
    Key? key,
    this.rows,
    this.store,
  }) : super(key: key);

  /// {@template multi_warehouse_apply_dens_cache}
  /// Test / senkron: warehouses map listesinden dens önbellek.
  /// {@endtemplate}
  static int applyDensCacheFromMaps(List<Map<String, dynamic>> maps) {
    densRows = WarehouseDensRow.fromWarehouseMaps(maps);
    densCount = densRows.length;
    return densCount;
  }

  /// Son yüklenen dens satırlar (önbellek).
  static List<WarehouseDensRow> densRows = const [];

  /// Dashboard / menü için dens adet (önbellek).
  static int densCount = 0;

  /// {@template multi_warehouse_refresh_dens_cache}
  /// SQLite `warehouses` dens önbelleği (soft-delete hariç).
  /// {@endtemplate}
  static Future<int> refreshDensCache({WarehouseMasterStore? store}) async {
    try {
      final s = store ?? const WarehouseMasterStore();
      final records = await s.listActive();
      densRows = records.map((r) => r.toDensRow()).toList(growable: false);
      densCount = densRows.length;
      if (densCount == 0) {
        return applyDensCacheFromMaps(WarehouseMasterSeed.defaultMaps);
      }
      return densCount;
    } catch (_) {
      return applyDensCacheFromMaps(WarehouseMasterSeed.defaultMaps);
    }
  }

  @override
  State<MultiWarehouseScreen> createState() => _MultiWarehouseScreenState();
}

class _MultiWarehouseScreenState extends State<MultiWarehouseScreen> {
  late List<WarehouseDensRow> _rows;
  late bool _loading;
  List<WarehouseMasterRecord> _records = const [];

  WarehouseMasterStore get _store =>
      widget.store ?? const WarehouseMasterStore();

  @override
  void initState() {
    super.initState();
    final injected = widget.rows;
    if (injected != null) {
      _rows = injected;
      _loading = false;
      MultiWarehouseScreen.densRows = injected;
      MultiWarehouseScreen.densCount = injected.length;
    } else {
      _rows = const [];
      _loading = true;
      _loadWarehouses();
    }
  }

  /// Ambar dens satırlarını SQLite’dan yükler.
  Future<void> _loadWarehouses() async {
    setState(() => _loading = true);
    try {
      await MultiWarehouseScreen.refreshDensCache(store: _store);
      final records = await _store.listActive();
      if (!mounted) return;
      setState(() {
        _records = records;
        _rows = MultiWarehouseScreen.densRows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback = WarehouseDensRow.fromSeed();
      setState(() {
        _records = const [];
        _rows = fallback;
        _loading = false;
      });
    }
  }

  WarehouseMasterRecord? _recordOf(WarehouseDensRow row) {
    for (final r in _records) {
      if (r.id == row.id || r.code == row.code) return r;
    }
    return null;
  }

  Future<void> _showEditor({WarehouseMasterRecord? existing}) async {
    final l10n = AppLocalization.of(context);
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var type = existing?.type ?? WarehouseMasterSeed.typeCenter;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? l10n.translate('field_sales.warehouse_create')
                    : l10n.translate('field_sales.warehouse_edit'),
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
                      labelText:
                          l10n.translate('field_sales.warehouse_code'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText:
                          l10n.translate('field_sales.warehouse_name'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    isDense: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText:
                          l10n.translate('field_sales.warehouse_type'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: WarehouseMasterSeed.typeCenter,
                        child: Text(
                          l10n.translate(
                            'field_sales.stock_slip.warehouse_center',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: WarehouseMasterSeed.typeVehicle,
                        child: Text(
                          l10n.translate(
                            'field_sales.stock_slip.warehouse_vehicle',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: WarehouseMasterSeed.typeReturn,
                        child: Text(
                          l10n.translate(
                            'field_sales.stock_slip.warehouse_return',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => type = v);
                    },
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
        await _store.create(code: code, name: name, type: type);
      } else {
        await _store.update(
          WarehouseMasterRecord(
            id: existing.id,
            code: existing.code,
            name: name,
            type: type,
            createdAt: existing.createdAt,
          ),
        );
      }
      await _loadWarehouses();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.warehouse_save_failed'),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(WarehouseMasterRecord record) async {
    final l10n = AppLocalization.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('field_sales.warehouse_delete'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          l10n.translate(
            'field_sales.warehouse_delete_confirm',
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
    await _loadWarehouses();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.multi_warehouse');
    final rows = _rows;
    final canEdit = widget.rows == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          if (canEdit)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.add,
              tooltip: l10n.translate('field_sales.warehouse_create'),
              onPressed: () => _showEditor(),
            ),
          if (canEdit)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.refresh,
              tooltip: l10n.translate('common.reload'),
              onPressed: _loadWarehouses,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.multi_warehouse.empty'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                      child: Text(
                        l10n.translate(
                          'field_sales.multi_warehouse.list_hint',
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
                      child: Text(
                        l10n
                            .translate(
                              'field_sales.multi_warehouse.count_label',
                            )
                            .replaceAll('{count}', '${rows.length}'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.multi_warehouse.code_col',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l10n.translate(
                                'field_sales.multi_warehouse.name_col',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.multi_warehouse.type_col',
                              ),
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
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final item = rows[index];
                          final record = _recordOf(item);
                          return InkWell(
                            onTap: !canEdit || record == null
                                ? null
                                : () => _showEditor(existing: record),
                            onLongPress: !canEdit || record == null
                                ? null
                                : () => _confirmDelete(record),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.translate(item.typeNameKey),
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
