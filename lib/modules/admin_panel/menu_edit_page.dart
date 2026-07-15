// Dosya Adı: menu_edit_page.dart
// Açıklama: Menü ekleme/düzenleme için tam sayfa, tab'lı, ikon seçicili, çok dilli form
// Oluşturulma Tarihi: 2024-06-09
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-06-09

import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MenuEditPage extends StatefulWidget {
  final Map<String, dynamic>? menu;
  final int? parentId;
  const MenuEditPage({Key? key, this.menu, this.parentId}) : super(key: key);

  @override
  State<MenuEditPage> createState() => _MenuEditPageState();
}

class _MenuEditData {
  String title;
  String? description;
  String? titleEn;
  String? descriptionEn;
  String? titleAr;
  String? descriptionAr;
  String? titleRu;
  String? descriptionRu;
  String? route;
  String? moduleName;
  int? parentId;
  bool isFavorite;
  bool isVisible;
  IconData icon;
  _MenuEditData({
    required this.title,
    this.description,
    this.titleEn,
    this.descriptionEn,
    this.titleAr,
    this.descriptionAr,
    this.titleRu,
    this.descriptionRu,
    this.route,
    this.moduleName,
    this.parentId,
    this.isFavorite = false,
    this.isVisible = true,
    required this.icon,
  });
}

final List<IconData> _iconOptions = [
  Icons.menu,
  Icons.home,
  Icons.star,
  Icons.settings,
  Icons.people,
  Icons.shopping_cart,
  Icons.business,
  Icons.folder,
  Icons.dashboard,
  Icons.bookmark,
  Icons.event,
  Icons.info,
  Icons.list,
  Icons.lock,
  Icons.map,
  Icons.phone,
  Icons.school,
  Icons.work,
  Icons.wifi,
  Icons.account_circle
];

class _MenuEditPageState extends State<MenuEditPage> {
  final _formKey = GlobalKey<FormState>();
  late _MenuEditData data;
  bool _isSaving = false;

  // Controllerlar
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

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    data = _MenuEditData(
      title: menu?['title'] ?? '',
      description: menu?['description'],
      titleEn: menu?['title_en'],
      descriptionEn: menu?['description_en'],
      titleAr: menu?['title_ar'],
      descriptionAr: menu?['description_ar'],
      titleRu: menu?['title_ru'],
      descriptionRu: menu?['description_ru'],
      route: menu?['route'],
      moduleName: menu?['module_name'],
      parentId: widget.parentId ?? menu?['parent_id'],
      isFavorite: menu?['is_favorite'] == true,
      isVisible: menu?['is_visible'] != false,
      icon: menu != null && menu['icon'] != null
          ? IconData(menu['icon'], fontFamily: 'MaterialIcons')
          : Icons.menu,
    );
    _titleTrController = TextEditingController(text: data.title);
    _descTrController = TextEditingController(text: data.description);
    _titleEnController = TextEditingController(text: data.titleEn);
    _descEnController = TextEditingController(text: data.descriptionEn);
    _titleArController = TextEditingController(text: data.titleAr);
    _descArController = TextEditingController(text: data.descriptionAr);
    _titleRuController = TextEditingController(text: data.titleRu);
    _descRuController = TextEditingController(text: data.descriptionRu);
    _routeController = TextEditingController(text: data.route);
    _moduleNameController = TextEditingController(text: data.moduleName);
  }

  @override
  void dispose() {
    _titleTrController.dispose();
    _descTrController.dispose();
    _titleEnController.dispose();
    _descEnController.dispose();
    _titleArController.dispose();
    _descArController.dispose();
    _titleRuController.dispose();
    _descRuController.dispose();
    _routeController.dispose();
    _moduleNameController.dispose();
    super.dispose();
  }

  // Gerçek çeviri fonksiyonu (LibreTranslate API)
  Future<String> _translateText(String text, String toLang) async {
    if (text.isEmpty) return '';
    try {
      final response = await http.post(
        Uri.parse('https://libretranslate.de/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': 'tr',
          'target': toLang,
          'format': 'text',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] ?? '';
      } else {
        return text;
      }
    } catch (e) {
      return text;
    }
  }

  Future<void> _autoTranslate() async {
    if (_titleTrController.text.isEmpty && _descTrController.text.isEmpty)
      return;
    setState(() => _isSaving = true);
    _titleEnController.text =
        await _translateText(_titleTrController.text, 'en');
    _titleArController.text =
        await _translateText(_titleTrController.text, 'ar');
    _titleRuController.text =
        await _translateText(_titleTrController.text, 'ru');
    if (_descTrController.text.isNotEmpty) {
      _descEnController.text =
          await _translateText(_descTrController.text, 'en');
      _descArController.text =
          await _translateText(_descTrController.text, 'ar');
      _descRuController.text =
          await _translateText(_descTrController.text, 'ru');
    }
    setState(() => _isSaving = false);
  }

  Future<void> _showIconPicker() async {
    IconData? selectedIcon = data.icon;
    String search = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<IconData> filteredIcons = _iconOptions;
        return StatefulBuilder(
          builder: (context, setState) {
            filteredIcons = _iconOptions.where((icon) {
              final iconName = icon.toString().toLowerCase();
              return iconName.contains(search.toLowerCase());
            }).toList();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'İkon ara... (örn: home, star)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: GridView.builder(
                      itemCount: filteredIcons.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final icon = filteredIcons[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedIcon = icon);
                            data.icon = icon;
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: icon == selectedIcon
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: icon == selectedIcon
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Icon(icon,
                                size: 28,
                                color: icon == selectedIcon
                                    ? Colors.blue
                                    : Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final supabase = await SupabaseService.getInstance();
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
      'parent_id': data.parentId,
      'is_favorite': data.isFavorite,
      'is_visible': data.isVisible,
      'icon': data.icon.codePoint,
    };
    if (widget.menu != null) {
      await supabase.update('menu', menuData, widget.menu!['id'].toString());
    } else {
      menuData['display_order'] = 0; // Sıra için gerekirse ayarlanabilir
      await supabase.insert('menu', menuData);
    }
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.08), // Hafif blur/karartma
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, minWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.menu != null
                                ? 'Menü Düzenle'
                                : 'Yeni Menü Ekle',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(context, false),
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
                              style:
                                  TextStyle(fontSize: 13, color: Colors.blue)),
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
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Başlık zorunlu'
                                    : null,
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
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 0.5),
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
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 0.5),
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
                                value: data.isFavorite,
                                onChanged: (v) =>
                                    setState(() => data.isFavorite = v),
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
                                value: data.isVisible,
                                onChanged: (v) =>
                                    setState(() => data.isVisible = v),
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
                            child:
                                Icon(data.icon, size: 24, color: Colors.blue),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
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
                          onPressed: _isSaving ? null : _saveMenu,
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
                              : const Text('Ekle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
