// Dosya Adı: product_catalog_picker_test.dart
// Açıklama: Katalog → dens satır mapping + seçici sheet smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/products/view/product_catalog_picker.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/product_model.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_slip_dens_form.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_load_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('stockSlipLineFromProduct / densLinesToLoadItems', () {
    test('katalog ürünü productId + code taşır', () {
      final product = ProductModel(
        id: 'prod-1',
        code: 'SKU-01',
        name: 'Su 0.5L',
        unit: 'Adet',
        mainUnit: 'Adet',
      );
      final line = stockSlipLineFromProduct(product, qty: '2.5');
      expect(line.productId, 'prod-1');
      expect(line.code, 'SKU-01');
      expect(line.name, 'Su 0.5L');
      expect(line.qty, '2.5');

      final items = densLinesToLoadItems([line]);
      expect(items, hasLength(1));
      expect(items.first['productId'], 'prod-1');
      expect((items.first['quantity'] as num).toDouble(), 2.5);
      expect(items.first['unit'], 'Adet');
    });

    test('productId yoksa code kullanılır', () {
      final items = densLinesToLoadItems([
        const StockSlipLinePlaceholder(
          code: 'LEGACY-1',
          name: 'Eski',
          qty: '1',
        ),
      ]);
      expect(items.first['productId'], 'LEGACY-1');
    });
  });

  group('ProductCatalogPickerSheet', () {
    testWidgets('ürün listesi ve seçim pop', (tester) async {
      ProductModel? selected;
      await pumpStubWithL10n(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  selected = await showProductCatalogPicker(
                    context,
                    loadProducts: () async => [
                      ProductModel(
                        id: 'p1',
                        code: 'C1',
                        name: 'Test Ürün',
                      ),
                    ],
                  );
                },
                child: const Text('Aç'),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text('Ürün Listesi'), findsOneWidget);
      expect(find.text('Test Ürün'), findsOneWidget);

      await tester.tap(find.text('Test Ürün'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'p1');
      expect(selected!.code, 'C1');
    });
  });
}
