// Dosya Adı: whms_master_code_name_list_screen.dart
// Açıklama: WHMS dens kod+ad master liste (CRUD stub iskelet)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';

/// {@template whms_master_row}
/// Basit kod + ad satırı.
/// {@endtemplate}
class WhmsMasterRow {
  /// [id]: PK
  final String id;

  /// [code]: Kod
  final String code;

  /// [name]: Ad
  final String name;

  /// {@macro whms_master_row}
  const WhmsMasterRow({
    required this.id,
    required this.code,
    required this.name,
  });
}

/// Liste / upsert / soft-delete sözleşmesi.
abstract class WhmsMasterCodeNameStore {
  /// Aktif satırlar
  Future<List<WhmsMasterRow>> list();

  /// Kod+ad kaydet (id boşsa insert)
  Future<WhmsMasterRow> upsert({
    required String id,
    required String code,
    required String name,
  });

  /// Soft delete
  Future<void> softDelete(String id);
}

/// {@template whms_master_code_name_list_screen}
/// Dens master liste — arama + boş state + ekle dialog.
///
/// Kullanım örneği:
/// ```dart
/// WhmsMasterCodeNameListScreen(
///   routeName: '/whms/vehicles',
///   titleKey: 'whms.vehicles.title',
///   store: WhmsVehicleStore(),
/// )
/// ```
/// {@endtemplate}
class WhmsMasterCodeNameListScreen extends StatefulWidget {
  /// Named route (AppBar / debug)
  final String routeName;

  /// Başlık l10n
  final String titleKey;

  /// Boş state l10n
  final String emptyKey;

  /// Arama hint l10n
  final String searchKey;

  /// Store
  final WhmsMasterCodeNameStore store;

  /// Test inject
  final List<WhmsMasterRow>? initialRows;

  /// {@macro whms_master_code_name_list_screen}
  const WhmsMasterCodeNameListScreen({
    super.key,
    required this.routeName,
    required this.titleKey,
    required this.emptyKey,
    required this.searchKey,
    required this.store,
    this.initialRows,
  });

  @override
  State<WhmsMasterCodeNameListScreen> createState() =>
      _WhmsMasterCodeNameListScreenState();
}

class _WhmsMasterCodeNameListScreenState
    extends State<WhmsMasterCodeNameListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsMasterRow> _all = const [];
  List<WhmsMasterRow> _filtered = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRows != null) {
      _all = List<WhmsMasterRow>.from(widget.initialRows!);
      _filtered = List<WhmsMasterRow>.from(_all);
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
      final rows = await widget.store.list();
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
      _filtered = List<WhmsMasterRow>.from(_all);
      return;
    }
    _filtered = _all.where((r) {
      return '${r.code} ${r.name}'.toLowerCase().contains(needle);
    }).toList(growable: false);
  }

  Future<void> _showEdit({WhmsMasterRow? existing}) async {
    final l10n = AppLocalization.of(context);
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.translate(
              existing == null
                  ? 'whms.master.add'
                  : 'whms.master.edit',
            ),
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.translate('whms.labels.field_code'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.translate('whms.labels.field_name'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
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
              child: Text(l10n.translate('whms.labels.save')),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await widget.store.upsert(
        id: existing?.id ?? '',
        code: codeCtrl.text,
        name: nameCtrl.text,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('whms.labels.save_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate(widget.titleKey),
        showCalculatorHome: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _showEdit(),
            tooltip: l10n.translate('whms.master.add'),
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
                isDense: true,
                hintText: l10n.translate(widget.searchKey),
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
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate(widget.emptyKey),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final row = _filtered[i];
                          return Material(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showEdit(existing: row),
                              onLongPress: () async {
                                await widget.store.softDelete(row.id);
                                await _load();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.code,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      row.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
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
