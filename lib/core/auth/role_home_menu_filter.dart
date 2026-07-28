// Dosya Adı: role_home_menu_filter.dart
// Açıklama: Rol → ana menü uuid / dens hub kısayol filtresi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import 'app_user_role.dart';

/// {@template role_home_shortcut}
/// Rol ana sayfası dens kısayolu (mevcut named route’a gider).
///
/// Kullanım örneği:
/// ```dart
/// final items = RoleHomeMenuFilter.hubShortcuts(AppUserRole.salesperson);
/// ```
/// {@endtemplate}
class RoleHomeShortcut {
  /// [id]: Stabil test / key id
  final String id;

  /// [l10nKey]: Çeviri anahtarı
  final String l10nKey;

  /// [route]: Named route
  final String route;

  /// [icon]: Material ikon
  final IconData icon;

  /// {@macro role_home_shortcut}
  const RoleHomeShortcut({
    required this.id,
    required this.l10nKey,
    required this.route,
    required this.icon,
  });
}

/// {@template role_home_menu_filter}
/// Plasiyer / depocu / admin menü görünürlüğü.
///
/// Ana menü `uuid` (`fs_*`) ve dens hub kısayollarını role göre süzer.
///
/// Kullanım örneği:
/// ```dart
/// final ok = RoleHomeMenuFilter.allowsMainMenuUuid(
///   AppUserRole.warehouseKeeper,
///   'fs_visit',
/// );
/// ```
/// {@endtemplate}
class RoleHomeMenuFilter {
  RoleHomeMenuFilter._();

  /// Plasiyer ana menü uuid seti
  static const Set<String> salespersonMainUuids = {
    'fs_favorites',
    'fs_customers',
    'fs_order',
    'fs_visit',
    'fs_finance',
    'fs_stock',
    'fs_delivery',
    'fs_other',
    'fs_currency',
    'fs_companies',
    'fs_sync',
    'fs_announcements',
    'fs_settings',
  };

  /// Depocu ana menü uuid seti (ziyaret/satış gizlenir)
  static const Set<String> warehouseMainUuids = {
    'fs_favorites',
    'fs_whms',
    'fs_stock',
    'fs_companies',
    'fs_sync',
    'fs_announcements',
    'fs_settings',
  };

  /// Depocu stok alt menü uuid’leri (saha stub — WHMS ayrı)
  static const Set<String> warehouseStockSubUuids = {
    'sub_stk_barcode',
    'sub_stk_count',
    'sub_stk_warehouse',
    'sub_stk_multi_wh',
    'sub_stk_wh_query',
    'sub_stk_wh_transfer',
    'sub_stk_movement',
    'sub_stk_detail',
    'sub_stk_transferred',
    'sub_stk_untransferred',
    'sub_stk_supply_req',
  };

  /// Depocu Depo Yönetimi (WHMS) alt menü uuid’leri
  static const Set<String> warehouseWhmsSubUuids = {
    'sub_whms_orders',
    'sub_whms_defs',
    'sub_whms_warehouses',
    'sub_whms_count',
    'sub_whms_transfer',
    'sub_whms_query',
    'sub_whms_reports',
    'sub_whms_devices',
    'sub_whms_labels',
  };

  /// Plasiyer stok alt menü (barkod + bakış)
  static const Set<String> salespersonStockSubUuids = {
    'sub_stk_barcode',
    'sub_stk_detail',
    'sub_stk_price',
  };

  /// Plasiyer “Diğer” alt menü
  static const Set<String> salespersonOtherSubUuids = {
    'sub_oth_day',
    'sub_oth_live_loc',
    'sub_oth_weekly_route',
    'sub_oth_in_app_route',
    'sub_oth_offline_map',
    'sub_oth_ai_insights',
  };

  /// Permission seed: plasiyer ana + kritik alt menüler
  static Set<String> get salespersonSeedMenuUuids => {
        ...salespersonMainUuids,
        ...salespersonOtherSubUuids,
        ...salespersonStockSubUuids,
      };

  /// Permission seed: depocu ana + stok + WHMS alt menüler
  static Set<String> get warehouseSeedMenuUuids => {
        ...warehouseMainUuids,
        ...warehouseStockSubUuids,
        ...warehouseWhmsSubUuids,
      };

  /// Ana menü uuid bu rol için görünür mü?
  ///
  /// Parametreler:
  /// - [role]: Oturum rolü
  /// - [uuid]: `menu.uuid` (fs_*)
  ///
  /// Dönüş değeri:
  /// - [bool]: true → göster
  static bool allowsMainMenuUuid(AppUserRole role, String? uuid) {
    final id = (uuid ?? '').trim();
    if (role.seesFullMenu) return true;
    // Legacy / sentetik kart (uuid yok) — gizleme
    if (id.isEmpty) return true;
    switch (role) {
      case AppUserRole.salesperson:
        return salespersonMainUuids.contains(id);
      case AppUserRole.warehouseKeeper:
        return warehouseMainUuids.contains(id);
      case AppUserRole.admin:
      case AppUserRole.supervisor:
      case AppUserRole.unknown:
        return true;
    }
  }

