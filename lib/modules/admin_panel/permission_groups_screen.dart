// Dosya Adı: permission_groups_screen.dart
// Açıklama: Yetki grubu listesi dens — CRUD (yalnızca admin)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../field_sales/shared/view/field_sales_dens_app_bar.dart';
import 'permission_group_edit_screen.dart';
import 'viewmodel/permission_group_store.dart';

/// {@template permission_groups_screen}
/// Yetki grupları dens listesi.
///
/// Route / admin panel sekmesi: grup oluştur, menü paketi, üye ata.
/// {@endtemplate}
class PermissionGroupsScreen extends StatefulWidget {
  /// Embedded (AppBar yok) — UserAuthorization içi
  final bool embedded;

  /// Store enjeksiyonu (test)
  final PermissionGroupStore? store;

  /// Test: önceden yüklenmiş gruplar (async skip)
  final List<PermissionGroupRecord>? initialGroups;

  /// {@macro permission_groups_screen}
  const PermissionGroupsScreen({
    Key? key,
    this.embedded = false,
    this.store,
    this.initialGroups,
  }) : super(key: key);

  @override
  State<PermissionGroupsScreen> createState() => _PermissionGroupsScreenState();
}

class _PermissionGroupsScreenState extends State<PermissionGroupsScreen> {
  late final PermissionGroupStore _store =
      widget.store ?? const PermissionGroupStore();
  List<PermissionGroupRecord> _groups = const [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialGroups != null) {
      _groups = widget.initialGroups!;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.ensureReady();
      final rows = await _store.listGroups();
      if (!mounted) return;
      setState(() {
        _groups = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<PermissionGroupRecord> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _groups;
    return _groups
        .where(
          (g) =>
              g.name.toLowerCase().contains(q) ||
              (g.description ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalization.of(context);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('permission_groups.create_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.translate('permission_groups.name'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.translate('permission_groups.description'),
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
            child: Text(l10n.translate('common.save')),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    await _store.createGroup(
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );
    await _load();
  }

  Future<void> _openEdit(PermissionGroupRecord group) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PermissionGroupEditScreen(
          groupId: group.id,
          store: _store,
        ),
      ),
    );
    await _load();
  }

  Future<void> _delete(PermissionGroupRecord group) async {
    final l10n = AppLocalization.of(context);
    if (group.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('permission_groups.system_locked')),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('permission_groups.delete_title')),
        content: Text(l10n.translate('permission_groups.delete_confirm')),
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
    if (ok != true) return;
    await _store.softDeleteGroup(group.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final body = _buildBody(l10n);
    if (widget.embedded) {
      return Material(child: body);
    }
    return Scaffold(
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('permission_groups.title'),
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('permission_groups.create_title'),
            onPressed: _createGroup,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(AppLocalization l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    final rows = _filtered;
    return Column(
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('permission_groups.title'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: l10n.translate('permission_groups.create_title'),
                  onPressed: _createGroup,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.translate('common.search'),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('permission_groups.empty'),
                    style: const TextStyle(fontSize: 13),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final g = rows[i];
                    return InkWell(
                      onTap: () => _openEdit(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: FieldSalesDensAppBar.primaryColor
                                .withValues(alpha: 0.25),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              g.isSystem
                                  ? Icons.lock_outline
                                  : Icons.group_outlined,
                              size: 18,
                              color: FieldSalesDensAppBar.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((g.description ?? '').isNotEmpty)
                                    Text(
                                      g.description!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!g.isSystem)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _delete(g),
                              ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
