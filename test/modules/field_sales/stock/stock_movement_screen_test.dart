// Dosya Adı: stock_movement_screen_test.dart
// Açıklama: Stok hareket dens ekran smoke
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/stock_transfer_model.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_movement_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('dens hareket satırı görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      StockMovementScreen(
        initialRows: [
          StockTransferModel(
            id: 't1',
            fromWarehouse: 'MRK',
            toWarehouse: 'ARC',
            productId: 'p1',
            productCode: 'SKU-9',
            productName: 'Hareket Ürün',
            quantity: 3,
            transferDate: DateTime(2026, 7, 28),
            status: 'Completed',
          ),
        ],
      ),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.stock_movement');
    expect(find.text('SKU-9'), findsOneWidget);
    expect(find.textContaining('MRK → ARC'), findsOneWidget);
  });
}
