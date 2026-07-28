// Dosya Adı: dashboard_grid_submenu_route_test.dart
// Açıklama: Home grid ModuleCardData alt menü route taşıma smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/constants/menu_constants.dart';
import 'package:exfin_ops/service/menu_service.dart';

void main() {
  group('Home grid submenu route mapping', () {
    test('mapModuleSubmenuItems taşıyor title + route', () {
      final items = MenuService.mapModuleSubmenuItems([
        {
          'title': 'Toptan Satış',
          'route': '/field-sales/invoice-wholesale',
        },
        {
          'title': 'Toptan Satış',
          'route': '/field-sales/waybill-wholesale',
        },
        {
          'title': '',
          'route': '/ignored',
        },
      ]);

      expect(items, hasLength(2));
      expect(items[0].title, 'Toptan Satış');
      expect(items[0].route, '/field-sales/invoice-wholesale');
      expect(items[1].route, '/field-sales/waybill-wholesale');
    });

    test('aynı title farklı route — Fatura vs İrsaliye çakışmaz', () {
      final invoice = MenuService.mapModuleSubmenuItems([
        {
          'title': 'Toptan Satış',
          'route': '/field-sales/invoice-wholesale',
        },
      ]).first;
      final waybill = MenuService.mapModuleSubmenuItems([
        {
          'title': 'Toptan Satış',
          'route': '/field-sales/waybill-wholesale',
        },
      ]).first;

      expect(invoice.title, waybill.title);
      expect(invoice.route, isNot(waybill.route));
      expect(invoice.route, '/field-sales/invoice-wholesale');
      expect(waybill.route, '/field-sales/waybill-wholesale');
    });

    test('ModuleCardData Stok alt menüleri route tutar', () {
      final stockCard = ModuleCardData(
        title: 'Stok',
        subtitle: '',
        icon: Icons.qr_code_scanner,
        submenus: MenuService.mapModuleSubmenuItems([
          {
            'title': 'Detay',
            'route': '/field-sales/products',
          },
          {
            'title': 'Sayım Fişi',
            'route': '/field-sales/stock-count',
          },
        ]),
      );

      expect(stockCard.submenus, isNotEmpty);
      expect(stockCard.submenus.first.route, '/field-sales/products');
      expect(
        stockCard.submenus.any((s) => s.route.isEmpty),
        isFalse,
      );
    });

    test('fs_stock seed sheet — 8 alt menü route dolu', () {
      // database_service seedFieldSalesMockData fs_stock ile aynı path’ler
      const seedRows = <Map<String, dynamic>>[
        {'title': 'Detay', 'route': '/field-sales/products'},
        {'title': 'Fiyat Gör', 'route': '/field-sales/prices'},
        {'title': 'Barkod Ekle', 'route': '/field-sales/stock-barcode'},
        {'title': 'Sayım Fişi', 'route': '/field-sales/stock-count'},
        {'title': 'Ambar Fişi', 'route': '/field-sales/stock-warehouse'},
        {
          'title': 'Üretimden Giriş Fişi',
          'route': '/field-sales/stock-production',
        },
        {
          'title': 'Transfer Edilenler',
          'route': '/field-sales/stock-transferred',
        },
        {
          'title': 'Transfer Edilmeyenler',
          'route': '/field-sales/stock-untransferred',
        },
      ];
      final items = MenuService.mapModuleSubmenuItems(seedRows);
      expect(items, hasLength(8));
      expect(items.every((i) => i.route.isNotEmpty), isTrue);
      expect(
        items.map((i) => i.route).toSet(),
        containsAll(<String>[
          '/field-sales/products',
          '/field-sales/stock-count',
          '/field-sales/stock-production',
        ]),
      );
    });

    test('fs_announcements seed — duyuru route', () {
      final items = MenuService.mapModuleSubmenuItems([
        {
          'title': 'Duyurular',
          'route': '/field-sales/announcements',
        },
      ]);
      expect(items, hasLength(1));
      expect(items.first.route, '/field-sales/announcements');
    });

    test('fs_other seed — offline harita + yol tarifi', () {
      const seedRows = <Map<String, dynamic>>[
        {
          'title': 'Bilgi Gönderme',
          'route': '/field-sales/send-info',
        },
        {
          'title': 'Güne Başlama Bitirme',
          'route': '/field-sales/day-status',
        },
        {
          'title': 'Haftalık Rota Planı',
          'route': '/field-sales/weekly-route-plan',
        },
        {
          'title': 'Offline Harita İndir',
          'route': '/field-sales/offline-map-download',
        },
        {
          'title': 'Uygulama İçi Yol Tarifi',
          'route': '/field-sales/in-app-route-map',
        },
        {
          'title': 'Resimler',
          'route': '/field-sales/image-settings',
        },
      ];
      final items = MenuService.mapModuleSubmenuItems(seedRows);
      expect(items, hasLength(6));
      expect(
        items.any((i) => i.route == '/field-sales/offline-map-download'),
        isTrue,
      );
      expect(
        items.any((i) => i.route == '/field-sales/in-app-route-map'),
        isTrue,
      );
      expect(
        MenuService.getIconFromString('download_for_offline'),
        Icons.download_for_offline,
      );
    });

    test('fs_other seed — Haftalık Rota Planı weekly-route-plan', () {
      const seedRows = <Map<String, dynamic>>[
        {
          'title': 'Bilgi Gönderme',
          'route': '/field-sales/send-info',
        },
        {
          'title': 'Güne Başlama Bitirme',
          'route': '/field-sales/day-status',
        },
        {
          'title': 'Haftalık Rota Planı',
          'route': '/field-sales/weekly-route-plan',
        },
        {
          'title': 'Resimler',
          'route': '/field-sales/image-settings',
        },
      ];
      final items = MenuService.mapModuleSubmenuItems(seedRows);
      expect(items, hasLength(4));
      expect(
        items.any((i) => i.route == '/field-sales/weekly-route-plan'),
        isTrue,
      );
      expect(
        items
            .where((i) => i.title == 'Haftalık Rota Planı')
            .single
            .route,
        '/field-sales/weekly-route-plan',
      );
      expect(
        MenuService.getIconFromString('calendar_view_week'),
        Icons.calendar_view_week,
      );
    });

    test('fs_invoice / fs_waybill seed — Fiş Ön Değerleri voucher-defaults', () {
      // database_service seedFieldSalesMockData fs_invoice / fs_waybill
      const invoiceSeed = <Map<String, dynamic>>[
        {
          'title': 'Toptan Satış',
          'route': '/field-sales/invoice-wholesale',
        },
        {
          'title': 'Bekleyen Faturalar',
          'route': '/field-sales/invoices-pending',
        },
        {
          'title': 'Fiş Ön Değerleri',
          'route': '/field-sales/voucher-defaults',
        },
      ];
      const waybillSeed = <Map<String, dynamic>>[
        {
          'title': 'Toptan Satış',
          'route': '/field-sales/waybill-wholesale',
        },
        {
          'title': 'Bekleyen İrsaliyeler',
          'route': '/field-sales/waybills-pending',
        },
        {
          'title': 'Fiş Ön Değerleri',
          'route': '/field-sales/voucher-defaults',
        },
      ];
      const settingsSeed = <Map<String, dynamic>>[
        {
          'title': 'Fiş Ön Değerleri',
          'route': '/field-sales/voucher-defaults',
        },
      ];

      final invoice = MenuService.mapModuleSubmenuItems(invoiceSeed);
      final waybill = MenuService.mapModuleSubmenuItems(waybillSeed);
      final settings = MenuService.mapModuleSubmenuItems(settingsSeed);

      expect(
        invoice.any((i) => i.route == '/field-sales/voucher-defaults'),
        isTrue,
      );
      expect(
        waybill.any((i) => i.route == '/field-sales/voucher-defaults'),
        isTrue,
      );
      expect(settings.single.route, '/field-sales/voucher-defaults');
      expect(
        invoice
            .where((i) => i.title == 'Fiş Ön Değerleri')
            .single
            .route,
        waybill
            .where((i) => i.title == 'Fiş Ön Değerleri')
            .single
            .route,
      );
    });

    test('null route → boş string (title-switch fallback)', () {
      final items = MenuService.mapModuleSubmenuItems([
        {'title': 'Eski Menü', 'route': null},
        {'title': 'Rotasız'},
      ]);
      expect(items.every((i) => i.route == ''), isTrue);
    });
  });
}
