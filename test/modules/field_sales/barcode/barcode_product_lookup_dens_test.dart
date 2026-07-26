// Dosya Adı: barcode_product_lookup_dens_test.dart
// Açıklama: Barkod dens ürün lookup widget smoke + Seç pop
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/barcode/view/barcode_scan_screen.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_seed.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  test('tam barkod tek satır döner', () {
    final row = BarcodeScanScreen.findExactBarcode(
      ProductCatalogSeed.defaultRows,
      '8690000000001',
    );
    expect(row, isNotNull);
    expect(row!.code, 'STK-001');
  });

  testWidgets('Barkod dens seed satırları ve Seç gösterir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      BarcodeScanScreen(
        products: ProductCatalogSeed.defaultRows,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Barkod Tara'), findsOneWidget);
    expect(find.text('STK-001'), findsOneWidget);
    expect(find.text('Demo Stok Kartı A'), findsOneWidget);
    expect(find.text('8690000000001'), findsOneWidget);
    expect(find.text('Seç'), findsOneWidget);
  });

  testWidgets('Arama süzgeci dens satırları daraltır', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      BarcodeScanScreen(
        products: ProductCatalogSeed.defaultRows,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'STK-002');
    await tester.pumpAndSettle();

    expect(find.text('Demo Stok Kartı B'), findsOneWidget);
    expect(find.text('Demo Stok Kartı A'), findsNothing);
    expect(find.text('STK-001'), findsNothing);
  });

  testWidgets('Seç ürün haritası ile pop eder', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Map<String, dynamic>? popped;
    await pumpStubWithL10n(
      tester,
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<Map<String, dynamic>>(
                MaterialPageRoute(
                  builder: (_) => BarcodeScanScreen(
                    products: ProductCatalogSeed.defaultRows,
                  ),
                ),
              );
            },
            child: const Text('open'),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo Stok Kartı B'));
    await tester.pump();
    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    expect(popped!['code'], 'STK-002');
    expect(popped!['barcode'], '8690000000002');
  });
}
