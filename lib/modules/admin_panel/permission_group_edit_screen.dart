// Dosya Adı: permission_group_edit_screen.dart
// Açıklama: Yetki grubu düzenleme — menü paketi + üye (firma) atama dens
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../core/auth/menu_permission_flags.dart';
import '../../core/localization/app_localization.dart';
import '../../core/services/supabase_service.dart';
import '../../service/database_service.dart';
import '../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../field_sales/shared/view/field_sales_dens_theme.dart';
import 'viewmodel/permission_group_store.dart';

/// {@template permission_group_edit_screen}
/// Grup menü checkbox ağacı + kullanıcı/firma üyelik ataması.
/// {@endtemplate}
class PermissionGroupEditScreen extends StatefulWidget {
  /// [groupId]: Düzenlenen grup
  final String groupId;

  /// Store enjeksiyonu
  final PermissionGroupStore? store;

  /// {@macro permission_group_edit_screen}
  const PermissionGroupEditScreen({
    Key? key,
    required this.groupId,
    this.store,
  }) : super(key: key);

  @override
  State<PermissionGroupEditScreen> createState() =>
      _PermissionGroupEditScreenState();
}

class _PermissionGroupEditScreenState extends State<PermissionGroupEditScreen>
    with SingleTickerProviderStateMixin {
  late final PermissionGroupStore _store =
      widget.store ?? const PermissionGroupStore();
  late TabController _tabs;

  PermissionGroupRecord? _group;
  List<Map<String, dynamic>> _menus = const [];
  Map<String, MenuPermissionFlags> _menuFlags = {};
  List<PermissionGroupMember> _members = const [];
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _companies = const [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.ensureReady();
      final group = await _store.getGroup(widget.groupId);
      final flags = await _store.listGroupMenus(widget.groupId);
      final members = await _store.listMembers(widget.groupId);

      List<Map<String, dynamic>> menus = const [];
      try {
        final db = await DatabaseService.getInstance();
        final sqlite = await db.getDatabase();
        menus = await sqlite.query(
          'menu',
          where: 'is_visible = 1 AND is_deleted = 0',
          orderBy: 'display_order ASC',
        );
      } catch (_) {
        menus = const [];
      }

      List<Map<String, dynamic>> users = const [];
      List<Map<String, dynamic>> companies = const [];
      try {
        final supabase = await SupabaseService.getInstance();
        users = await supabase.query('users', orderBy: 'username');
        companies = await supabase.query('company', orderBy: 'name');
      } catch (_) {
        // Offline: boş kullanıcı/firma listesi
      }

      if (!mounted) return;
      setState(() {
        _group = group;
        _menus = menus;
        _menuFlags = Map<String, MenuPermissionFlags>.from(flags);
        _members = members;
        _users = users;
        _companies = companies;
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

  Future<void> _saveMenus() async {
    setState(() => _saving = true);
    try {
      await _store.replaceGroupMenus(
        groupId: widget.groupId,
        menus: _menuFlags,
      );
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('permission_groups.saved'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setFlag(String uuid, MenuPermissionFlags flags) {
    setState(() {
      if (!flags.canView &&
          !flags.canAdd &&
          !flags.canEdit &&
          !flags.canDelete) {
        _menuFlags.remove(uuid);
      } else {
        _menuFlags[uuid] = flags;
      }
    });
  }

  void _toggleView(String uuid, bool? value) {
    final cur = _menuFlags[uuid] ?? MenuPermissionFlags.none;
    final on = value ?? false;
    _setFlag(
      uuid,
      MenuPermissionFlags(
        canView: on,
        canAdd: on ? cur.canAdd : false,
        canEdit: on ? cur.canEdit : false,
        canDelete: on ? cur.canDelete : false,
      ),
    );
  }

  List<Map<String, dynamic>> _childrenOf(Object? parentId) {
    return _menus.where((m) {
      final pid = m['parent_id'];
      if (parentId == null) return pid == null;
      return pid != null && pid.toString() == parentId.toString();
    }).toList();
  }

  Future<void> _addMember() async {
    final l10n = AppLocalization.of(context);
    if (_users.isEmpty || _companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('permission_groups.no_users_companies')),
        ),
      );
      return;
    }
    String? userId = _users.first['id']?.toString();
    int companyNo =
        int.tryParse('${_companies.first['company_no']}') ?? 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(l10n.translate('permission_groups.assign_member')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: userId,
                    isDense: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.translate('permission_groups.user'),
                    ),
                    items: _users
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['id']?.toString(),
                            child: Text(
                              '${u['username'] ?? u['full_name'] ?? u['id']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => userId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: companyNo,
                    isDense: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.translate('permission_groups.company'),
                    ),
                    items: _companies
                        .map((c) {
                          final no =
                              int.tryParse('${c['company_no']}') ?? 0;
                          return DropdownMenuItem(
                            value: no,
                            child: Text(
                              '${c['name'] ?? no} ($no)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => companyNo = v);
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
    if (ok != true || userId == null) return;
    await _store.assignMember(
      groupId: widget.groupId,
      userId: userId!,
      companyNo: companyNo,
    );
    await _load();
  }

  String _userLabel(String userId) {
    for (final u in _users) {
      if (u['id']?.toString() == userId) {
        return '${u['username'] ?? u['full_name'] ?? userId}';
      }
    }
    return userId;
  }

  String _companyLabel(int companyNo) {
    for (final c in _companies) {
      final no = int.tryParse('${c['company_no']}') ?? -1;
      if (no == companyNo) {
        return '${c['name'] ?? companyNo}';
      }
    }
    return '$companyNo';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = _group?.name ??
        l10n.translate('permission_groups.edit_title');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: TabBar(
            controller: _tabs,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontSize: 12),
            tabs: [
              Tab(text: l10n.translate('permission_groups.tab_menus')),
              Tab(text: l10n.translate('permission_groups.tab_members')),
            ],
          ),
        ),
        actions: [
          if (_tabs.index == 0)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.save,
              tooltip: l10n.translate('common.save'),
              onPressed: _saving ? null : _saveMenus,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildMenusTab(l10n),
                    _buildMembersTab(l10n),
                  ],
                ),
    );
  }

  Widget _buildMenusTab(AppLocalization l10n) {
    final roots = _childrenOf(null);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Text(
            l10n.translate('permission_groups.menus_hint'),
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            children: roots.map((m) => _menuNode(m, 0, l10n)).toList(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: SizedBox(
              height: 40,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveMenus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FieldSalesDensAppBar.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.translate('common.save')),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuNode(
    Map<String, dynamic> menu,
    int depth,
    AppLocalization l10n,
  ) {
    final uuid = (menu['uuid'] as String?) ?? '';
    final title = (menu['title'] as String?) ?? uuid;
    final flags = _menuFlags[uuid] ?? MenuPermissionFlags.none;
    final children = _childrenOf(menu['id']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: depth * 12.0),
          child: Row(
            children: [
              Checkbox(
                value: flags.canView,
                visualDensity: VisualDensity.compact,
                onChanged: (v) => _toggleView(uuid, v),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (flags.canView) ...[
                _miniFlag(
                  label: l10n.translate('permission_groups.can_add'),
                  value: flags.canAdd,
                  onChanged: (v) => _setFlag(
                    uuid,
                    MenuPermissionFlags(
                      canView: true,
                      canAdd: v ?? false,
                      canEdit: flags.canEdit,
                      canDelete: flags.canDelete,
                    ),
                  ),
                ),
                _miniFlag(
                  label: l10n.translate('permission_groups.can_edit'),
                  value: flags.canEdit,
                  onChanged: (v) => _setFlag(
                    uuid,
                    MenuPermissionFlags(
                      canView: true,
                      canAdd: flags.canAdd,
                      canEdit: v ?? false,
                      canDelete: flags.canDelete,
                    ),
                  ),
                ),
                _miniFlag(
                  label: l10n.translate('permission_groups.can_delete'),
                  value: flags.canDelete,
                  onChanged: (v) => _setFlag(
                    uuid,
                    MenuPermissionFlags(
                      canView: true,
                      canAdd: flags.canAdd,
                      canEdit: flags.canEdit,
                      canDelete: v ?? false,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ...children.map((c) => _menuNode(c, depth + 1, l10n)),
      ],
    );
  }

  Widget _miniFlag({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          visualDensity: VisualDensity.compact,
          onChanged: onChanged,
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildMembersTab(AppLocalization l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate('permission_groups.members_hint'),
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
              TextButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add, size: 16),
                label: Text(
                  l10n.translate('permission_groups.assign_member'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _members.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('permission_groups.no_members'),
                    style: const TextStyle(fontSize: 13),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final m = _members[i];
                    return Container(
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
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userLabel(m.userId),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _companyLabel(m.companyNo),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await _store.removeMember(
                                groupId: widget.groupId,
                                userId: m.userId,
                                companyNo: m.companyNo,
                              );
                              await _load();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
