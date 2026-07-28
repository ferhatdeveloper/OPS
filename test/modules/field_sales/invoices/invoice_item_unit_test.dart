// Dosya Adı: invoice_item_unit_test.dart
// Açıklama: Fatura kalemi birim + miktar serialize testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InvoiceItemModel unit_name round-trip', () {
    final item = InvoiceItemModel(
      id: 'i1',
      invoiceId: 'inv1',
      productId: 'p1',
      quantity: 2.5,
      price: 10,
      vatAmount: 5,
      totalAmount: 25,
      productName: 'Test',
      unitName: 'Koli',
    );

    final map = item.toMap();
    expect(map['unit_name'], 'Koli');
    expect(map['quantity'], 2.5);

    final restored = InvoiceItemModel.fromMap(map, productName: 'Test');
    expect(restored.unitName, 'Koli');
    expect(restored.quantity, 2.5);
  });
}
