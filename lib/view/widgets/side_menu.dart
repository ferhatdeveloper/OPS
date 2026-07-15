import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/menu_service.dart';
import '../../viewmodel/dashboard_provider.dart';
import '../../core/utils/color_utils.dart';
import '../widgets/tab_page.dart';
import '../../service/language_service.dart';
import '../../core/localization/app_localization.dart';
import '../settings/sync_log_screen.dart';

/// Bu widget yan menüyü gösterir
/// Veritabanından çekilen menü verilerini kullanır
class SideMenu extends ConsumerStatefulWidget {
  final bool isExpanded;
  final Function(bool) onToggle;
  final Function() onClose;
  final int? selectedIndex;
  final Function(int)? onMenuItemSelected;

  const SideMenu({
    Key? key,
    this.isExpanded = true,
    required this.onToggle,
    required this.onClose,
    this.selectedIndex,
    this.onMenuItemSelected,
  }) : super(key: key);

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {
  final menuTextStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Ana menü ve alt menüler için veri yapıları
  List<MenuItemData> _mainMenuItems = [];
  final Map<String, List<SubMenuItemData>> _allSubMenus = {};
  String _selectedMenu = '';
  bool _isLoading = true;
  final Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _loadAllMenuData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dil değişikliğini dinle
    final locale = ref.watch(localeProvider);
    _loadAllMenuData(
      locale.languageCode,
    ); // Dil değiştiğinde menüyü yeniden yükle
  }

  // Tüm menü verilerini tek seferde yükle
  Future<void> _loadAllMenuData([String? languageCode]) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Servisi başlat
      await MenuService.initialize();

      // 2. Ana menü öğelerini yükle
      _mainMenuItems = await MenuService.getMainMenuItems(
        languageCode: languageCode,
      );

      // 3. Tüm alt menüleri paralel olarak yükle
      await _loadAllSubmenus(languageCode);

      // 4. İşlem tamamlandı
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Menü yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Tüm alt menüleri tek seferde ve paralel olarak yükle
  Future<void> _loadAllSubmenus([String? languageCode]) async {
    try {
      final futures = <Future>[];

      for (final menuItem in _mainMenuItems) {
        final future = MenuService.getSubMenuItems(
          menuItem.title,
          languageCode: languageCode,
        ).then((submenus) {
          _allSubMenus[menuItem.title] = submenus;
        });
        futures.add(future);
      }

      // Tüm yükleme işlemlerini paralel olarak bekle
      await Future.wait(futures);
    } catch (e) {
      print("Alt menüler yüklenirken hata: $e");
    }
  }

  // Alt menüyü seç ve genişlet/daralt
  void _toggleMenu(String title) {
    setState(() {
      // Genişletme durumunu tersine çevir
      final isCurrentlyExpanded = _expandedState[title] ?? false;

      // Önceki seçili menüyü kapat (tek açık menü olsun)
      if (_selectedMenu.isNotEmpty && _selectedMenu != title) {
        _expandedState[_selectedMenu] = false;
      }

      _selectedMenu = title;
      _expandedState[title] = !isCurrentlyExpanded;
    });
  }

  // Bir menü öğesi genişletilmiş mi kontrol et
  bool _isExpanded(String title) {
    return _expandedState[title] ?? false;
  }

