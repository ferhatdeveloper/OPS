// Dosya Adı: customer_detail_hub_smoke_test.dart
// Açıklama: Cari detay MBT hub (FATURA/İRSALİYE/SİPARİŞ/ZİYARET/FİNANS) route smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/init/navigation/routes.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_detail_screen.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerDetailScreen hub', () {
    test('5 MBT aksiyon — named route + l10n key', () {
      final actions = CustomerDetailScreen.hubActions;
      expect(actions.length, 5);
      expect(
        actions.map((a) => a.routeName).toList(),
        <String>[
          AppRoutes.fieldSalesInvoicesNew,
          AppRoutes.fieldSalesWaybillWholesale,
          AppRoutes.fieldSalesOrders,
          VisitFormScreen.routeName,
          AppRoutes.fieldSalesCollections,
        ],
      );
      expect(
        actions.map((a) => a.l10nKey).toList(),
        <String>[
          'field_sales.customer_detail_hub_invoice',
          'field_sales.customer_detail_hub_waybill',
          'field_sales.customer_detail_hub_order',
          'field_sales.customer_detail_hub_visit',
          'field_sales.customer_detail_hub_finance',
        ],
      );
    });

    test('hubCariIdArg — boş/whitespace null, trim geçerli', () {
      expect(CustomerDetailScreen.hubCariIdArg(null), isNull);
      expect(CustomerDetailScreen.hubCariIdArg(''), isNull);
      expect(CustomerDetailScreen.hubCariIdArg('   '), isNull);
      expect(CustomerDetailScreen.hubCariIdArg(' C-42 '), 'C-42');
    });
  });

  group('Cari detay hub — generateRoute cariId', () {
    test('5 hub path + cariId → MaterialPageRoute, arguments korunur', () {
      const cariId = 'CUST-HUB-1';
      const paths = <String>[
        AppRoutes.fieldSalesInvoicesNew,
        AppRoutes.fieldSalesWaybillWholesale,
        AppRoutes.fieldSalesOrders,
        VisitFormScreen.routeName,
        AppRoutes.fieldSalesCollections,
      ];
      for (final path in paths) {
        final route = AppRoutes.generateRoute(
          RouteSettings(name: path, arguments: cariId),
        );
        expect(route, isA<MaterialPageRoute<dynamic>>(), reason: path);
        expect(route.settings.name, path, reason: path);
        expect(route.settings.arguments, cariId, reason: path);
      }
    });

    test('visit-form boş cariId → visit-existing fallback builder', () {
      final route = AppRoutes.generateRoute(
        const RouteSettings(name: VisitFormScreen.routeName),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route.settings.name, VisitFormScreen.routeName);
    });

    test('waybill-wholesale customerFirstRoutes içinde', () {
      expect(
        AppRoutes.customerFirstRoutes.contains(
          AppRoutes.fieldSalesWaybillWholesale,
        ),
        isTrue,
      );
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesWaybillWholesale,
          visitCustomerId: 'W-1',
        ),
        'W-1',
      );
    });
  });
}
