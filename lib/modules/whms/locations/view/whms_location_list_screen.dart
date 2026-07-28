// Dosya Adı: whms_location_list_screen.dart
// Açıklama: WHMS lokasyon dens liste + form (koridor/raf/göz)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import '../../../field_sales/stock/model/warehouse_master_seed.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_location.dart';
import '../viewmodel/whms_location_store.dart';

/// {@template whms_location_list_screen}
/// Ambar altı lokasyon dens listesi — CRUD + ambar chip filtresi.
/// Route: `/whms/locations`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsLocationListScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsLocationListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsLocations;

  /// Opsiyonel satır enjeksiyonu (test)
  final List<WhmsLocation>? rows;

  /// Store enjeksiyonu (test)
  final WhmsLocationStore? store;

  /// {@macro whms_location_list_screen}
  const WhmsLocationListScreen({
    Key? key,
    this.rows,
    this.store,
  }) : super(key: key);

  @override
  State<WhmsLocationListScreen> createState() =>
      _WhmsLocationListScreenState();
}

class _WhmsLocationListScreenState extends State<WhmsLocationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsLocation> _all = const [];
  List<WhmsLocation> _filtered = const [];
  bool _loading = true;

  /// null = tüm ambarlar
  String? _warehouseFilter;

  WhmsLocationStore get _store =>
      widget.store ?? const WhmsLocationStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WhmsLocation>.from(widget.rows!);
      _filtered = List<WhmsLocation>.from(_all);
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
      final rows = await _store.listActive(
        warehouseCode: _warehouseFilter,
      );
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
        ? List<WhmsLocation>.from(_all)
        : _all
            .where((o) {
              return o.warehouseCode.toLowerCase().contains(q) ||
                  o.code.toLowerCase().contains(q) ||
                  o.addressLabel.toLowerCase().contains(q) ||
                  o.barcode.toLowerCase().contains(q) ||
                  o.aisle.toLowerCase().contains(q) ||
                  o.rack.toLowerCase().contains(q) ||
                  o.bin.toLowerCase().contains(q);
            })
            .toList(growable: false);
    if (notify) {
      setState(() => _filtered = next);
    } else {
      _filtered = next;
    }
  }

  Future<void> _setWarehouseFilter(String? code) async {
    if (_warehouseFilter == code) return;
    setState(() {
      _warehouseFilter = code;
      _loading = true;
    });
    await _load();
  }

  Future<void> _showEditor({WhmsLocation? existing}) async {
    final l10n = AppLocalization.of(context);
    final whCtrl = TextEditingController(
      text: existing?.warehouseCode ??
          (_warehouseFilter ??
              WarehouseMasterSeed.defaultRows.first.code),
    );
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final aisleCtrl = TextEditingController(text: existing?.aisle ?? '');
    final rackCtrl = TextEditingController(text: existing?.rack ?? '');
    final binCtrl = TextEditingController(text: existing?.bin ?? '');
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    final seqCtrl = TextEditingController(
      text: (existing?.routeSeq ?? 0).toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            existing == null
                ? l10n.translate('whms.locations.add')
                : l10n.translate('whms.locations.edit'),
            style: const TextStyle(fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _densField(
                  controller: whCtrl,
                  label: l10n.translate('whms.locations.warehouse'),
                  enabled: existing == null,
                  capitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                _densField(
                  controller: codeCtrl,
                  label: l10n.translate('whms.locations.code'),
                  enabled: existing == null,
                  capitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                _densField(
                  controller: aisleCtrl,
                  label: l10n.translate('whms.locations.aisle'),
                  capitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                _densField(
                  controller: rackCtrl,
                  label: l10n.translate('whms.locations.rack'),
                  capitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                _densField(
                  controller: binCtrl,
                  label: l10n.translate('whms.locations.bin'),
                  capitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                _densField(
                  controller: barcodeCtrl,
                  label: l10n.translate('whms.locations.barcode'),
                ),
                const SizedBox(height: 8),
                _densField(
                  controller: seqCtrl,
                  label: l10n.translate('whms.locations.route_seq'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
              child: Text(l10n.translate('whms.locations.save')),
            ),
          ],
        );
      },
    );

    final wh = whCtrl.text.trim();
    final code = codeCtrl.text.trim();
    final aisle = aisleCtrl.text.trim();
    final rack = rackCtrl.text.trim();
    final bin = binCtrl.text.trim();
    final barcode = barcodeCtrl.text.trim();
    final seq = int.tryParse(seqCtrl.text.trim()) ?? 0;
    whCtrl.dispose();
    codeCtrl.dispose();
    aisleCtrl.dispose();
    rackCtrl.dispose();
    binCtrl.dispose();
    barcodeCtrl.dispose();
    seqCtrl.dispose();

    if (saved != true || !mounted) return;
    if (wh.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.locations.required_fields'),
          ),
        ),
      );
      return;
    }

    try {
      await _store.upsert(
        WhmsLocation(
          id: existing?.id ?? '',
          warehouseCode: wh,
          code: code,
          aisle: aisle,
          rack: rack,
          bin: bin,
          barcode: barcode,
          routeSeq: seq,
          createdAt: existing?.createdAt,
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.locations.required_fields'),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(WhmsLocation record) async {
    final l10n = AppLocalization.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('whms.locations.delete'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          l10n.translate(
            'whms.locations.delete_confirm',
            args: {'address': record.addressLabel},
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

  Widget _densField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
      ),
    );
  }

  List<FieldSalesDensChipItem> _warehouseChips(AppLocalization l10n) {
    final items = <FieldSalesDensChipItem>[
      FieldSalesDensChipItem(
        label: l10n.translate('whms.locations.filter_all'),
        selected: _warehouseFilter == null,
        onTap: () => _setWarehouseFilter(null),
      ),
    ];
    for (final w in WarehouseMasterSeed.defaultRows) {
      items.add(
        FieldSalesDensChipItem(
          label: w.code,
          selected: _warehouseFilter == w.code,
          onTap: () => _setWarehouseFilter(w.code),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.locations.title'),
        backgroundColor: primary,
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('whms.locations.add'),
            onPressed: () => _showEditor(),
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(items: _warehouseChips(l10n)),
          ],
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
                hintText: l10n.translate('whms.locations.search_hint'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                          l10n.translate('whms.locations.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final row = _filtered[index];
                          return _LocationRow(
                            location: row,
                            isDark: isDark,
                            onEdit: () => _showEditor(existing: row),
                            onDelete: () => _confirmDelete(row),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dens lokasyon satırı.
class _LocationRow extends StatelessWidget {
  final WhmsLocation location;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationRow({
    required this.location,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${location.warehouseCode}  ·  ${location.code}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (location.addressLabel != location.code)
                          location.addressLabel,
                        if (location.barcode.trim().isNotEmpty)
                          location.barcode,
                        'SEQ ${location.routeSeq}',
                      ].join('  ·  '),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
