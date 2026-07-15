import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../core/constants/menu_constants.dart';
import '../core/localization/app_localization.dart';
import 'database_service.dart';

/// Menu service to provide consistent menus across the app
class MenuService {
  static DatabaseService? _databaseService;
  static bool _isInitialized = false;

  // Önbellek mekanizması
  static Map<String, dynamic> _cache = {};

  // İstek sayısını azaltmak için kullanılan bayrak
  static bool _isPreloading = false;
  static bool _preloadCompleted = false;

  /// Servis başlatma - tüm verileri tek seferde yükler
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _databaseService = await DatabaseService.getInstance();
      _isInitialized = true;

      // Tüm menü verilerini yükle
      if (!_preloadCompleted) {
        await preloadAllMenuData();
      }
    }
  }

  /// Tüm menü verilerini önceden yükle
  static Future<void> preloadAllMenuData() async {
    // Şu anda yükleniyorsa, bekleyen işlem tamamlanana kadar yeni yükleme başlatma
    if (_isPreloading) return;

    _isPreloading = true;

    try {
      // Desteklenen tüm diller için menu verilerini yükle
      final languages = ['tr', 'en']; // Desteklenen diller

      for (final language in languages) {
        // Ana menüleri ve tüm alt menüleri yükle
        final menuItems = <MenuItemData>[];
        final allSubmenus = <String, List<SubMenuItemData>>{};

        // Ana menüleri ve alt menüleri paralel olarak yükle
        final mainMenus = await _databaseService!.getMainMenuItems(
          languageCode: language,
        );

        // Ana menüleri paralel olarak yükle
        final futures = <Future>[];

        // Her bir ana menü için alt menüleri yükle
        for (final menu in mainMenus) {
          final future = Future(() async {
            final menuId = menu['id'] as int;
            final title = menu['title'] as String;
            final iconName = menu['icon'] as String? ?? 'circle';
            final isFavorite =
                menu['is_favorite'] != null && menu['is_favorite'] == 1;

            // Bu menüye ait alt menüleri al
            final submenuData = await _databaseService!.getSubmenusByParentId(
              menuId,
              languageCode: language,
            );
            final submenus =
                submenuData.map((sub) => sub['title'] as String).toList();

            // Ana menü öğesini oluştur
            menuItems.add(
              MenuItemData(
                id: menuId,
                title: title,
                icon: getIconFromString(iconName),
                submenus: submenus,
                isFavorite: isFavorite,
              ),
            );

            // Alt menü öğelerini oluştur
            final submenuItems = <SubMenuItemData>[];
            for (final sub in submenuData) {
              final subTitle = sub['title'] as String;
              final description = sub['description'] as String?;
              final route = sub['route'] as String?;
              final subIconName = sub['icon'] as String? ?? 'circle';

              submenuItems.add(
                SubMenuItemData(
                  title: subTitle,
                  description: description ?? '',
                  route: route ?? '',
                  icon: getIconFromString(subIconName),
                ),
              );
            }

            // Alt menüleri önbelleğe ekle
            allSubmenus[title] = submenuItems;
          });

          futures.add(future);
        }

        // Tüm yükleme işlemlerini bekle
        await Future.wait(futures);

        // Önbelleğe kaydet
        _cache['mainMenuItems_$language'] = menuItems;

        // Tüm alt menüleri önbelleğe kaydet
        for (final entry in allSubmenus.entries) {
          final cacheKey = 'submenus_${entry.key}_$language';
          _cache[cacheKey] = entry.value;
        }
      }

      _preloadCompleted = true;
    } catch (e) {
      print("Menü verilerini yüklerken hata: $e");
    } finally {
      _isPreloading = false;
    }
  }

  /// Tüm önbelleği temizle ve yeniden yükle
  static Future<void> reloadAll() async {
    await clearCache();
    await preloadAllMenuData();
  }

  /// Önbelleği temizle (sistem ayarları değiştiğinde kullanılabilir)
  static Future<void> clearCache() async {
    _cache.clear();
    _preloadCompleted = false;
    print("Menü servis: Önbellek tamamen temizlendi");
  }

  /// String'den IconData nesnesi oluştur
  static IconData getIconFromString(String iconName) {
    // Material ikonlarını eşleştir
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'attach_money':
        return Icons.attach_money;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'point_of_sale':
        return Icons.point_of_sale;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'people':
        return Icons.people;
      case 'document_scanner':
        return Icons.document_scanner;
      case 'insights':
        return Icons.insights;
      case 'badge':
        return Icons.badge;
      case 'precision_manufacturing':
        return Icons.precision_manufacturing;
      case 'settings':
        return Icons.settings;
      case 'build':
        return Icons.build;
      case 'business':
        return Icons.business;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'account_balance':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'currency_exchange':
        return Icons.currency_exchange;
      case 'inventory':
        return Icons.inventory;
      case 'miscellaneous_services':
        return Icons.miscellaneous_services;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'warehouse':
        return Icons.warehouse;
      case 'checklist':
        return Icons.checklist;
      case 'qr_code':
        return Icons.qr_code;
      case 'description':
        return Icons.description;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'list_alt':
        return Icons.list_alt;
      case 'local_offer':
        return Icons.local_offer;
      case 'directions_car':
        return Icons.directions_car;
      case 'assignment':
        return Icons.assignment;
      case 'request_quote':
        return Icons.request_quote;
      case 'storefront':
        return Icons.storefront;
      case 'contact_page':
        return Icons.contact_page;
      case 'receipt':
        return Icons.receipt;
      case 'date_range':
        return Icons.date_range;
      case 'done_all':
        return Icons.done_all;
      case 'person':
        return Icons.person;
      case 'security':
        return Icons.security;
      case 'tune':
        return Icons.tune;
      case 'backup':
        return Icons.backup;
      case 'history':
        return Icons.history;
      case 'analytics':
        return Icons.analytics;
      case 'dashboard':
        return Icons.dashboard;
      // E-Dönüşüm için ikonlar
      case 'file_present':
        return Icons.file_present;
      case 'archive':
        return Icons.archive;
      case 'fact_check':
        return Icons.fact_check;
      case 'book':
        return Icons.book;
      case 'cloud_sync':
        return Icons.cloud_sync;
      // Raporlama için ikonlar
      case 'bar_chart':
        return Icons.bar_chart;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'stacked_bar_chart':
        return Icons.stacked_bar_chart;
      case 'leaderboard':
        return Icons.leaderboard;
      case 'insert_chart':
        return Icons.insert_chart;
      case 'auto_graph':
        return Icons.auto_graph;
      case 'smart_toy':
        return Icons.smart_toy;
      // İnsan Kaynakları için ikonlar
      case 'monetization_on':
        return Icons.monetization_on;
      case 'event_available':
        return Icons.event_available;
      case 'star_rate':
        return Icons.star_rate;
      case 'school':
        return Icons.school;
      // Üretim için ikonlar
      case 'list':
        return Icons.list;
      case 'event':
        return Icons.event;
      case 'work':
        return Icons.work;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in;
      // Gelişmiş Araçlar için ikonlar
      case 'scanner':
        return Icons.scanner;
      case 'design_services':
        return Icons.design_services;
      case 'data_usage':
        return Icons.data_usage;
      case 'psychology':
        return Icons.psychology;
      case 'phone_android':
        return Icons.phone_android;
      // Sektörel için ikonlar
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'store':
        return Icons.store;
      case 'handyman':
        return Icons.handyman;
      case 'hotel':
        return Icons.hotel;
      case 'medical_services':
        return Icons.medical_services;
      case 'content_cut':
        return Icons.content_cut;
      // Diğer eksik ikonlar
      case 'computer':
        return Icons.computer;
      case 'storage':
        return Icons.storage;
      case 'developer_board':
        return Icons.developer_board;
      case 'supervised_user_circle':
        return Icons.supervised_user_circle;
      case 'hub':
        return Icons.hub;
      case 'star':
        return Icons.star;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'location_on':
        return Icons.location_on;
      case 'qr_code_scanner':
        return Icons.qr_code_scanner;
      case 'sync':
        return Icons.sync;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.circle;
    }
  }

  /// Ana menüleri getir
  static Future<List<MenuItemData>> getMainMenuItems({
    String? languageCode,
  }) async {
    await initialize();

    // Önbellekten döndür eğer mevcutsa
    final cacheKey = 'mainMenuItems_${languageCode ?? 'tr'}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<MenuItemData>;
    }

    // Veritabanından al
    final mainMenus = await _databaseService!.getMainMenuItems(
      languageCode: languageCode,
    );
    final menuItems = <MenuItemData>[];

    for (final menu in mainMenus) {
      final menuId = menu['id'] as int;
      final title = menu['title'] as String;
      final iconName = menu['icon'] as String? ?? 'circle';
      final isFavorite =
          menu['is_favorite'] != null && menu['is_favorite'] == 1;

      // Alt menüleri al
      final submenuData = await _databaseService!.getSubmenusByParentId(
        menuId,
        languageCode: languageCode,
      );
      final submenus =
          submenuData.map((sub) => sub['title'] as String).toList();

      menuItems.add(
        MenuItemData(
          id: menuId,
          title: title,
          icon: getIconFromString(iconName),
          submenus: submenus,
          isFavorite: isFavorite,
        ),
      );
    }

    // Önbelleğe kaydet
    _cache[cacheKey] = menuItems;

    return menuItems;
  }

  /// Sık kullanılan menüleri getir
  static Future<List<FavoriteMenuItem>> getFavoriteMenuItems({
    String? languageCode,
  }) async {
    await initialize();

    // Önbellekten döndür eğer mevcutsa
    final cacheKey = 'favoriteMenuItems_${languageCode ?? 'tr'}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<FavoriteMenuItem>;
    }

    final favoriteItems = await _databaseService!.getFavoriteMenuItems();
    final menuItems = <FavoriteMenuItem>[];

    for (final item in favoriteItems) {
      final menuId = item['id'] as int;
      String title = item['title'] as String;
      String? description = item['description'] as String?;

      // Dil kontrolü
      if (languageCode == 'en' && item['title_en'] != null) {
        title = item['title_en'] as String;
      }

      if (languageCode == 'en' && item['description_en'] != null) {
        description = item['description_en'] as String?;
      }

      final route = item['route'] as String?;
      final iconName = item['icon'] as String? ?? 'circle';
      final parentId = item['parent_id'] as int?;

      menuItems.add(
        FavoriteMenuItem(
          id: menuId,
          title: title,
          description: description ?? '',
          route: route ?? '',
          icon: getIconFromString(iconName),
          parentId: parentId,
        ),
      );
    }

    // Önbelleğe kaydet
    _cache[cacheKey] = menuItems;

    return menuItems;
  }

  /// Menü öğesini sık kullanılanlara ekle veya çıkar
  static Future<void> toggleFavoriteMenuItem(
    int menuId,
    bool isFavorite,
  ) async {
    await initialize();

    await _databaseService!.toggleFavoriteMenuItem(menuId, isFavorite);

    // Önbelleği tamamen temizle
    await clearCache();
  }

  /// Seçilen menü öğelerini sık kullanılan olarak işaretle
  static Future<void> updateFavoriteMenuItems(List<int> menuIds) async {
    await initialize();

    await _databaseService!.updateFavoriteMenuItems(menuIds);

    // Önbelleği tamamen temizle
    await clearCache();

    // Preload işlemini yeniden başlat
    _preloadCompleted = false;
    await preloadAllMenuData();

    print("Menü servis: Sık kullanılanlar güncellendi ve önbellek yenilendi");
  }

  /// Alt menüleri getir - önbellekli versiyonu
  static Future<List<SubMenuItemData>> getSubMenuItems(
    String parentTitle, {
    String? languageCode,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Önbellekte varsa oradan dön
    final cacheKey = 'submenus_${parentTitle}_${languageCode ?? 'tr'}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<SubMenuItemData>;
    }

    // Eğer önbellekte yoksa ve preload tamamlanmadıysa, yüklemeyi başlat
    if (!_preloadCompleted) {
      await preloadAllMenuData();
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as List<SubMenuItemData>;
      }
    }

    final result = <SubMenuItemData>[];

    try {
      // Önce ana menüleri al
      final mainMenus = await _databaseService!.getMainMenuItems(
        languageCode: languageCode,
      );

      // İlgili ana menüyü bul
      final parentMenu = mainMenus.firstWhere(
        (menu) => menu['title'] == parentTitle,
        orElse: () => {},
      );

      if (parentMenu.isEmpty) {
        return [];
      }

      // Bu menüye ait alt menüleri al
      final parentId = parentMenu['id'] as int;
      final submenus = await _databaseService!.getSubmenusByParentId(
        parentId,
        languageCode: languageCode,
      );

      for (final submenu in submenus) {
        final title = submenu['title'] as String;
        final description = submenu['description'] as String?;
        final route = submenu['route'] as String?;
        final iconName = submenu['icon'] as String? ?? 'circle';

        result.add(
          SubMenuItemData(
            title: title,
            description: description ?? '',
            route: route ?? '',
            icon: getIconFromString(iconName),
          ),
        );
      }

      // Sonucu önbelleğe kaydet
      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      print("Alt menü verileri getirilirken hata: $e");
      return [];
    }
  }

  // Get main menu items with translations
  static List<Map<String, dynamic>> getMainMenuItemsWithTranslations(
    BuildContext context,
  ) {
    return []; // Boş liste döndür
  }

  // Get favorite menu items
  static List<FavoriteItemData> getFavoriteItems() {
    return []; // Boş liste döndür
  }

  // Get favorite menu items with translations
  static List<FavoriteItemData> getFavoriteItemsWithTranslations(
    BuildContext context,
  ) {
    return []; // Boş liste döndür
  }

  // Get module cards for the home screen
  static List<ModuleCardData> getModuleCards() {
    return MenuConstants.moduleCards;
  }

  // Veritabanından tüm modül kartlarını al
  static Future<List<ModuleCardData>> getMobileModuleCards({
    String? languageCode,
  }) async {
    await initialize();

    // Önbellekten döndür eğer mevcutsa
    final cacheKey = 'mobileModuleCards_${languageCode ?? 'tr'}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<ModuleCardData>;
    }

    final result = <ModuleCardData>[];

    try {
      // Ana menüleri al
      final mainMenus = await _databaseService!.getMainMenuItems(
        languageCode: languageCode,
      );

      for (final menu in mainMenus) {
        final menuId = menu['id'] as int;
        final title = menu['title'] as String;
        final iconName = menu['icon'] as String? ?? 'circle';
        final description = menu['description'] as String? ?? '';

        // Bu menüye ait alt menüleri al
        final submenuData = await _databaseService!.getSubmenusByParentId(
          menuId,
          languageCode: languageCode,
        );
        final submenus =
            submenuData.map((sub) => sub['title'] as String).toList();

        result.add(
          ModuleCardData(
            title: title,
            subtitle: description,
            icon: getIconFromString(iconName),
            submenus: submenus,
          ),
        );
      }

      // Önbelleğe kaydet
      _cache[cacheKey] = result;

      return result;
    } catch (e) {
      print("Mobil modül verileri getirilirken hata: $e");
      return [];
    }
  }

  // Veritabanından sık kullanılan menü öğelerini al
  static Future<List<FavoriteItemData>> getMobileFavoriteItems() async {
    await initialize();

    // Önbellekten döndür eğer mevcutsa
    if (_cache.containsKey('mobileFavoriteItems')) {
      return _cache['mobileFavoriteItems'] as List<FavoriteItemData>;
    }

    final result = <FavoriteItemData>[];

    try {
      // Sık kullanılan menüleri al (is_favorite = 1 olanlar)
      final favoriteItems = await _databaseService!.getFavoriteMenuItems();

      for (final item in favoriteItems) {
        final title = item['title'] as String;
        final iconName = item['icon'] as String? ?? 'circle';

        result.add(
          FavoriteItemData(title: title, icon: getIconFromString(iconName)),
        );
      }

      // Önbelleğe kaydet
      _cache['mobileFavoriteItems'] = result;

      return result;
    } catch (e) {
      print("Mobil sık kullanılan menü öğeleri getirilirken hata: $e");
      return [];
    }
  }

  // Get module cards with translations
  static List<ModuleCardData> getModuleCardsWithTranslations(
    BuildContext context,
  ) {
    return MenuConstants.moduleCards.map((card) {
      final translatedTitle = AppLocalization.of(context).translate(card.title);
      final translatedSubtitle = AppLocalization.of(
        context,
      ).translate(card.subtitle);

      // Translate submenus
      final translatedSubmenus = card.submenus
          .map((submenu) => AppLocalization.of(context).translate(submenu))
          .toList();

      return ModuleCardData(
        title: translatedTitle,
        subtitle: translatedSubtitle,
        icon: card.icon,
        submenus: translatedSubmenus,
      );
    }).toList();
  }

  /// Kullanıcı ve şirkete göre ana menüleri getir
  static Future<List<MenuItemData>> getMainMenuItemsByUserAndCompany({
    required String userId,
    required int companyNo,
    String? languageCode,
  }) async {
    await initialize();
    final menus = await _databaseService!.getMenusByUserAndCompany(
      userId: userId,
      companyNo: companyNo,
      languageCode: languageCode,
    );
    // Sadece ana menüler (parent_id == null)
    final mainMenus = menus.where((m) => m['parent_id'] == null).toList();
    return mainMenus.map((menu) {
      final menuId = menu['id'] as int;
      final title = menu['title'] as String;
      final iconName = menu['icon'] as String? ?? 'circle';
      final isFavorite =
          menu['is_favorite'] != null && menu['is_favorite'] == 1;
      // Alt menüler (bu fonksiyonda boş bırakılır, alt menü fonksiyonu ile doldurulacak)
      return MenuItemData(
        id: menuId,
        title: title,
        icon: getIconFromString(iconName),
        submenus: [],
        isFavorite: isFavorite,
      );
    }).toList();
  }

  /// Kullanıcı ve şirkete göre alt menüleri getir
  static Future<List<SubMenuItemData>> getSubMenuItemsByUserAndCompany({
    required String userId,
    required int companyNo,
    required int parentId,
    String? languageCode,
  }) async {
    await initialize();
    final menus = await _databaseService!.getMenusByUserAndCompany(
      userId: userId,
      companyNo: companyNo,
      languageCode: languageCode,
    );
    // Alt menüler (parent_id == parentId)
    final subMenus = menus.where((m) => m['parent_id'] == parentId).toList();
    return subMenus.map((menu) {
      final title = menu['title'] as String;
      final description = menu['description'] as String?;
      final route = menu['route'] as String?;
      final iconName = menu['icon'] as String? ?? 'circle';
      return SubMenuItemData(
        title: title,
        description: description ?? '',
        route: route ?? '',
        icon: getIconFromString(iconName),
      );
    }).toList();
  }
}

