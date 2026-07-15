// filepath: d:/Developer/EXFINERP/lib/view/dashboard_screen_updated.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'widgets/side_menu.dart';
import 'widgets/custom_tab_bar.dart';
import 'widgets/tab_page.dart';
import 'widgets/shortcut_grid.dart';
import '../viewmodel/dashboard_provider.dart';
import '../modules/inventory/view/materials_screen.dart';
import '../service/menu_service.dart';
import '../core/utils/color_utils.dart';
import '../core/localization/app_localization.dart';
import '../service/language_service.dart';
import 'widgets/calculator_widget.dart';
import '../service/database_service.dart';
import '../service/auth_service.dart';
import '../core/providers/loading_provider.dart';
import 'dart:async';

// EXFIN Renkleri
const Color exfinDarkBlue = Color.fromARGB(255, 5, 79, 153); // Koyu lacivert
const Color exfinRed = Color(0xFFFF0000); // Tam kırmızı renk
const Color exfinLightBlue = Color(0xFF3498DB); // Açık mavi
const Color surfaceColor = Color(0xFFF9FAFB);
const Color textColorPrimary = Color(0xFF1F2937);
const Color textColorSecondary = Color(0xFF6B7280);
const Color menuBackgroundColor = Color(0xFF4A6583);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool isMenuExpanded = true;
  bool isMenuVisible = true;
  final String currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
  int selectedMenuIndex = -1; // To track selected menu item
  List<FavoriteMenuItem> _favoriteMenuItems = [];
  Map<String, dynamic> _companyInfo = {
    'name': 'LOGO',
    'branch': '3-MARKET',
    'period': '2025',
    'license_start': '01.01.2025',
    'license_end': '31.12.2025',
  };
  String? _userName;
  List<dynamic> _availablePeriods = [];

  @override
  void initState() {
    super.initState();
    DatabaseService.getInstance().then((db) => db.ensureAllTables());
    _initializeLanguage();
    _initializeMenu();
    _loadFavorites();
    _syncAndLoadCompanyInfo();
    _startForceLogoutListener();
    _loadUserAndCompanyInfo();
  }

  // Dil ayarlarını veritabanından yükle
  Future<void> _initializeLanguage() async {
    final languageCode = await LanguageService.getLanguagePreference();

    Locale newLocale;
    if (languageCode.contains('-')) {
      final parts = languageCode.split('-');
      newLocale = Locale(parts[0], parts[1].toUpperCase());
    } else {
      newLocale = Locale(languageCode);
    }

    // Provider'ı güncelle
    if (mounted) {
      ref.read(localeProvider.notifier).setLocale(newLocale);
    }
  }

  // Menü servisini başlat
  Future<void> _initializeMenu() async {
    await MenuService.initialize();
  }

  // Menü veritabanını sıfırla (sadece geliştirme aşamasında)
  Future<void> _resetMenuDatabase() async {
    try {
      final db = await DatabaseService.getInstance();
      await db.resetMenuDatabase();
      // Önbelleği temizle
      MenuService.clearCache();
      // Servisi yeniden başlat
      await MenuService.initialize();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Menü veritabanı başarıyla sıfırlandı. Uygulamayı yeniden başlatın.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await MenuService.getFavoriteMenuItems();
      setState(() {
        _favoriteMenuItems = favorites;
      });
    } catch (e) {
      print('Sık kullanılanlar yüklenirken hata: $e');
    }
  }

  Future<void> _syncAndLoadCompanyInfo() async {
    try {
      final db = await DatabaseService.getInstance();
      final session = await db.getUserSession();
      final userId = session?['id'];
      if (userId != null) {
        // Önce tabloyu zorla sıfırla (debug için)
        await db.forceResetCompaniesTable();
        // Sonra senkronizasyonu yap
        await db.syncUserCompaniesWithSupabaseIfOnline(userId);
        // Dönemleri de senkronize et
        await db.syncCompanyPeriodsWithSupabaseIfOnline();
      }
      await _loadCompanyInfo();
    } catch (e) {
      print('Şirket senkronizasyonu sırasında hata: $e');
      await _loadCompanyInfo();
    }
  }

  // Firma bilgilerini yükle
  Future<void> _loadCompanyInfo() async {
    try {
      final db = await DatabaseService.getInstance();
      final companyInfo = await db.getCompanyInfo();
      if (mounted) {
        setState(() {
          _companyInfo = companyInfo;
        });
        print('YÜKLENEN FİRMA BİLGİSİ: $_companyInfo');
        // Firma bilgisi geldikten sonra dönem kontrolü yap
        _checkAndPromptPeriod();
      }
    } catch (e) {
      print('Firma bilgileri yüklenirken hata: $e');
    }
  }

  Future<void> _startForceLogoutListener() async {
    final db = await DatabaseService.getInstance();
    final session = await db.getUserSession();
    final userId = session?['id'];
    if (userId != null) {
      AuthService.startForceLogoutListener(context, ref, userId);
    }
  }

  Future<void> _loadUserAndCompanyInfo() async {
    print('DEBUG: _loadUserAndCompanyInfo başladı');
    final db = await DatabaseService.getInstance();
    final session = await db.getUserSession();
    setState(() {
      _userName = session?['full_name'] ?? session?['username'] ?? 'Kullanıcı';
    });
    print('DEBUG: Kullanıcı adı: $_userName');

    // Tüm dönemleri company_period tablosundan çek (period_name, start_date, end_date)
    try {
      final allPeriods = await db.getAllPeriodsWithDates();
      print('DEBUG: Tüm dönemler: $allPeriods');
      if (allPeriods.isNotEmpty) {
        setState(() {
          _availablePeriods = allPeriods;
        });
        print('DEBUG: Tüm dönemlerden alınan: $_availablePeriods');
      } else {
        setState(() {
          _availablePeriods = [];
        });
      }
    } catch (e) {
      print('DEBUG: Tüm dönemler çekilirken hata: $e');
      setState(() {
        _availablePeriods = [];
      });
    }
    print('DEBUG: _loadUserAndCompanyInfo tamamlandı, dönem sayısı: ${_availablePeriods.length}');
  }

  Future<void> _checkAndPromptPeriod() async {
    print('DEBUG: _checkAndPromptPeriod çağrıldı');
    print('DEBUG: Mevcut period: [38;5;208m${_companyInfo['period']}[0m');
    print('DEBUG: Mevcut dönemler: $_availablePeriods');
    
    if (_companyInfo['period'] == null || _companyInfo['period'].toString().isEmpty) {
      // Eğer dönem listesi boşsa, önce dönemleri yükle
      if (_availablePeriods.isEmpty) {
        print('DEBUG: Dönem listesi boş, dönemler yükleniyor...');
        await _loadUserAndCompanyInfo();
      }
      
      // Hala boşsa, varsayılan dönemler ekle
      if (_availablePeriods.isEmpty) {
        print('DEBUG: Hala dönem listesi boş, varsayılan dönemler ekleniyor...');
        setState(() {
          _availablePeriods = [
            {'period_name': '2024', 'start_date': '', 'end_date': ''},
            {'period_name': '2025', 'start_date': '', 'end_date': ''},
            {'period_name': '2026', 'start_date': '', 'end_date': ''},
          ];
        });
      }
      
      print('DEBUG: Dialog açılıyor, dönem sayısı: ${_availablePeriods.length}');
      
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(AppLocalization.of(context).translate('auth.period_selection')), // assuming 'auth.period_selection' or similar
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalization.of(context).translate('auth.select_period_to_work')),
              const SizedBox(height: 16),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: null,
                items: _availablePeriods.map<DropdownMenuItem<Map<String, dynamic>>>((d) {
                  final label = d['period_name'] ?? '';
                  final start = d['start_date'] ?? '';
                  final end = d['end_date'] ?? '';
                  final display = start.isNotEmpty && end.isNotEmpty
                      ? '$label ($start - $end)'
                      : label;
                  return DropdownMenuItem(
                    value: d,
                    child: Text(display),
                  );
                }).toList(),
                onChanged: (val) {
                  Navigator.of(context).pop(val);
                },
                decoration: const InputDecoration(
                  labelText: 'Dönem Seçin',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Varsayılan dönem seç
                Navigator.of(context).pop(_availablePeriods.first);
              },
              child: Text(AppLocalization.of(context).translate('common.default')),
            ),
            ElevatedButton(
              onPressed: () {
                // İlk dönemi seç
                Navigator.of(context).pop(_availablePeriods.first);
              },
              child: Text(AppLocalization.of(context).translate('common.select')),
            ),
          ],
        ),
      );
      
      if (selected != null) {
        final selectedPeriod = selected['period_name'] ?? '';
        print('DEBUG: Seçilen dönem: $selectedPeriod');
        setState(() {
          _companyInfo['period'] = selectedPeriod;
        });
        
        // Seçilen dönemi veritabanına kaydet
        try {
          final db = await DatabaseService.getInstance();
          await db.updateCompanyPeriod(selectedPeriod);
          print('DEBUG: Dönem veritabanına kaydedildi: $selectedPeriod');
        } catch (e) {
          print('DEBUG: Dönem kaydedilirken hata: $e');
        }
      }
    }
  }

  void _showFavoriteMenuDialog() async {
    // Tüm menü öğelerini yükle
    final allMenuItems = await _loadAllMenuItems();

    if (!mounted) return;

    // Kullanıcı tarafından seçilen menü öğelerinin ID'leri
    final selectedMenuIds = <int>[];

    // Mevcut sık kullanılanlar
    for (final item in _favoriteMenuItems) {
      selectedMenuIds.add(item.id);
    }

    print('Dialog öncesi seçili ID\'ler: $selectedMenuIds');

    // Dialog göster
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildMinimalFavoriteDialog(
        context,
        allMenuItems,
        selectedMenuIds,
      ),
    );

    // Dialog kapandıktan sonra seçilen menüleri güncelleyin
    if (result == true && selectedMenuIds.isNotEmpty) {
      print('Sık kullanılanlar kaydediliyor, ID\'ler: $selectedMenuIds');
      await MenuService.updateFavoriteMenuItems(selectedMenuIds);

      // Sık kullanılanları yeniden yükle
      await _loadFavorites();
      print(
        'Sık kullanılanlar güncellendi, toplam: ${_favoriteMenuItems.length}',
      );
    } else {
      print('Sık kullanılanlar iptal edildi veya boş liste');
    }
  }

  // Minimal sık kullanılanlar dialog'u
  Widget _buildMinimalFavoriteDialog(
    BuildContext context,
    List<MenuItemWithSubmenu> allMenuItems,
    List<int> selectedMenuIds,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Container(
            width: 500, // Genişleterek 500px yaptım
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sık Kullanılanlar',
                      style: TextStyle(
                        fontSize: 20, // Başlık boyutunu artırdım
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Boşluğu artırdım
                // Seçim bilgisi
                Text(
                  'Sık kullanılan menüleri seçin:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),

                // Menü listesi
                Container(
                  height: 450, // Yüksekliği artırdım
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.builder(
                    itemCount: allMenuItems.length,
                    itemBuilder: (context, index) {
                      final item = allMenuItems[index];
                      final isSelected = selectedMenuIds.contains(item.id);

                      // Ana menüler için ayırıcı
                      if (item.parentTitle == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index > 0) const Divider(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, // Dolguyu artırdım
                                vertical: 8, // Dolguyu artırdım
                              ),
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15, // Boyutu artırdım
                                  color: exfinDarkBlue,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Alt menüler
                      return CheckboxListTile(
                        title: Text(
                          item.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item.parentTitle} altında',
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: Icon(
                          item.icon,
                          size: 22,
                        ), // Biraz daha büyük
                        dense: true,
                        value: isSelected,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, // Dolguyu artırdım
                          vertical: 2, // Biraz dikey boşluk ekledim
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedMenuIds.add(item.id);
                            } else {
                              selectedMenuIds.remove(item.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

                // Seçim sayısı
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Seçilen öğe sayısı: ${selectedMenuIds.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // Butonlar
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Önce seçilen öğeler için doğrulama yapalım
                          if (selectedMenuIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Lütfen en az bir menü öğesi seçin',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: exfinDarkBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<MenuItemWithSubmenu>> _loadAllMenuItems() async {
    final result = <MenuItemWithSubmenu>[];

    // Ana menüleri yükle
    final mainMenus = await MenuService.getMainMenuItems();

    for (final mainMenu in mainMenus) {
      // Ana menüyü ekle
      result.add(
        MenuItemWithSubmenu(
          id: mainMenu.id,
          title: mainMenu.title,
          icon: mainMenu.icon,
          parentTitle: null,
          isFavorite: mainMenu.isFavorite,
        ),
      );

      // Alt menüleri yükle
      final submenus = await MenuService.getSubMenuItems(mainMenu.title);
      for (final submenu in submenus) {
        final submenuItem = await _getSubmenuItem(submenu.title);
        if (submenuItem != null) {
          result.add(
            MenuItemWithSubmenu(
              id: submenuItem['id'] as int,
              title: submenu.title,
              icon: submenu.icon,
              parentTitle: mainMenu.title,
              isFavorite: submenuItem['is_favorite'] == 1,
            ),
          );
        }
      }
    }

    return result;
  }

  Future<Map<String, dynamic>?> _getSubmenuItem(String title) async {
    final db = await DatabaseService.getInstance();
    final items = await db.getMenuItemByTitle(title);
    if (items.isNotEmpty) {
      return items.first;
    }
    return null;
  }

  // Define shortcut data using MenuService
  List<ShortcutData> getShortcuts(BuildContext context) {
    // Önce sık kullanılanları ekle (varsa)
    final List<ShortcutData> shortcuts = [];

    // Veritabanından sık kullanılanları ekle
    for (var favorite in _favoriteMenuItems) {
      shortcuts.add(
        ShortcutData(
          title: favorite.title,
          icon: favorite.icon,
          color: Colors.amber.shade700, // Sık kullanılanlar için farklı renk
          onTap: () => _openModule(context, favorite.title, favorite.icon),
        ),
      );
    }

    // Get favorite items from the menu service
    final favoriteItems = MenuService.getFavoriteItems();

    // Add favorites first
    for (var favorite in favoriteItems) {
      // Zaten eklenen sık kullanılanları tekrar ekleme
      if (!shortcuts.any(
        (shortcut) =>
            shortcut.title ==
            AppLocalization.of(context).translate(favorite.title),
      )) {
        shortcuts.add(
          ShortcutData(
            title: AppLocalization.of(context).translate(favorite.title),
            icon: favorite.icon,
            color: ColorUtils.getColorForIcon(favorite.icon),
            onTap: () => _openModule(
              context,
              AppLocalization.of(context).translate(favorite.title),
              favorite.icon,
            ),
          ),
        );
      }
    }

    // Use module cards for additional shortcuts
    final moduleCards = MenuService.getModuleCards();

    // Add module cards
    for (var module in moduleCards) {
      // Only add if not already in favorites to avoid duplicates
      if (!shortcuts.any(
        (shortcut) =>
            AppLocalization.of(context).translate(module.title) ==
            shortcut.title,
      )) {
        shortcuts.add(
          ShortcutData(
            title: AppLocalization.of(context).translate(module.title),
            icon: module.icon,
            color: ColorUtils.getColorForIcon(module.icon),
            onTap: () => _openModule(
              context,
              AppLocalization.of(context).translate(module.title),
              module.icon,
            ),
          ),
        );
      }
    }

    return shortcuts;
  }

  // Open module in a new tab
  void _openModule(BuildContext context, String title, IconData icon) {
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    // Create a new tab for this module with appropriate content
    Widget content;

    // Check if this is a finance-related module
    if (title == 'Malzemeler' ||
        title == 'Stok Ekstresi' ||
        title == 'Sayım') {
      content = const MaterialsScreen();
    } else {
      content = EmptyTabContent(title: title);
    }

    dashboardNotifier.addTab(
      TabPage(title: title, icon: icon, content: content),
    );
  }

  // Dashboard home builder
  Widget _buildDashboardHome(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width <= 600;

    return Column(
      children: [
        // Dashboard statistics cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: isMobile
              ? Column(
                  children: [
                    _buildStatCard(
                      context,
                      AppLocalization.of(context).translate('dashboard.today_sales'),
                      '48,250.00',
                      Icons.trending_up,
                      ColorUtils.getColorForIcon(Icons.trending_up),
                      '+12%',
                    ),
                    const SizedBox(height: 8),
                    _buildStatCard(
                      context,
                      AppLocalization.of(context).translate('manager_dashboard.open_orders'), // using already translated key
                      '23',
                      Icons.shopping_cart,
                      ColorUtils.getColorForIcon(Icons.shopping_cart),
                      '5 Gecikmiş', // will translate later if needed, but skipped for now
                    ),
                    const SizedBox(height: 8),
                    _buildStatCard(
                      context,
                      AppLocalization.of(context).translate('dashboard.active_customers'), // "active_customers"
                      '124',
                      Icons.people,
                      ColorUtils.getColorForIcon(Icons.people),
                      '+6 Yeni',
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildStatCard(
                      context,
                      AppLocalization.of(context).translate('dashboard.today_sales'),
                      '48,250.00',
                      Icons.trending_up,
                      ColorUtils.getColorForIcon(Icons.trending_up),
                      '+12%',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      context,
                      AppLocalization.of(context).translate('manager_dashboard.open_orders'),
                      '23',
                      Icons.shopping_cart,
                      ColorUtils.getColorForIcon(Icons.shopping_cart),
                      '5 Gecikmiş',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      context,
                      AppLocalization.of(context).translate('dashboard.active_customers'),
                      '124',
                      Icons.people,
                      ColorUtils.getColorForIcon(Icons.people),
                      '+6 Yeni',
                    ),
                  ],
                ),
        ),

        // Shortcuts grid using the menu service
        Expanded(
          child: ShortcutGrid(
            shortcuts: getShortcuts(context),
            crossAxisCount: isDesktop ? 10 : (isTablet ? 3 : 2),
            spacing: 16,
            onFavoritesEdit: _showFavoriteMenuDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorUtils.withAlpha(color, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: title.contains('Satış')
                          ? Colors.green
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Kullanıcıya onay soralım
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalization.of(context).translate('common.logout')),
          content: Text(AppLocalization.of(context).translate('common.logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalization.of(context).translate('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalization.of(context).translate('common.logout')),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final db = await DatabaseService.getInstance();
        await db.logout();

        if (context.mounted) {
          // Tüm sayfaları temizleyip login sayfasına yönlendir
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );

          // Başarılı çıkış mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Başarıyla çıkış yapıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForceLogoutState>(forceLogoutProvider, (prev, next) {
      if (next.isActive && next.onResult != null) {
        int secondsLeft = 15;
        Timer? timer;
        bool callbackCalled = false;
        void safeCallback(bool accepted) {
          if (!callbackCalled) {
            callbackCalled = true;
            next.onResult!(accepted);
            ref.read(forceLogoutProvider.notifier).hide();
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
                  if (secondsLeft > 0) {
                    setState(() => secondsLeft--);
                  } else {
                    timer?.cancel();
                    Navigator.of(context, rootNavigator: true).pop();
                    safeCallback(true);
                  }
                });
                return AlertDialog(
                  title: Text(AppLocalization.of(context).translate('auth.takeover_request_title')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(next.message ?? ''),
                      const SizedBox(height: 16),
                      Text(AppLocalization.of(context).translate('auth.countdown_seconds', args: {'seconds': secondsLeft.toString()}),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.of(context, rootNavigator: true).pop();
                        safeCallback(false);
                      },
                      child: Text(AppLocalization.of(context).translate('common.cancel')), // reject
                    ),
                    ElevatedButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.of(context, rootNavigator: true).pop();
                        safeCallback(true);
                      },
                      child: Text(AppLocalization.of(context).translate('common.save')), // accept
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    });

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: exfinDarkBlue,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
              'EXFİN ERP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
                FutureBuilder<String?>(
                  future: _getActivePeriodForCompany(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 16);
                    }
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      return Text(
                        snapshot.data!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      );
                    }
                    return const SizedBox(height: 16);
                  },
                ),
              ],
            ),
            const SizedBox(width: 5),
            const Text(
              '| Business Solutions',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
        leadingWidth: 48,
        leading: Container(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(
              isMenuVisible ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isMenuVisible = !isMenuVisible;
                if (isMenuVisible) {
                  isMenuExpanded = true;
                }
              });
            },
            tooltip: isMenuVisible ? 'Menüyü Gizle' : 'Menüyü Göster',
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          // Menü daraltma/genişletme düğmesi
          if (isMenuVisible && isDesktop)
            IconButton(
              icon: isMenuExpanded
                  ? const Icon(Icons.chevron_left, color: Colors.white)
                  : const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () {
                setState(() {
                  isMenuExpanded = !isMenuExpanded;
                });
              },
              tooltip: isMenuExpanded ? 'Menüyü Daralt' : 'Menüyü Genişlet',
              padding: EdgeInsets.zero,
            ),

          // Firma/dönem/kullanıcı bilgileri SAĞDA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _companyInfo['name'] ?? 'Firma seçilmedi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _companyInfo['period'] != null ? '${AppLocalization.of(context).translate('target.period')}: ${_companyInfo['period']}' : AppLocalization.of(context).translate('auth.no_period'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 16),
                Text(
                  _userName ?? AppLocalization.of(context).translate('common.user'),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // Profil menüsü
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Profil Menüsü',
            onSelected: (String value) async {
              switch (value) {
                case 'account':
                  // Hesap ayarları
                  break;
                case 'security':
                  // Güvenlik ayarları
                  break;
                case 'notifications':
                  // Bildirim ayarları
                  break;
                case 'logout':
                  // Çıkış onayı
                  await _handleLogout(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'account',
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(AppLocalization.of(context).translate('settings.account_settings')),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem<String>(
                value: 'security',
                child: ListTile(
                  leading: const Icon(Icons.security),
                  title: Text(AppLocalization.of(context).translate('settings.security')),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem<String>(
                value: 'notifications',
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(AppLocalization.of(context).translate('settings.notifications')),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(AppLocalization.of(context).translate('common.logout')),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: !isDesktop && isMenuVisible
          ? Drawer(
              child: SideMenu(
                isExpanded: true,
                onToggle: (_) {},
                onClose: () {
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Side menu - animasyonlu geçiş ile gizlenip gösterilebilir
          if (isMenuVisible && isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isMenuExpanded ? 250 : 70,
              child: SideMenu(
                isExpanded: isMenuExpanded,
                onToggle: (expanded) {
                  setState(() {
                    isMenuExpanded = expanded;
                  });
                },
                onClose: () {
                  setState(() {
                    isMenuVisible = false;
                  });
                },
                selectedIndex: selectedMenuIndex,
                onMenuItemSelected: (index) {
                  setState(() {
                    selectedMenuIndex = index;
                  });
                },
              ),
            ),

          // Main content
          Expanded(
            child: Container(
              color: surfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // License info banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: Colors.black,
                    child: const Text(
                      '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Tab navigation
                  Consumer(
                    builder: (context, ref, _) {
                      final dashboardState = ref.watch(dashboardProvider);
                      final dashboardNotifier = ref.read(
                        dashboardProvider.notifier,
                      );

                      return CustomTabBar(
                        tabs: dashboardState.tabs,
                        currentIndex: dashboardState.currentTabIndex,
                        onTabSelected: (index) =>
                            dashboardNotifier.switchToTab(index),
                        onTabClosed: (index) =>
                            dashboardNotifier.closeTab(index),
                      );
                    },
                  ),

                  // Main content area - either tabs or dashboard
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final dashboardState = ref.watch(dashboardProvider);

                        // If there are tabs and we have a valid current tab index
                        if (dashboardState.tabs.isNotEmpty &&
                            dashboardState.currentTabIndex >= 0 &&
                            dashboardState.currentTabIndex <
                                dashboardState.tabs.length) {
                          // Show the current tab
                          return TabPageView(
                            page: dashboardState
                                .tabs[dashboardState.currentTabIndex],
                          );
                        }

                        // Otherwise show the dashboard home
                        return _buildDashboardHome(
                          context,
                          isDesktop,
                          isTablet,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right sidebar (widget area in screenshot) - only show on desktop
          if (isDesktop)
            Container(
              width: 70,
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Working Date
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      // Show date picker
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                    },
                    tooltip: 'Çalışma Tarihi',
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Çalışma\nTarihi',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Calculator
                  IconButton(
                    icon: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      // Show calculator dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          contentPadding: const EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: SizedBox(
                            width: 280,
                            height: 360,
                            child: const CalculatorWidget(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Hesap Makinesi',
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Hesap\nMakinesi',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  // Menü Sıfırlama (Geliştirme Modu)
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _resetMenuDatabase,
                    tooltip: 'Menü DB Sıfırla',
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Menü\nSıfırla',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<String?> _getActivePeriodForCompany() async {
    final db = await DatabaseService.getInstance();
    final companyNo = _companyInfo['company_no']?.toString() ?? '';
    if (companyNo.isEmpty) return null;
    final periods = await db.getActivePeriodForCompany(companyNo);
    if (periods != null && periods.isNotEmpty) {
      return periods;
    }
    return null;
  }
}

// Empty tab content placeholder
class EmptyTabContent extends StatelessWidget {
  final String title;

  const EmptyTabContent({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.code, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '$title ekranı geliştirilme aşamasındadır',
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu modül henüz tamamlanmamıştır',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Ana menü ve alt menü öğelerini temsil eden sınıf
class MenuItemWithSubmenu {
  final int id;
  final String title;
  final IconData icon;
  final String? parentTitle; // Eğer alt menüyse, üst menü başlığı
  final bool isFavorite;

  MenuItemWithSubmenu({
    required this.id,
    required this.title,
    required this.icon,
    this.parentTitle,
    required this.isFavorite,
  });
}
