// Dosya Adı: whms_package_type_list_screen.dart
// Açıklama: WHMS paket tipi dens CRUD listesi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_package_type.dart';
import '../viewmodel/whms_package_type_store.dart';

/// {@template whms_package_type_list_screen}
/// Paket tipi dens liste + form.
/// Route: `/whms/labels/packages`
/// {@endtemplate}
class WhmsPackageTypeListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsPackageTypes;

  /// [store]: Test
  final WhmsPackageTypeStore? store;

  /// [rows]: Test
  final List<WhmsPackageType>? rows;

  /// {@macro whms_package_type_list_screen}
  const WhmsPackageTypeListScreen({
    super.key,
    this.store,
    this.rows,
  });

  @override
  State<WhmsPackageTypeListScreen> createState() =>
      _WhmsPackageTypeListScreenState();
}

class _WhmsPackageTypeListScreenState extends State<WhmsPackageTypeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsPackageType> _all = const [];
  List<WhmsPackageType> _filtered = const [];
  bool _loading = true;

  WhmsPackageTypeStore get _store =>
      widget.store ?? const WhmsPackageTypeStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WhmsPackageType>.from(widget.rows!);
      _filtered = List<WhmsPackageType>.from(_all);
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
      final rows = await _store.listActive();
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
      _filtered = List<WhmsPackageType>.from(_all);
      return;
    }
    _filtered = _all.where((r) {
      final hay = '${r.code} ${r.name} ${r.tareRef ?? ''}'.toLowerCase();
      return hay.contains(needle);
    }).toList(growable: false);
  }

  Future<void> _showEditor({WhmsPackageType? existing}) async {
    final l10n = AppLocalization.of(context);
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final tareCtrl = TextEditingController(text: existing?.tareRef ?? '');
    var afterSales = existing?.afterSalesFlag ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? l10n.translate('whms.packages.add')
                    : l10n.translate('whms.packages.edit'),
                style: const TextStyle(fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.translate('whms.packages.code'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      enabled: existing == null,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.translate('whms.packages.name'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tareCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.translate('whms.packages.tare_ref'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate('whms.packages.after_sales'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: afterSales,
                      onChanged: (v) =>
                          setLocal(() => afterSales = v ?? false),
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
                  child: Text(l10n.translate('whms.packages.save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    try {
      await _store.upsert(
        WhmsPackageType(
          id: existing?.id ?? '',
          code: codeCtrl.text,
          name: nameCtrl.text,
          tareRef: tareCtrl.text.trim().isEmpty ? null : tareCtrl.text.trim(),
          afterSalesFlag: afterSales,
          createdAt: existing?.createdAt,
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('whms.packages.required_fields')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.packages.title'),
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('whms.packages.add'),
            onPressed: () => _showEditor(),
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
                hintText: l10n.translate('whms.packages.search_hint'),
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
                          l10n.translate('whms.packages.empty'),
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
                          final r = _filtered[i];
                          return Material(
                            color: FieldSalesDensTheme.surface(context),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showEditor(existing: r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.code,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: FieldSalesDensTheme.title(context),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
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
