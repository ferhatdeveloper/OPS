// Dosya Adı: menu_management.dart
// Açıklama: Admin paneli için menü yönetimi ekranı (listeleme, ekleme, silme, drag-drop sıralama)
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-22

import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/mdi_icon_map.dart';

/// {@template MenuManagement}
/// Menü yönetimi ekranı: menüleri listeleme, ekleme, silme ve drag-drop ile sıralama
///
/// Kullanım örneği:
/// ```dart
/// MenuManagement()
/// ```
/// {@endtemplate}
class MenuManagement extends StatefulWidget {
  const MenuManagement({Key? key}) : super(key: key);

  @override
  State<MenuManagement> createState() => _MenuManagementState();
}

class _MenuManagementState extends State<MenuManagement> {
  List<Map<String, dynamic>> _menus = [];
  bool _isLoading = true;
  String? _error;

  // Yeni eklenen state
  Map<String, dynamic>? _editingMenu;
  int? _editingParentId;
  bool _showForm = false;

  List<Map<String, dynamic>> get _mainMenus =>
      _menus.where((m) => m['parent_id'] == null).toList();
  List<Map<String, dynamic>> _getSubMenus(int parentId) =>
      _menus.where((m) => m['parent_id'] == parentId).toList();

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = await SupabaseService.getInstance();
      final menus = await supabase.query('menu', orderBy: 'display_order');
      setState(() {
        _menus = menus
            .where((m) => m['is_deleted'] != true && m['is_visible'] == true)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Menüler yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  void _openMenuForm({Map<String, dynamic>? menu, int? parentId}) {
    setState(() {
      _editingMenu = menu;
      _editingParentId = parentId;
      _showForm = true;
    });
  }

  void _closeMenuForm() {
    setState(() {
      _editingMenu = null;
      _editingParentId = null;
      _showForm = false;
    });
  }

  Future<void> _saveMenuForm(Map<String, dynamic> menuData) async {
    final supabase = await SupabaseService.getInstance();
    if (_editingMenu != null) {
      await supabase.update('menu', menuData, _editingMenu!['id'].toString());
    } else {
      menuData['display_order'] = _menus.length;
      await supabase.insert('menu', menuData);
    }
    _closeMenuForm();
    await _fetchMenus();
  }

  Future<void> _deleteMenu(int index) async {
    try {
      final supabase = await SupabaseService.getInstance();
      final menuId = _menus[index]['id'];
      // Soft delete: is_deleted = true
      await supabase.update('menu', {'is_deleted': true}, menuId.toString());
      await _fetchMenus();
    } catch (e) {
      setState(() {
        _error = 'Menü silinemedi: $e';
      });
    }
  }

  Future<void> _updateMenuOrder() async {
    try {
      final supabase = await SupabaseService.getInstance();
      for (int i = 0; i < _menus.length; i++) {
        await supabase.update(
            'menu', {'display_order': i}, _menus[i]['id'].toString());
      }
    } catch (e) {
      setState(() {
        _error = 'Sıralama güncellenemedi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menü Yönetimi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Yeni Menü Ekle'),
                              onPressed: () => _openMenuForm(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            itemCount: _mainMenus.length,
                            onReorder: (oldIndex, newIndex) async {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _mainMenus[oldIndex];
                              final oldMenuIndex = _menus
                                  .indexWhere((m) => m['id'] == item['id']);
                              setState(() {
                                _menus.removeAt(oldMenuIndex);
                                final insertIndex = newIndex >=
                                        _mainMenus.length
                                    ? _menus.length
                                    : _menus.indexWhere((m) =>
                                        m['id'] == _mainMenus[newIndex]['id']);
                                _menus.insert(insertIndex, item);
                              });
                              await _updateMenuOrder();
                            },
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, mainIndex) {
                              final mainMenu = _mainMenus[mainIndex];
                              final subMenus = _getSubMenus(mainMenu['id']);
                              return Card(
                                key: ValueKey(mainMenu['id']),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  leading: ReorderableDragStartListener(
                                    index: mainIndex,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                  title: Text(mainMenu['title'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _openMenuForm(menu: mainMenu),
                                        tooltip: 'Düzenle',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            color: Colors.green),
                                        onPressed: () => _openMenuForm(
                                            parentId: mainMenu['id']),
                                        tooltip: 'Alt Menü Ekle',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteMenu(
                                            _menus.indexWhere((m) =>
                                                m['id'] == mainMenu['id'])),
                                        tooltip: 'Sil',
                                      ),
                                    ],
                                  ),
                                  children: subMenus.isEmpty
                                      ? [
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                left: 24.0, bottom: 8),
                                            child: Text('Alt menü yok',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ),
                                        ]
                                      : [
                                          ReorderableListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: subMenus.length,
                                            onReorder: (oldSub, newSub) async {
                                              if (newSub > oldSub) newSub--;
                                              final parentId = mainMenu['id'];
                                              final allSubMenus = _menus
                                                  .where((m) =>
                                                      m['parent_id'] ==
                                                      parentId)
                                                  .toList();
                                              final moved =
                                                  allSubMenus.removeAt(oldSub);
                                              allSubMenus.insert(newSub, moved);
                                              int globalIndex = 0;
                                              for (int i = 0;
                                                  i < _menus.length;
                                                  i++) {
                                                if (_menus[i]['parent_id'] ==
                                                    parentId) {
                                                  _menus[i] =
                                                      allSubMenus[globalIndex];
                                                  globalIndex++;
                                                }
                                              }
                                              setState(() {});
                                              await _updateMenuOrder();
                                            },
                                            buildDefaultDragHandles: false,
                                            itemBuilder: (context, subIndex) {
                                              final subMenu =
                                                  subMenus[subIndex];
                                              return ListTile(
                                                key: ValueKey(subMenu['id']),
                                                leading:
                                                    ReorderableDragStartListener(
                                                  index: subIndex,
                                                  child: const Icon(
                                                      Icons.drag_handle,
                                                      size: 20),
                                                ),
                                                title: Text(
                                                    subMenu['title'] ?? ''),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.blue),
                                                      onPressed: () =>
                                                          _openMenuForm(
                                                              menu: subMenu),
                                                      tooltip: 'Düzenle',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () =>
                                                          _deleteMenu(_menus
                                                              .indexWhere((m) =>
                                                                  m['id'] ==
                                                                  subMenu[
                                                                      'id'])),
                                                      tooltip: 'Sil',
                                                    ),
                                                  ],
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                        left: 32, right: 16),
                                              );
                                            },
                                          ),
                                        ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // Ekranda açılan form paneli
                    if (_showForm)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 420,
                        child: Material(
                          color: Colors.white,
                          elevation: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            child: MenuEditPanel(
                              menu: _editingMenu,
                              parentId: _editingParentId,
                              onClose: _closeMenuForm,
                              onSave: _saveMenuForm,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

// Modern ve flat form panel widget
class MenuEditPanel extends StatefulWidget {
  final Map<String, dynamic>? menu;
  final int? parentId;
  final VoidCallback onClose;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const MenuEditPanel(
      {Key? key,
      this.menu,
      this.parentId,
      required this.onClose,
      required this.onSave})
      : super(key: key);

  @override
  State<MenuEditPanel> createState() => _MenuEditPanelState();
}

class _MenuEditPanelState extends State<MenuEditPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleTrController;
  late TextEditingController _descTrController;
  late TextEditingController _titleEnController;
  late TextEditingController _descEnController;
  late TextEditingController _titleArController;
  late TextEditingController _descArController;
  late TextEditingController _titleRuController;
  late TextEditingController _descRuController;
  late TextEditingController _routeController;
  late TextEditingController _moduleNameController;
  bool _isFavorite = false;
  bool _isVisible = true;
  String _iconName = 'menu';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _titleTrController = TextEditingController(text: menu?['title'] ?? '');
    _descTrController = TextEditingController(text: menu?['description'] ?? '');
    _titleEnController = TextEditingController(text: menu?['title_en'] ?? '');
    _descEnController =
        TextEditingController(text: menu?['description_en'] ?? '');
    _titleArController = TextEditingController(text: menu?['title_ar'] ?? '');
    _descArController =
        TextEditingController(text: menu?['description_ar'] ?? '');
    _titleRuController = TextEditingController(text: menu?['title_ru'] ?? '');
    _descRuController =
        TextEditingController(text: menu?['description_ru'] ?? '');
    _routeController = TextEditingController(text: menu?['route'] ?? '');
    _moduleNameController =
        TextEditingController(text: menu?['module_name'] ?? '');
    _isFavorite = menu?['is_favorite'] == true;
    _isVisible = menu?['is_visible'] != false;
    if (menu != null && menu['icon'] != null && menu['icon'] is String) {
      _iconName = menu['icon'];
    }
  }

  Future<void> _autoTranslate() async {
    setState(() => _isSaving = true);
    _titleEnController.text = _titleTrController.text;
    _titleArController.text = _titleTrController.text;
    _titleRuController.text = _titleTrController.text;
    _descEnController.text = _descTrController.text;
    _descArController.text = _descTrController.text;
    _descRuController.text = _descTrController.text;
    setState(() => _isSaving = false);
  }

  Future<void> _showIconPicker() async {
    String search = '';
    late final List<MapEntry<String, IconData>> allIcons =
        mdiIconMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    late final List<MapEntry<String, IconData>> popularIcons =
        allIcons.take(200).toList();
    late final List<MapEntry<String, IconData>> otherIcons = allIcons
        .where((entry) => !popularIcons.any((pop) => pop.key == entry.key))
        .toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          List<MapEntry<String, IconData>> gridIcons;
          if (search.isNotEmpty) {
            gridIcons = allIcons
                .where((entry) =>
                    entry.key.toLowerCase().contains(search.toLowerCase()))
                .toList();
          } else {
            gridIcons = [...popularIcons, ...otherIcons];
          }
          return Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('İkon Seç',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'İkon ara... (örn: home, star)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 1,
                      ),
                      itemCount: gridIcons.length,
                      itemBuilder: (context, index) {
                        final entry = gridIcons[index];
                        final iconData = entry.value;
                        final isSelected = _iconName == entry.key;
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(iconData),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Icon(iconData,
                                  size: 32,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.black54),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    setState(() {});
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final menuData = {
      'title': _titleTrController.text,
      'description': _descTrController.text,
      'title_en': _titleEnController.text,
      'description_en': _descEnController.text,
      'title_ar': _titleArController.text,
      'description_ar': _descArController.text,
      'title_ru': _titleRuController.text,
      'description_ru': _descRuController.text,
      'route': _routeController.text,
      'module_name': _moduleNameController.text,
      'parent_id': widget.parentId ?? widget.menu?['parent_id'],
      'is_favorite': _isFavorite,
      'is_visible': _isVisible,
      'icon': _iconName,
    };
    await widget.onSave(menuData);
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final iconData = MdiIcons.fromString(_iconName) ?? Icons.menu;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.menu != null ? 'Menü Düzenle' : 'Yeni Menü Ekle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: widget.onClose,
                    splashRadius: 20,
                    tooltip: 'Kapat',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      indicatorColor: Colors.blue,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'TR'),
                        Tab(text: 'EN'),
                        Tab(text: 'AR'),
                        Tab(text: 'RU'),
                      ],
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.translate,
                        size: 18, color: Colors.blue),
                    label: const Text('Çevir',
                        style: TextStyle(fontSize: 13, color: Colors.blue)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.transparent,
                    ),
                    onPressed: _isSaving ? null : _autoTranslate,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: TabBarView(
                  children: [
                    // TR
                    Column(
                      children: [
                        TextFormField(
                          controller: _titleTrController,
                          decoration: InputDecoration(
                            labelText: 'Başlık (TR)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Başlık zorunlu' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descTrController,
                          decoration: InputDecoration(
                            labelText: 'Açıklama (TR)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    // EN
                    Column(
                      children: [
                        TextFormField(
                          controller: _titleEnController,
                          decoration: InputDecoration(
                            labelText: 'Başlık (EN)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descEnController,
                          decoration: InputDecoration(
                            labelText: 'Açıklama (EN)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    // AR
                    Column(
                      children: [
                        TextFormField(
                          controller: _titleArController,
                          decoration: InputDecoration(
                            labelText: 'Başlık (AR)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descArController,
                          decoration: InputDecoration(
                            labelText: 'Açıklama (AR)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    // RU
                    Column(
                      children: [
                        TextFormField(
                          controller: _titleRuController,
                          decoration: InputDecoration(
                            labelText: 'Başlık (RU)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descRuController,
                          decoration: InputDecoration(
                            labelText: 'Açıklama (RU)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _routeController,
                      decoration: InputDecoration(
                        labelText: 'Route',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _moduleNameController,
                      decoration: InputDecoration(
                        labelText: 'Modül Adı',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Favori'),
                        Switch(
                          value: _isFavorite,
                          onChanged: (v) => setState(() => _isFavorite = v),
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Görünür'),
                        Switch(
                          value: _isVisible,
                          onChanged: (v) => setState(() => _isVisible = v),
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showIconPicker,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(iconData, size: 32, color: Colors.blue),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('İptal'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
