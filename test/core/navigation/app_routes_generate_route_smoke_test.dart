// Dosya Adı: app_routes_generate_route_smoke_test.dart
// Açıklama: AppRoutes.generateRoute null/unknown ve kritik path smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/init/navigation/routes.dart';
import 'package:exfin_ops/modules/field_sales/products/view/product_catalog_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRoutes.generateRoute smoke', () {
    test('null name → MaterialPageRoute (unknown fallback)', () {
      final route = AppRoutes.generateRoute(const RouteSettings());
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route.settings.name, isNull);
    });

    testWidgets('unknown path → "rota bulunamadı" scaffold', (tester) async {
      const path = '/definitely-not-a-route';
      final route = AppRoutes.generateRoute(const RouteSettings(name: path));
      expect(route, isA<MaterialPageRoute<dynamic>>());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                (route as MaterialPageRoute<dynamic>).builder(context),
          ),
        ),
      );
      expect(find.textContaining('rota bulunamadı'), findsOneWidget);
      expect(find.textContaining(path), findsOneWidget);
    });

    test('login / systemLogs → MaterialPageRoute', () {
      expect(
        AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.login)),
        isA<MaterialPageRoute<dynamic>>(),
      );
      expect(
        AppRoutes.generateRoute(
          const RouteSettings(name: AppRoutes.systemLogs),
        ),
        isA<MaterialPageRoute<dynamic>>(),
      );
    });

    test('checks / cash-cards / voucher-defaults / invoice-defaults', () {
      const paths = <String>[
        AppRoutes.fieldSalesChecks,
        '/field-sales/cash-cards',
        '/field-sales/voucher-defaults',
        '/field-sales/invoice-defaults',
      ];
      for (final path in paths) {
        final route = AppRoutes.generateRoute(RouteSettings(name: path));
        expect(route, isA<MaterialPageRoute<dynamic>>(), reason: path);
        expect(route.settings.name, path, reason: 'settings.name: $path');
      }
    });

    test('kritik menü seed path’leri kayıtlı (MaterialPageRoute)', () {
      const critical = <String>[
        '/field-sales/waybills',
        '/field-sales/waybill-wholesale',
        '/field-sales/waybill-purchase',
        '/field-sales/waybills-pending',
        '/field-sales/waybills-untransferred',
        '/field-sales/ewaybill-status',
        '/field-sales/einvoice-status',
        '/field-sales/invoice-wholesale',
        '/field-sales/invoice-return',
        '/field-sales/invoice-purchase',
        '/field-sales/delivery-list',
        '/field-sales/delivery-hold',
        '/field-sales/delivery-untransferred',
        '/field-sales/visit-existing',
        '/field-sales/visit-form',
        '/field-sales/visit-new',
        '/field-sales/visit-history',
        '/field-sales/visit-detail',
        '/field-sales/visit-untransferred',
        '/field-sales/weekly-route-plan',
        '/field-sales/offline-map-download',
        '/field-sales/in-app-route-map',
        '/field-sales/routes/plan',
        '/field-sales/orders',
        '/field-sales/orders-list',
        '/field-sales/orders-tracking',
        '/field-sales/orders-pending',
        '/field-sales/orders-untransferred',
        '/field-sales/orders-approval',
        '/field-sales/invoices-list-mbt',
        '/field-sales/invoices-pending',
        '/field-sales/invoices-untransferred',
        '/field-sales/invoices-approval',
        '/field-sales/cash-cards',
        '/field-sales/cash-card-detail',
        '/field-sales/bank-cards',
        '/field-sales/checks',
        '/field-sales/promissory-list',
        '/field-sales/company-general',
        '/field-sales/manager-dashboard',
        '/field-sales/voucher-defaults',
        '/field-sales/invoice-defaults',
        '/field-sales/payment-entry',
        '/field-sales/virman',
        // Stok (fs_stock sheet altları — placeholder değil)
        '/field-sales/products',
        '/field-sales/prices',
        '/field-sales/stock-barcode',
        '/field-sales/stock-count',
        '/field-sales/stock-warehouse',
        '/field-sales/stock-production',
        '/field-sales/stock-transferred',
        '/field-sales/stock-untransferred',
        // Duyurular (fs_announcements)
        '/field-sales/announcements',
        '/field-sales/admin',
        '/field-sales/currency-rates',
        '/field-sales/companies',
        '/field-sales/warehouses',
        '/field-sales/report-backup',
        '/field-sales/report-sales',
        '/field-sales/report-cari',
        '/field-sales/report-siparis',
        '/field-sales/report-params',
        '/field-sales/report-layout',
        '/field-sales/report-pdf',
        '/field-sales/report-logo-settings',
      ];
      for (final path in critical) {
        final route = AppRoutes.generateRoute(RouteSettings(name: path));
        expect(route, isA<MaterialPageRoute<dynamic>>(), reason: path);
        expect(route.settings.name, path, reason: 'settings.name: $path');
      }
    });

    test(
      'stok / duyurular seed path — unknown fallback değil (builder ≠ null)',
      () {
        // generateRoute unknown path’te de MaterialPageRoute döner;
        // kayıtlı path’te settings.name korunur + builder üretilebilir.
        const paths = <String>[
          '/field-sales/products',
          '/field-sales/prices',
          '/field-sales/stock-barcode',
          '/field-sales/stock-count',
          '/field-sales/stock-warehouse',
          '/field-sales/stock-production',
          '/field-sales/stock-transferred',
          '/field-sales/stock-untransferred',
          '/field-sales/announcements',
          '/field-sales/admin',
        ];
        for (final path in paths) {
          final route = AppRoutes.generateRoute(RouteSettings(name: path));
          expect(route, isA<MaterialPageRoute<dynamic>>(), reason: path);
          expect(route.settings.name, path, reason: path);
          final page = route as MaterialPageRoute<dynamic>;
          expect(page.builder, isNotNull, reason: 'builder: $path');
        }
      },
    );

    testWidgets(
      'STOK Detay /field-sales/products → ProductCatalogScreen',
      (tester) async {
        final route = AppRoutes.generateRoute(
          const RouteSettings(name: AppRoutes.fieldSalesProducts),
        );
        expect(route, isA<MaterialPageRoute<dynamic>>());

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) =>
                  (route as MaterialPageRoute<dynamic>).builder(context),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ProductCatalogScreen), findsOneWidget);
      },
    );

    test('argumentsForSeedRoute — cari-önce path + ziyaret id', () {
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesOrders,
          visitCustomerId: 'C-100',
        ),
        'C-100',
      );
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesCollections,
          visitCustomerId: '  ',
        ),
        isNull,
      );
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesInvoiceWholesale,
          visitCustomerId: 'INV-1',
        ),
        'INV-1',
      );
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesPaymentEntry,
          visitCustomerId: 'PAY-1',
        ),
        'PAY-1',
      );
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesVirman,
          visitCustomerId: 'C-100',
        ),
        isNull,
      );
      expect(
        AppRoutes.argumentsForSeedRoute(
          '/field-sales/customers',
          visitCustomerId: 'C-100',
        ),
        isNull,
      );
    });

    test('invoice-wholesale / invoices/new — customerId arg → MaterialPageRoute',
        () {
      for (final path in <String>[
        AppRoutes.fieldSalesInvoiceWholesale,
        AppRoutes.fieldSalesInvoiceReturn,
        AppRoutes.fieldSalesInvoicesNew,
        AppRoutes.fieldSalesOrders,
        AppRoutes.fieldSalesCollections,
        AppRoutes.fieldSalesPaymentEntry,
      ]) {
        final withCust = AppRoutes.generateRoute(
          RouteSettings(name: path, arguments: 'CUST-9'),
        );
        expect(withCust, isA<MaterialPageRoute<dynamic>>(), reason: path);
        expect(withCust.settings.arguments, 'CUST-9', reason: path);

        final noCust = AppRoutes.generateRoute(RouteSettings(name: path));
        expect(noCust, isA<MaterialPageRoute<dynamic>>(), reason: '$path no arg');
      }
    });
  });
}
