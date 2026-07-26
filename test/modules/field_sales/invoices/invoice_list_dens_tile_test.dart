// Dosya Adı: invoice_list_dens_tile_test.dart
// Açıklama: Fatura listesi dens tile — satış/alış + satır map
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_list_dens_record.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/mbt_sales_purchase_queue_body.dart';

void main() {
  group('InvoiceListDensRecord.sideFromInvoiceType', () {
    test('purchase → alış sekmesi', () {
      expect(
        InvoiceListDensRecord.sideFromInvoiceType(
          'field_sales.purchase_invoice',
        ),
        MbtQueueDocSide.purchase,
      );
    });

    test('wholesale / return → satış sekmesi', () {
      expect(
        InvoiceListDensRecord.sideFromInvoiceType(
          'field_sales.wholesale_invoice',
        ),
        MbtQueueDocSide.sales,
      );
      expect(
        InvoiceListDensRecord.sideFromInvoiceType('field_sales.return_invoice'),
        MbtQueueDocSide.sales,
      );
    });
  });
}
