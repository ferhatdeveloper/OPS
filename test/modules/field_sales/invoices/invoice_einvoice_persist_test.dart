// Dosya Adı: invoice_einvoice_persist_test.dart
// Açıklama: Fatura kaydında ettn/gib_status → invoices + einvoice_status
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/sync/outbound_idempotency.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_gib_status.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_status_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_model.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_persist.dart';

void main() {
  group('InvoicePersist.prepareForPersist — ETTN/GİB', () {
    test('e-Fatura: eksik ettn üretir, gib_status QUEUED', () {
      final invoice = InvoiceModel(
        id: 'inv-e1',
        customerId: 'c1',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 100,
        isEInvoice: true,
      );

      final prepared = InvoicePersist.prepareForPersist(invoice);

      expect(prepared.ettn, isNotNull);
      expect(prepared.ettn!.trim(), isNotEmpty);
      expect(prepared.gibStatus, EinvoiceGibStatus.queued.code);
    });

    test('e-Fatura: mevcut ettn/gib_status korunur', () {
      final invoice = InvoiceModel(
        id: 'inv-e2',
        customerId: 'c1',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 50,
        isEInvoice: true,
        ettn: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        gibStatus: EinvoiceGibStatus.sent.code,
      );

      final prepared = InvoicePersist.prepareForPersist(invoice);

      expect(prepared.ettn, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(prepared.gibStatus, 'SENT');
    });

    test('kağıt fatura: ettn/gib_status temizlenir', () {
      final invoice = InvoiceModel(
        id: 'inv-p1',
        customerId: 'c1',
        invoiceDate: DateTime(2026, 7, 26),
        totalAmount: 10,
        isEInvoice: false,
        ettn: 'should-clear',
        gibStatus: 'SENT',
      );

      final prepared = InvoicePersist.prepareForPersist(invoice);

      expect(prepared.ettn, isNull);
      expect(prepared.gibStatus, isNull);
    });
  });

  group('InvoicePersist.buildInvoiceSqliteRow — ettn/gib', () {
    test('e-Fatura satırında ettn ve gib_status yazar', () {
      final prepared = InvoicePersist.prepareForPersist(
        InvoiceModel(
          id: 'inv-row-1',
          customerId: 'c9',
          invoiceDate: DateTime(2026, 7, 26),
          totalAmount: 200,
          isEInvoice: true,
          ettn: '11111111-1111-1111-1111-111111111111',
        ),
      );

      final row = InvoicePersist.buildInvoiceSqliteRow(
        prepared,
        nowIso: '2026-07-26T12:00:00.000',
      );

      expect(row['ettn'], '11111111-1111-1111-1111-111111111111');
      expect(row['gib_status'], EinvoiceGibStatus.queued.code);
      expect(row['is_e_invoice'], 1);
    });
  });

  group('InvoicePersist.buildEinvoiceStatusRecord', () {
    test('e-Fatura → dens satırı invoices ile aynı ettn/gib', () {
      final prepared = InvoicePersist.prepareForPersist(
        InvoiceModel(
          id: 'inv-dens-1',
          customerId: 'cust-1',
          invoiceDate: DateTime(2026, 7, 26, 10),
          totalAmount: 333.5,
          invoiceType: 'field_sales.van_sales',
          isEInvoice: true,
          ettn: '22222222-2222-2222-2222-222222222222',
          status: 'Completed',
        ),
      );

      final dens = InvoicePersist.buildEinvoiceStatusRecord(
        prepared,
        nowIso: '2026-07-26T12:00:00.000',
        densId: 'eis-dens-1',
        customerCode: 'C-001',
        customerName: 'Demo Cari',
      );

      expect(dens, isNotNull);
      expect(dens!.invoiceId, 'inv-dens-1');
      expect(
        dens.documentNo,
        OutboundIdempotency.ficheNumber('invoice', 'inv-dens-1'),
      );
      expect(dens.ettn, prepared.ettn);
      expect(dens.gibStatus, EinvoiceGibStatus.queued);
      expect(dens.docSide, EinvoiceDocSide.sales);
      expect(dens.amount, 333.5);
      expect(dens.customerId, 'cust-1');
      expect(dens.customerCode, 'C-001');
      expect(dens.toMap()['ettn'], prepared.ettn);
      expect(dens.toMap()['gib_status'], 'QUEUED');
      expect(dens.toMap()['invoice_id'], 'inv-dens-1');
    });

    test('satın alma e-Fatura → doc_side=purchase', () {
      final prepared = InvoicePersist.prepareForPersist(
        InvoiceModel(
          id: 'inv-buy',
          customerId: 'sup-1',
          invoiceDate: DateTime(2026, 7, 26),
          totalAmount: 10,
          invoiceType: 'field_sales.purchase_invoice',
          isEInvoice: true,
          ettn: '33333333-3333-3333-3333-333333333333',
        ),
      );

      final dens = InvoicePersist.buildEinvoiceStatusRecord(
        prepared,
        nowIso: '2026-07-26T12:00:00.000',
      );

      expect(dens!.docSide, EinvoiceDocSide.purchase);
      expect(dens.docSide.code, 'purchase');
    });

    test('kağıt fatura → dens satırı yok', () {
      final prepared = InvoicePersist.prepareForPersist(
        InvoiceModel(
          id: 'inv-paper',
          customerId: 'c1',
          invoiceDate: DateTime(2026, 7, 26),
          totalAmount: 1,
          isEInvoice: false,
        ),
      );

      final dens = InvoicePersist.buildEinvoiceStatusRecord(
        prepared,
        nowIso: '2026-07-26T12:00:00.000',
      );

      expect(dens, isNull);
    });
  });
}
