// Dosya Adı: invoice_pending_record_test.dart
// Açıklama: Bekleyen fatura dens model + seed birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_pending_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_pending_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoices_pending_screen.dart';

void main() {
  group('InvoicePendingRecord', () {
    test('isPendingMap approval_status=0 veya status Pending', () {
      expect(
        InvoicePendingRecord.isPendingMap({
          'approval_status': 0,
          'status': 'Completed',
        }),
        isTrue,
      );
      expect(
        InvoicePendingRecord.isPendingMap({
          'approval_status': 1,
          'status': 'Pending',
        }),
        isTrue,
      );
      expect(
        InvoicePendingRecord.isPendingMap({
          'approval_status': 1,
          'status': 'Completed',
        }),
        isFalse,
      );
    });

    test('fromMap purchase tip → alış side', () {
      final row = InvoicePendingRecord.fromMap({
        'id': 'inv-p1',
        'customer_id': 'sup-1',
        'invoice_date': '2026-07-26T10:00:00.000',
        'total_amount': 42.5,
        'status': 'Pending',
        'invoice_type': 'field_sales.purchase_invoice',
        'approval_status': 0,
        'is_synced': 0,
        'customer_code': 'TED-1',
        'customer_name': 'Tedarikçi',
      });
      expect(row.docSide, InvoicePendingDocSide.purchase);
      expect(row.customerLabel, 'TED-1 · Tedarikçi');
      expect(row.totalAmount, 42.5);
    });

    test('toMap/fromMap round-trip temel alanlar', () {
      final row = InvoicePendingRecord(
        id: 'inv-r1',
        customerId: 'c1',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 10,
        status: 'Pending',
        invoiceType: 'field_sales.wholesale_invoice',
        approvalStatus: 0,
      );
      final back = InvoicePendingRecord.fromMap(row.toMap());
      expect(back.id, row.id);
      expect(back.approvalStatus, 0);
      expect(back.docSide, InvoicePendingDocSide.sales);
      expect(back.status, 'Pending');
    });
  });

  group('InvoicePendingSeed', () {
    test('route ve stub satırlarda onay bekleyen dolu', () {
      expect(InvoicePendingSeed.route, InvoicesPendingScreen.routeName);
      expect(InvoicePendingSeed.submenuTitle, 'Bekleyen Faturalar');
      expect(InvoicePendingSeed.tableName, 'invoices');
      expect(InvoicePendingSeed.defaultRows, isNotEmpty);
      for (final r in InvoicePendingSeed.defaultRows) {
        expect(r.approvalStatus, 0);
        expect(r.id, isNotEmpty);
      }
      expect(InvoicePendingSeed.salesRows, isNotEmpty);
      expect(InvoicePendingSeed.purchaseRows, isNotEmpty);
      expect(InvoicePendingSeed.defaultMaps.first['approval_status'], 0);
    });
  });
}
