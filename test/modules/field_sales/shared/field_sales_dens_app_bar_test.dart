// Dosya Adı: field_sales_dens_app_bar_test.dart
// Açıklama: Dens AppBar toolbar yüksekliği / başlık smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_app_bar.dart';

void main() {
  testWidgets('FieldSalesDensAppBar — dens yükseklik ve başlık',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: FieldSalesDensAppBar(title: 'Yönetici Raporları'),
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Yönetici Raporları'), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.toolbarHeight, FieldSalesDensAppBar.kToolbarHeightDens);
  });
}
