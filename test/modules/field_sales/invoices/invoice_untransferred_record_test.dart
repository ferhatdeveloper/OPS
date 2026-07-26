// Dosya Adı: invoice_untransferred_record_test.dart
// Açıklama: Transfer edilmeyen fatura dens model + seed birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_untransferred_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_untransferred_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoices_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_untransferred_query.dart';

void main() {
  group('InvoiceUntransferredRecord', () {
    test('toMap/fromMap is_synced=0 ve doc_side korur', () {
      final row = InvoiceUntransferredRecord(
        id: 'inv-u1',
        documentNo: 'FT20260001',
        invoiceType: 'field_sales.wholesale_invoice_8',
        docSide: InvoiceUntransferredDocSide.sales,
        customerCode: 'C0001',
        customerName: 'Demo Cari',
        documentDate: DateTime(2026, 7, 26),
        amount: 100.5,
        isSynced: 0,
      );
      final map = row.toMap();
      expect(map['is_synced'], 0);
      expect(map['doc_side'], 'sales');
      expect(map['document_no'], 'FT20260001');
      expect(map['ONAY'], 1);

      final back = InvoiceUntransferredRecord.fromMap(map);
      expect(back.id, 'inv-u1');
      expect(back.isSynced, 0);
      expect(back.docSide, InvoiceUntransferredDocSide.sales);
      expect(back.amount, 100.5);
    });
  });

  group('InvoiceUntransferredSeed', () {
    test('route + stub satırlar yalnızca unsynced', () {
      expect(
        InvoiceUntransferredSeed.route,
        InvoicesUntransferredScreen.routeName,
      );
      expect(InvoiceUntransferredSeed.tableName, 'invoices');
      expect(InvoiceUntransferredSeed.defaultRows, isNotEmpty);
      for (final r in InvoiceUntransferredSeed.defaultRows) {
        expect(r.isSynced, 0);
        expect(r.documentNo, isNotEmpty);
      }
      expect(InvoiceUntransferredSeed.salesRows, isNotEmpty);
      expect(InvoiceUntransferredSeed.purchaseRows, isNotEmpty);
    });
  });

  group('InvoiceUntransferredQuery', () {
    test('onlyUnsynced is_synced!=0 eler', () {
      final mixed = [
        InvoiceUntransferredRecord(
          id: 'a',
          documentNo: 'A1',
          isSynced: 0,
        ),
        InvoiceUntransferredRecord(
          id: 'b',
          documentNo: 'B1',
          isSynced: 1,
        ),
      ];
      final out = InvoiceUntransferredQuery.onlyUnsynced(mixed);
      expect(out.map((e) => e.id), ['a']);
    });

    test('fromInvoiceSqliteMaps purchase tipini alış yapar', () {
      final rows = InvoiceUntransferredQuery.fromInvoiceSqliteMaps([
        {
          'id': 'p1',
          'invoice_type': 'field_sales.purchase_invoice',
          'total_amount': 50,
          'invoice_date': '2026-07-20T10:00:00.000',
          'is_synced': 0,
          'customer_id': 'c-p',
        },
      ]);
      expect(rows, hasLength(1));
      expect(rows.first.docSide, InvoiceUntransferredDocSide.purchase);
      expect(rows.first.amount, 50);
    });

    test('fromSyncQueueJobs yalnızca entity_type=invoice', () {
      final rows = InvoiceUntransferredQuery.fromSyncQueueJobs([
        {
          'id': 'job1',
          'entity_type': 'invoice',
          'entity_id': 'inv-q1',
          'payload':
              '{"id":"inv-q1","invoice_type":"field_sales.wholesale_invoice_8",'
              '"customer_code":"C9","total_amount":12.5,'
              '"invoice_date":"2026-07-26T08:00:00.000"}',
        },
        {
          'id': 'job2',
          'entity_type': 'order',
          'entity_id': 'ord-1',
        },
      ]);
      expect(rows, hasLength(1));
      expect(rows.first.id, 'inv-q1');
      expect(rows.first.docSide, InvoiceUntransferredDocSide.sales);
      expect(rows.first.customerCode, 'C9');
      expect(rows.first.amount, 12.5);
    });
  });
}
