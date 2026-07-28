import 'package:flutter/material.dart';

/// Constants class that defines all menu items throughout the app
/// This ensures consistency across different screens
class MenuConstants {
  // Main menu items that are used on all screens - Logo Muhasebe Style
  static final List<MenuItemData> mainMenuItems = [];

  // Favorite/quick access menu items
  static final List<FavoriteItemData> favoriteItems = [];

  // Module cards for the home screen - using the same main menu from desktop version
  static final List<ModuleCardData> moduleCards = [];
}

/// Data class for menu items with submenus
class MenuItemData {
  final String title;
  final IconData icon;
  final List<String> submenus;

  const MenuItemData({
    required this.title,
    required this.icon,
    required this.submenus,
  });

  // Convert to Map for easier manipulation
  Map<String, dynamic> toMap() {
    return {'title': title, 'icon': icon, 'submenus': submenus};
  }
}

/// Data class for favorite menu items
class FavoriteItemData {
  final String title;
  final IconData icon;

  /// Menü seed `route` — boşsa dashboard title-switch kullanılır
  final String route;

  const FavoriteItemData({
    required this.title,
    required this.icon,
    this.route = '',
  });
}

/// Home grid alt menü öğesi — seed `route` ile navigasyon
class ModuleSubmenuItem {
  final String title;

  /// Menü seed `route` — boşsa dashboard title-switch kullanılır
  final String route;

  /// [uuid]: SQLite menu.uuid (`sub_*`) — rol alt menü filtresi
  final String uuid;

  const ModuleSubmenuItem({
    required this.title,
    this.route = '',
    this.uuid = '',
  });

  Map<String, dynamic> toMap() {
    return {'title': title, 'route': route, 'uuid': uuid};
  }
}

/// Data class for module cards
class ModuleCardData {
  /// [id]: SQLite menu.id — favori toggle için (0 = sentetik kart)
  final int id;

  /// [uuid]: SQLite menu.uuid (`fs_*`) — rol menü filtresi
  final String uuid;

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ModuleSubmenuItem> submenus;

  /// [isFavorite]: Kullanıcı kalp ile işaretledi mi (`menu.is_favorite`)
  final bool isFavorite;

  const ModuleCardData({
    this.id = 0,
    this.uuid = '',
    required this.title,
    required this.subtitle,
    required this.icon,
    this.submenus = const [],
    this.isFavorite = false,
  });

  // Convert to Map for easier manipulation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'submenus': submenus.map((s) => s.toMap()).toList(),
      'isFavorite': isFavorite,
    };
  }
}
