// Dosya Adı: company_dens_app_bar_smoke_test.dart
// Açıklama: OPS smoke — FieldSalesDensAppBar dens toolbar (company list contract)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_app_bar.dart';

void main() {
  testWidgets('FieldSalesDensAppBar toolbarHeight 44', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: FieldSalesDensAppBar(
            title: 'Firmalar',
            backgroundColor: FieldSalesDensAppBar.primaryColor,
            showCalculatorHome: false,
          ),
        ),
      ),
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.toolbarHeight, FieldSalesDensAppBar.kToolbarHeightDens);
  });
}
