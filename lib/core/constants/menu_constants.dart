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

  const FavoriteItemData({required this.title, required this.icon});
}

/// Data class for module cards
class ModuleCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> submenus;

  const ModuleCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.submenus = const [],
  });

  // Convert to Map for easier manipulation
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'submenus': submenus,
    };
  }
}
