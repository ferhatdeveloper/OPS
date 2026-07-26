// Dosya Adı: einvoice_status_record_test.dart
// Açıklama: e-Fatura dens ETTN/GİB model + seed birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_gib_status.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_status_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_status_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/einvoice_status_screen.dart';

void main() {
  group('EinvoiceGibStatus', () {
    test('kodlar benzersiz ve bilinen', () {
      final codes = EinvoiceGibStatus.values.map((e) => e.code).toSet();
      expect(codes.length, EinvoiceGibStatus.values.length);
      expect(EinvoiceGibStatus.isKnown('SENT'), isTrue);
      expect(EinvoiceGibStatus.isKnown('nope'), isFalse);
      expect(EinvoiceGibStatus.fromCode('accepted'), EinvoiceGibStatus.accepted);
      expect(EinvoiceGibStatus.fromCode(null), EinvoiceGibStatus.draft);
    });
  });

  group('EinvoiceStatusRecord', () {
    test('toMap/fromMap ETTN ve gib_status korur', () {
      final row = EinvoiceStatusRecord(
        id: 't1',
        documentNo: 'EF1',
        ettn: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        gibStatus: EinvoiceGibStatus.sent,
        docSide: EinvoiceDocSide.sales,
        amount: 10.5,
      );
      final map = row.toMap();
      expect(map['ettn'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(map['gib_status'], 'SENT');
      expect(map['doc_side'], 'sales');
      expect(map['ONAY'], 0);

      final back = EinvoiceStatusRecord.fromMap(map);
      expect(back.ettn, row.ettn);
      expect(back.gibStatus, EinvoiceGibStatus.sent);
      expect(back.gibStatusCode, 'SENT');
      expect(back.documentNo, 'EF1');
      expect(back.amount, 10.5);
    });
  });

  group('EinvoiceStatusSeed', () {
    test('route ve stub satırlarda ETTN/GİB dolu', () {
      expect(EinvoiceStatusSeed.route, EinvoiceStatusScreen.routeName);
      expect(EinvoiceStatusSeed.submenuTitle, 'e-Fatura Durum');
      expect(EinvoiceStatusSeed.tableName, 'einvoice_status');
      expect(EinvoiceStatusSeed.defaultRows, isNotEmpty);
      for (final r in EinvoiceStatusSeed.defaultRows) {
        expect(r.ettn, isNotEmpty);
        expect(EinvoiceGibStatus.isKnown(r.gibStatusCode), isTrue);
        expect(r.documentNo, isNotEmpty);
      }
      expect(EinvoiceStatusSeed.salesRows.length, greaterThan(0));
      expect(EinvoiceStatusSeed.purchaseRows.length, greaterThan(0));
      expect(
        EinvoiceStatusSeed.defaultMaps.first['ettn'],
        isNotEmpty,
      );
    });
  });
}
