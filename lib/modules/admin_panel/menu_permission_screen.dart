import 'package:flutter/material.dart';
// TODO: Projenizde SupabaseService importunu aşağıya göre ayarlayın
import '../../core/services/supabase_service.dart';

class MenuNode {
  final int id;
  final String title;
  final List<MenuNode> children;
  MenuNode({required this.id, required this.title, this.children = const []});
}

class MenuPermissionScreen extends StatefulWidget {
  final String selectedUserId;
  final String selectedCompanyNo;
  final VoidCallback? onBack;
  const MenuPermissionScreen({
    required this.selectedUserId,
    required this.selectedCompanyNo,
    this.onBack,
    super.key,
  });

  @override
  State<MenuPermissionScreen> createState() => _MenuPermissionScreenState();
}

class _MenuPermissionScreenState extends State<MenuPermissionScreen> {
  List<MenuNode> menuTree = [];
  Map<int, Map<String, bool>> permissionMap = {};
  List<Map<String, dynamic>> _menus = [];
  bool _isLoading = true;
  String? _error;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchMenusAndPermissions();
  }

  Future<void> _fetchMenusAndPermissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = await SupabaseService.getInstance();
      final menus = await supabase.query('menu', orderBy: 'display_order');
      _menus = menus
          .where((m) => m['is_deleted'] != true && m['is_visible'] == true)
          .toList();
      debugPrint('MENULER: \\${_menus.length} adet');
      for (final m in _menus) {
        debugPrint(
            'menu: id=\\${m['id']} title=\\${m['title']} parent_id=\\${m['parent_id']}');
      }
      final perms = await supabase.query('menu_permissions');
      final filteredPerms = perms
          .where((p) =>
              p['user_id'].toString() == widget.selectedUserId.toString() &&
              p['company_no']?.toString() ==
                  widget.selectedCompanyNo.toString())
          .toList();
      debugPrint('YETKILER: \\${filteredPerms.length} adet');
      setState(() {
        menuTree = buildMenuTreeFromList(_menus, null);
        permissionMap = {
          for (var p in filteredPerms)
            p['menu_id']: {
              'can_view': p['can_view'] ?? false,
              'can_edit': p['can_edit'] ?? false,
              'can_delete': p['can_delete'] ?? false,
              'can_add': p['can_add'] ?? false,
            }
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Menüler veya yetkiler yüklenemedi: \\$e';
        _isLoading = false;
      });
    }
  }

  List<MenuNode> buildMenuTreeFromList(
      List<Map<String, dynamic>> menus, int? parentId) {
    debugPrint('buildMenuTreeFromList çağrıldı - parentId: $parentId');

    final filteredMenus = menus.where((m) {
      final menuParentId = m['parent_id'];
      final isMatch = (menuParentId == null && parentId == null) ||
          (menuParentId != null &&
              menuParentId.toString() == parentId.toString());

      debugPrint('''
        Menu Filtreleme:
        - Menu ID: ${m['id']}
        - Menu Parent ID: $menuParentId
        - Aranan Parent ID: $parentId
        - Eşleşme: $isMatch
      ''');

      return isMatch;
    }).toList();

    debugPrint('Filtrelenmiş menü sayısı: ${filteredMenus.length}');

    return filteredMenus.map((m) {
      final node = MenuNode(
        id: m['id'],
        title: m['title'],
        children: buildMenuTreeFromList(menus, m['id']),
      );

      debugPrint('''
        Oluşturulan Node:
        - ID: ${node.id}
        - Title: ${node.title}
        - Alt Menü Sayısı: ${node.children.length}
      ''');

      return node;
    }).toList();
  }

  void updatePermissionRecursive(MenuNode node, String permType, bool? value) {
    setState(() {
      permissionMap[node.id] ??= {
        'can_view': false,
        'can_edit': false,
        'can_delete': false,
        'can_add': false
      };
      permissionMap[node.id]![permType] = value ?? false;
      for (final child in node.children) {
        updatePermissionRecursive(child, permType, value);
      }
    });
  }

  Future<void> savePermissions() async {
    final supabase = await SupabaseService.getInstance();
    final yetkiListesi = permissionMap.entries
        .map((e) => {
              'menu_id': e.key,
              'user_id': widget.selectedUserId,
              'company_no': widget.selectedCompanyNo,
              'can_view': e.value['can_view'],
              'can_edit': e.value['can_edit'],
              'can_delete': e.value['can_delete'],
              'can_add': e.value['can_add'],
            })
        .toList();
    await supabase.upsert('menu_permissions', yetkiListesi);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Yetkiler kaydedildi')));
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (final node in menuTree) {
        updatePermissionRecursive(node, 'can_view', _selectAll);
        updatePermissionRecursive(node, 'can_edit', _selectAll);
        updatePermissionRecursive(node, 'can_delete', _selectAll);
        updatePermissionRecursive(node, 'can_add', _selectAll);
      }
    });
  }

  void _toggleNodeWithChildren(MenuNode node, String permType, bool? value) {
    setState(() {
      updatePermissionRecursive(node, permType, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onBack != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri Dön'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF29507A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: widget.onBack,
            ),
          ),
        Expanded(
          child: Scaffold(
            appBar: widget.onBack == null
                ? AppBar(title: const Text('Menü Yetkileri'))
                : null,
            body: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                      ),
                      const Text('Tümünü Seç'),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Menü Yetkileri',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView(
                    children: menuTree
                        .map((node) => buildMenuTreeWithSelectAll(node))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: savePermissions,
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMenuTreeWithSelectAll(MenuNode node) {
    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              node.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Görüntüle'),
          Checkbox(
            value: permissionMap[node.id]?['can_view'] ?? false,
            onChanged: (v) => _toggleNodeWithChildren(node, 'can_view', v),
          ),
          const SizedBox(width: 8),
          const Text('Düzenle'),
          Checkbox(
            value: permissionMap[node.id]?['can_edit'] ?? false,
            onChanged: (v) => _toggleNodeWithChildren(node, 'can_edit', v),
          ),
          const SizedBox(width: 8),
          const Text('Sil'),
          Checkbox(
            value: permissionMap[node.id]?['can_delete'] ?? false,
            onChanged: (v) => _toggleNodeWithChildren(node, 'can_delete', v),
          ),
          const SizedBox(width: 8),
          const Text('Ekle'),
          Checkbox(
            value: permissionMap[node.id]?['can_add'] ?? false,
            onChanged: (v) => _toggleNodeWithChildren(node, 'can_add', v),
          ),
        ],
      ),
      children: node.children.map(buildMenuTreeWithSelectAll).toList(),
    );
  }
}
