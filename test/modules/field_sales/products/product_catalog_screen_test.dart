// Dosya Adı: product_catalog_screen_test.dart
// Açıklama: Ürün katalog dens ekranı enjekte satır / boş state smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_row.dart';
import 'package:exfin_ops/modules/field_sales/products/view/product_catalog_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('enjekte satır adı dens listede görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      const ProductCatalogScreen(
        products: [
          ProductCatalogRow(
            id: 'p1',
            code: 'STK-001',
            name: 'Demo Stok Kartı A',
            unit: 'ADET',
            price: 125.5,
            stockQuantity: 48,
          ),
        ],
      ),
    );

    expect(find.text('Demo Stok Kartı A'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('boş enjekte liste empty state gösterir', (tester) async {
    await pumpStubWithL10n(
      tester,
      const ProductCatalogScreen(products: []),
    );

    expect(
      find.text('Görüntülenecek ürün bulunamadı.'),
      findsOneWidget,
    );
  });
}
