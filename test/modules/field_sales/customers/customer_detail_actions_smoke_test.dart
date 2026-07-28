// Dosya Adı: customer_detail_actions_smoke_test.dart
// Açıklama: Cari detay Hareketler/Mutabakat/Peşin satış route smoke
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/core/init/navigation/routes.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_extract_screen.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_reconciliation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cari detay aksiyon route smoke', () {
    test('Hareketler → CustomerExtractScreen + cariId', () {
      const cariId = 'C-ACT-1';
      final route = AppRoutes.generateRoute(
        const RouteSettings(
          name: CustomerExtractScreen.routeName,
          arguments: cariId,
        ),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route.settings.name, CustomerExtractScreen.routeName);
      expect(route.settings.arguments, cariId);
    });

    test('Mutabakat → CustomerReconciliationScreen + map args', () {
      const args = <String, String>{
        'customerId': 'C-ACT-2',
        'customerCode': '120.01',
        'customerName': 'Demo',
      };
      final route = AppRoutes.generateRoute(
        const RouteSettings(
          name: CustomerReconciliationScreen.routeName,
          arguments: args,
        ),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route.settings.name, CustomerReconciliationScreen.routeName);
      expect(route.settings.arguments, args);
    });

    test('Peşin satış → invoices/new + cariId', () {
      const cariId = 'C-ACT-3';
      final route = AppRoutes.generateRoute(
        const RouteSettings(
          name: AppRoutes.fieldSalesInvoicesNew,
          arguments: cariId,
        ),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route.settings.name, AppRoutes.fieldSalesInvoicesNew);
      expect(route.settings.arguments, cariId);
    });
  });
}
