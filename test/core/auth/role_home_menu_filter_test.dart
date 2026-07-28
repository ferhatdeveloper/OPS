// Dosya Adı: role_home_menu_filter_test.dart
// Açıklama: Rol → menü uuid / hub kısayol filtre birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/auth/app_user_role.dart';
import 'package:exfin_ops/core/auth/role_home_menu_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserRole.parse', () {
    test('plasiyer / salesperson → salesperson', () {
      expect(AppUserRole.parse('plasiyer'), AppUserRole.salesperson);
      expect(AppUserRole.parse('SalesPerson'), AppUserRole.salesperson);
      expect(AppUserRole.parse('saha_satis'), AppUserRole.salesperson);
    });

    test('depocu / warehouse → warehouseKeeper', () {
      expect(AppUserRole.parse('depocu'), AppUserRole.warehouseKeeper);
      expect(AppUserRole.parse('warehouse'), AppUserRole.warehouseKeeper);
      expect(AppUserRole.parse('ambarci'), AppUserRole.warehouseKeeper);
    });

    test('admin / supervisor', () {
      expect(AppUserRole.parse('admin'), AppUserRole.admin);
      expect(AppUserRole.parse('yönetici'), AppUserRole.admin);
      expect(AppUserRole.parse('supervisor'), AppUserRole.supervisor);
    });

    test('boş / bilinmeyen → unknown', () {
      expect(AppUserRole.parse(null), AppUserRole.unknown);
      expect(AppUserRole.parse(''), AppUserRole.unknown);
      expect(AppUserRole.parse('guest'), AppUserRole.unknown);
    });
  });

  group('RoleHomeMenuFilter main uuid', () {
    test('plasiyer ziyaret görür, yönetici menüsü görmez', () {
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.salesperson,
          'fs_visit',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.salesperson,
          'fs_order',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.salesperson,
          'fs_finance',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.salesperson,
          'fs_admin',
        ),
        isFalse,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.salesperson,
          'fs_invoice',
        ),
        isFalse,
      );
    });

    test('depocu stok görür, ziyaret/sipariş görmez', () {
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.warehouseKeeper,
          'fs_stock',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.warehouseKeeper,
          'fs_visit',
        ),
        isFalse,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.warehouseKeeper,
          'fs_order',
        ),
        isFalse,
      );
      expect(
        RoleHomeMenuFilter.allowsMainMenuUuid(
          AppUserRole.warehouseKeeper,
          'fs_finance',
        ),
        isFalse,
      );
    });

    test('admin tüm ana menüleri görür', () {
      for (final uuid in [
        'fs_admin',
        'fs_visit',
        'fs_stock',
        'fs_invoice',
        'fs_order',
      ]) {
        expect(
          RoleHomeMenuFilter.allowsMainMenuUuid(AppUserRole.admin, uuid),
          isTrue,
        );
      }
    });

    test('filterByMainUuid plasiyer listesini süzer', () {
      final items = ['fs_visit', 'fs_admin', 'fs_stock', 'fs_invoice'];
      final filtered = RoleHomeMenuFilter.filterByMainUuid(
        role: AppUserRole.salesperson,
        items: items,
        uuidOf: (e) => e,
      );
      expect(filtered, ['fs_visit', 'fs_stock']);
    });
  });

  group('RoleHomeMenuFilter sub uuid', () {
    test('depocu stok alt menü: transfer/sayım var, fiyat yok', () {
      expect(
        RoleHomeMenuFilter.allowsSubMenuUuid(
          role: AppUserRole.warehouseKeeper,
          parentUuid: 'fs_stock',
          subUuid: 'sub_stk_wh_transfer',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsSubMenuUuid(
          role: AppUserRole.warehouseKeeper,
          parentUuid: 'fs_stock',
          subUuid: 'sub_stk_count',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsSubMenuUuid(
          role: AppUserRole.warehouseKeeper,
          parentUuid: 'fs_stock',
          subUuid: 'sub_stk_price',
        ),
        isFalse,
      );
    });

    test('plasiyer stok: barkod var, ambar transfer yok', () {
      expect(
        RoleHomeMenuFilter.allowsSubMenuUuid(
          role: AppUserRole.salesperson,
          parentUuid: 'fs_stock',
          subUuid: 'sub_stk_barcode',
        ),
        isTrue,
      );
      expect(
        RoleHomeMenuFilter.allowsSubMenuUuid(
          role: AppUserRole.salesperson,
          parentUuid: 'fs_stock',
          subUuid: 'sub_stk_wh_transfer',
        ),
        isFalse,
      );
    });
  });

  group('RoleHomeMenuFilter hubShortcuts', () {
    test('plasiyer hub: ziyaret, sipariş, tahsilat, rota, konum, barkod, gün, AI',
        () {
      final ids = RoleHomeMenuFilter.hubShortcuts(AppUserRole.salesperson)
          .map((e) => e.id)
          .toList();
      expect(
        ids,
        [
          'visit',
          'order',
          'collection',
          'route',
          'live_location',
          'barcode',
          'day_status',
          'ai_insights',
        ],
      );
    });

    test('depocu hub: ambar, stok, transfer, barkod, araç stok, sayım, tedarik',
        () {
      final ids = RoleHomeMenuFilter.hubShortcuts(AppUserRole.warehouseKeeper)
          .map((e) => e.id)
          .toList();
      expect(
        ids,
        [
          'warehouse',
          'stock_query',
          'transfer',
          'barcode',
          'vehicle_stock',
          'count',
          'supply_request',
        ],
      );
    });

    test('admin hub boş (tam menü)', () {
      expect(RoleHomeMenuFilter.hubShortcuts(AppUserRole.admin), isEmpty);
    });
  });
}