  // Alt menü öğesine tıklandığında yeni tab oluştur
  void _openMenuItem(SubMenuItemData item) {
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    // Sistem Logları için özel case
    if (item.title == 'Sistem Logları' || item.route == '/system/logs') {
      dashboardNotifier.addTab(
        TabPage(
          title: item.title,
          icon: item.icon,
          content: SyncLogScreen(),
        ),
      );
      return;
    }

    // Yeni bir tab ekle
    dashboardNotifier.addTab(
      TabPage(
        title: item.title,
        icon: item.icon,
        content: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '${item.title} sayfası',
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
              Text(
                'Rota: ${item.route}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                item.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuBackgroundColor = const Color(0xFF4A6583);
    final menuHeaderColor = const Color(0xFF2B3A4A);

    // Return the compact version if not expanded
    if (!widget.isExpanded) {
      return _buildCompactView(context, menuBackgroundColor, menuHeaderColor);
    }

    // Return the expanded version
    return _buildExpandedView(context, menuBackgroundColor, menuHeaderColor);
  }

  // Build the compact view version of the side menu
  Widget _buildCompactView(
    BuildContext context,
    Color menuBackgroundColor,
    Color menuHeaderColor,
  ) {
    return Container(
      color: menuBackgroundColor,
      child: Column(
        children: [
          // Menu header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: menuHeaderColor,
              boxShadow: [
                BoxShadow(
                  color: ColorUtils.withAlpha(Colors.black, 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            height: 50, // Fixed height to match AppBar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon-only indicator to show menu is in compact mode
                const Icon(
                  Icons.view_headline,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : ListView.builder(
                      itemCount: _mainMenuItems.length,
                      itemBuilder: (context, index) {
                        final menuItem = _mainMenuItems[index];
                        return _buildCompactMenuItem(
                          context,
                          menuItem.title,
                          menuItem.icon,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Build the expanded version of the side menu
  Widget _buildExpandedView(
    BuildContext context,
    Color menuBackgroundColor,
    Color menuHeaderColor,
  ) {
    return Container(
      color: menuBackgroundColor,
      child: Column(
        children: [
          // Menu header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: menuHeaderColor,
              boxShadow: [
                BoxShadow(
                  color: ColorUtils.withAlpha(Colors.black, 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            height: 50, // Fixed height to match AppBar
            child: Row(
              children: [
                // Menu title
                const Text(
                  'Menü',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    widget.isExpanded
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: ColorUtils.withAlpha(Colors.white, 0.9),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onToggle(!widget.isExpanded),
                  tooltip: widget.isExpanded ? 'Daralt' : 'Genişlet',
                ),
              ],
            ),
          ),

          // Modern search box
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorUtils.withAlpha(Colors.white, 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorUtils.withAlpha(Colors.white, 0.1),
                width: 1,
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: 'Menüde Ara...',
                hintStyle: TextStyle(
                  color: ColorUtils.withAlpha(Colors.white, 0.6),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: ColorUtils.withAlpha(Colors.white, 0.6),
                ),
              ),
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),

          // Menu items
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : ListView.builder(
                      itemCount: _mainMenuItems.length,
                      itemBuilder: (context, index) {
                        final menuItem = _mainMenuItems[index];
                        return _buildMenuItem(
                          context,
                          menuItem.title,
                          menuItem.icon,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a compact menu item
  Widget _buildCompactMenuItem(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final isSelected = _selectedMenu == title;

    return Tooltip(
      message: title,
      child: InkWell(
        onTap: () => _toggleMenu(title),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: ColorUtils.withAlpha(Colors.white, 0.05),
                width: 1,
              ),
            ),
            color:
                isSelected
                    ? ColorUtils.withAlpha(Colors.white, 0.1)
                    : Colors.transparent,
          ),
          child: Icon(
            icon,
            color:
                isSelected
                    ? Colors.white
                    : ColorUtils.withAlpha(Colors.white, 0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  // Menü öğesini oluştur (genişletilebilir gruplar)
  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    final isSelected = _selectedMenu == title;
    final isExpanded = _isExpanded(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ana menü başlığı - tıklanabilir
        InkWell(
          onTap: () => _toggleMenu(title),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? ColorUtils.withAlpha(Colors.white, 0.1)
                      : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: ColorUtils.withAlpha(Colors.white, 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: ColorUtils.withAlpha(Colors.white, 0.9),
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: ColorUtils.withAlpha(Colors.white, 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        // Alt menüler - sadece genişletildiğinde göster
        if (isExpanded) _buildSubMenus(title),
      ],
    );
  }

  // Alt menü öğelerini oluştur
  Widget _buildSubMenus(String parentTitle) {
    // Alt menü listesini al (önceden yüklenmiş olmalı)
    final submenus = _allSubMenus[parentTitle] ?? [];

    // Alt menü yoksa yükleniyor göster
    if (submenus.isEmpty) {
      // Son bir deneme daha yap ve dil kodunu al
      LanguageService.getLanguagePreference().then((languageCode) {
        MenuService.getSubMenuItems(
          parentTitle,
          languageCode: languageCode,
        ).then((items) {
          if (items.isNotEmpty && mounted) {
            setState(() {
              _allSubMenus[parentTitle] = items;
            });
          }
        });
      });

      return Container(
        color: ColorUtils.withAlpha(Colors.black, 0.05),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    // Alt menü öğelerini oluştur
    return Container(
      color: ColorUtils.withAlpha(Colors.black, 0.05),
      child: Column(
        children:
            submenus
                .map(
                  (submenu) => ListTile(
                    leading: const Icon(
                      Icons.circle,
                      color: Colors.white54,
                      size: 8,
                    ),
                    title: Text(
                      submenu.title,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 28),
                    onTap: () => _openMenuItem(submenu),
                  ),
                )
                .toList(),
      ),
    );
  }
}

// Boş içerik göstermek için yardımcı widget
class EmptyTabContent extends StatelessWidget {
  final String title;
  final String description;

  const EmptyTabContent({
    Key? key,
    required this.title,
    this.description = 'Bu modül için içerik henüz eklenmedi.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 64,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
