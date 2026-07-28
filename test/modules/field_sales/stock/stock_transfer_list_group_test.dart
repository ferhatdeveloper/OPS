// Dosya Adı: stock_transfer_list_group_test.dart
// Açıklama: Stok transfer dens gruplama birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/stock_transfer_model.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_transfer_list_screen.dart';

void main() {
  StockTransferModel row({
    required String id,
    required bool synced,
    String from = 'MRK',
    String to = 'ARC',
    DateTime? date,
  }) {
    return StockTransferModel(
      id: id,
      fromWarehouse: from,
      toWarehouse: to,
      productId: 'p1',
      quantity: 1,
      transferDate: date ?? DateTime(2026, 7, 28),
      isSynced: synced,
      status: synced ? 'Completed' : 'Pending',
    );
  }

  test('untransferred yalnız is_synced=0 gruplar', () {
    final groups = StockTransferListScreen.groupRows(
      [
        row(id: 'a', synced: false),
        row(id: 'b', synced: false),
        row(id: 'c', synced: true),
      ],
      syncedOnly: false,
    );
    expect(groups.length, 1);
    expect(groups.first.lineCount, 2);
    expect(groups.first.synced, isFalse);
  });

  test('transferred yalnız is_synced=1 gruplar', () {
    final groups = StockTransferListScreen.groupRows(
      [
        row(id: 'a', synced: true),
        row(id: 'b', synced: false),
      ],
      syncedOnly: true,
    );
    expect(groups.length, 1);
    expect(groups.first.lineCount, 1);
    expect(groups.first.synced, isTrue);
  });
}
