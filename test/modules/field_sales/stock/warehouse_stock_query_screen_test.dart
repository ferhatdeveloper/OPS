// Dosya Adı: warehouse_stock_query_screen_test.dart
// Açıklama: Ambar stok sorgu dens ekran smoke
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/warehouse_stock_query_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/warehouse_stock_query_store.dart';
import 'package:exfin_ops/modules/whms/contract/stock_balance.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('dens satır ve ambar chip görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      const WarehouseStockQueryScreen(
        initialWarehouseCode: 'MRK',
        initialRows: [
          WarehouseStockQueryRow(
            productId: 'prd-1',
            productCode: 'SKU-1',
            productName: 'Test Ürün',
            quantity: 5,
            warehouseCode: 'MRK',
            bucket: StockBalanceBucket.warehouse,
          ),
        ],
      ),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.warehouse_stock_query');
    expect(find.text('SKU-1'), findsOneWidget);
    expect(find.text('Test Ürün'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });
}