/// Provider for favorite items that can be updated throughout the app
final favoriteItemsProvider =
    StateNotifierProvider<FavoriteItemsNotifier, List<FavoriteItemData>>(
  (ref) => FavoriteItemsNotifier(),
);

class FavoriteItemsNotifier extends StateNotifier<List<FavoriteItemData>> {
  FavoriteItemsNotifier() : super(MenuConstants.favoriteItems);

  void addFavorite(FavoriteItemData item) {
    // Don't add duplicates
    if (state.any((element) => element.title == item.title)) {
      return;
    }
    state = [...state, item];
  }

  void removeFavorite(String title) {
    state = state.where((item) => item.title != title).toList();
  }

  void reorderFavorites(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = state[oldIndex];
    final newList = List<FavoriteItemData>.from(state);
    newList.removeAt(oldIndex);
    newList.insert(newIndex, item);

    state = newList;
  }
}

/// Provider for expanded menu state
final expandedMenuIndexProvider = StateProvider<int?>((ref) => null);

/// Ana menü öğesi veri modeli
class MenuItemData {
  final int id;
  final String title;
  final IconData icon;
  final List<String> submenus;
  final bool isFavorite;

  MenuItemData({
    required this.id,
    required this.title,
    required this.icon,
    required this.submenus,
    required this.isFavorite,
  });
}

/// Alt menü öğesi veri modeli
class SubMenuItemData {
  final String title;
  final String description;
  final String route;
  final IconData icon;

  SubMenuItemData({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });
}

/// Sık kullanılan menü öğesi veri modeli
class FavoriteMenuItem {
  final int id;
  final String title;
  final String description;
  final String route;
  final IconData icon;
  final int? parentId;

  FavoriteMenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    this.parentId,
  });
}