  /// Alt menü uuid bu rol + parent için görünür mü?
  ///
  /// Parametreler:
  /// - [role]: Oturum rolü
  /// - [parentUuid]: Üst menü uuid
  /// - [subUuid]: Alt menü uuid
  ///
  /// Dönüş değeri:
  /// - [bool]: true → göster
  static bool allowsSubMenuUuid({
    required AppUserRole role,
    required String? parentUuid,
    required String? subUuid,
  }) {
    if (role.seesFullMenu) return true;
    final parent = (parentUuid ?? '').trim();
    final sub = (subUuid ?? '').trim();
    if (sub.isEmpty) return true;

    if (role == AppUserRole.warehouseKeeper) {
      if (parent == 'fs_stock') {
        return warehouseStockSubUuids.contains(sub);
      }
      if (parent == 'fs_whms') {
        return warehouseWhmsSubUuids.contains(sub);
      }
      return true;
    }

    if (role == AppUserRole.salesperson) {
      if (parent == 'fs_whms') return false;
      if (parent == 'fs_stock') {
        return salespersonStockSubUuids.contains(sub);
      }
      if (parent == 'fs_other') {
        return salespersonOtherSubUuids.contains(sub);
      }
      if (parent == 'fs_admin') return false;
      return true;
    }

    return true;
  }

  /// Listeyi ana menü uuid’ye göre süzer.
  ///
  /// Parametreler:
  /// - [role]: Oturum rolü
  /// - [items]: Kaynak liste
  /// - [uuidOf]: Öğeden uuid okuyucu
  ///
  /// Dönüş değeri:
  /// - Filtrelenmiş liste
  static List<T> filterByMainUuid<T>({
    required AppUserRole role,
    required List<T> items,
    required String? Function(T item) uuidOf,
  }) {
    if (role.seesFullMenu) return List<T>.from(items);
    return items
        .where((e) => allowsMainMenuUuid(role, uuidOf(e)))
        .toList(growable: false);
  }

  /// Rol dens hub kısayolları (mevcut ekran route’ları).
  ///
  /// Parametreler:
  /// - [role]: Oturum rolü
  ///
  /// Dönüş değeri:
  /// - [List]<[RoleHomeShortcut]>: Hub kutucukları; admin → boş
  static List<RoleHomeShortcut> hubShortcuts(AppUserRole role) {
    switch (role) {
      case AppUserRole.salesperson:
        return const [
          RoleHomeShortcut(
            id: 'visit',
            l10nKey: 'role_home.shortcut_visit',
            route: '/field-sales/visit-existing',
            icon: Icons.location_on_outlined,
          ),
          RoleHomeShortcut(
            id: 'order',
            l10nKey: 'role_home.shortcut_order',
            route: '/field-sales/orders-sales',
            icon: Icons.shopping_cart_outlined,
          ),
          RoleHomeShortcut(
            id: 'collection',
            l10nKey: 'role_home.shortcut_collection',
            route: '/field-sales/collections',
            icon: Icons.payments_outlined,
          ),
          RoleHomeShortcut(
            id: 'route',
            l10nKey: 'role_home.shortcut_route',
            route: '/field-sales/routes/plan',
            icon: Icons.route_outlined,
          ),
          RoleHomeShortcut(
            id: 'live_location',
            l10nKey: 'role_home.shortcut_live_location',
            route: '/field-sales/gps-tracking',
            icon: Icons.my_location_outlined,
          ),
          RoleHomeShortcut(
            id: 'barcode',
            l10nKey: 'role_home.shortcut_barcode',
            route: '/field-sales/barcode-scan',
            icon: Icons.qr_code_scanner,
          ),
          RoleHomeShortcut(
            id: 'day_status',
            l10nKey: 'role_home.shortcut_day_status',
            route: '/field-sales/day-status',
            icon: Icons.work_outline,
          ),
          RoleHomeShortcut(
            id: 'ai_insights',
            l10nKey: 'role_home.shortcut_ai_insights',
            route: '/field-sales/ai-insights',
            icon: Icons.auto_awesome_outlined,
          ),
        ];
      case AppUserRole.warehouseKeeper:
        return const [
          RoleHomeShortcut(
            id: 'whms_hub',
            l10nKey: 'role_home.shortcut_whms',
            route: '/whms',
            icon: Icons.warehouse_outlined,
          ),
          RoleHomeShortcut(
            id: 'warehouse',
            l10nKey: 'role_home.shortcut_warehouse',
            route: '/whms/warehouses',
            icon: Icons.store_outlined,
          ),
          RoleHomeShortcut(
            id: 'stock_query',
            l10nKey: 'role_home.shortcut_stock_query',
            route: '/whms/stock-query',
            icon: Icons.inventory_2_outlined,
          ),
          RoleHomeShortcut(
            id: 'transfer',
            l10nKey: 'role_home.shortcut_transfer',
            route: '/whms/transfer',
            icon: Icons.swap_horiz,
          ),
          RoleHomeShortcut(
            id: 'count',
            l10nKey: 'role_home.shortcut_count',
            route: '/whms/count',
            icon: Icons.fact_check_outlined,
          ),
          RoleHomeShortcut(
            id: 'barcode',
            l10nKey: 'role_home.shortcut_barcode',
            route: '/field-sales/barcode-scan',
            icon: Icons.qr_code_scanner,
          ),
          RoleHomeShortcut(
            id: 'vehicle_stock',
            l10nKey: 'role_home.shortcut_vehicle_stock',
            route: '/field-sales/vehicle-stock',
            icon: Icons.local_shipping_outlined,
          ),
          RoleHomeShortcut(
            id: 'supply_request',
            l10nKey: 'role_home.shortcut_supply_request',
            route: '/field-sales/supply-requests',
            icon: Icons.request_quote_outlined,
          ),
        ];
      case AppUserRole.admin:
      case AppUserRole.supervisor:
      case AppUserRole.unknown:
        return const [];
    }
  }
}
