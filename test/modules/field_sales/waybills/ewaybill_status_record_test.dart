// Dosya Adı: ewaybill_status_record_test.dart
// Açıklama: e-İrsaliye dens ETTN/GİB model + seed birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/ewaybill_gib_status.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/ewaybill_status_record.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/ewaybill_status_seed.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/ewaybill_status_screen.dart';

void main() {
  group('EwaybillGibStatus', () {
    test('kodlar benzersiz ve bilinen', () {
      final codes = EwaybillGibStatus.values.map((e) => e.code).toSet();
      expect(codes.length, EwaybillGibStatus.values.length);
      expect(EwaybillGibStatus.isKnown('SENT'), isTrue);
      expect(EwaybillGibStatus.isKnown('nope'), isFalse);
      expect(EwaybillGibStatus.fromCode('accepted'), EwaybillGibStatus.accepted);
      expect(EwaybillGibStatus.fromCode(null), EwaybillGibStatus.draft);
    });
  });

  group('EwaybillStatusRecord', () {
    test('toMap/fromMap ETTN ve gib_status korur', () {
      final row = EwaybillStatusRecord(
        id: 't1',
        documentNo: 'IRS1',
        ettn: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        gibStatus: EwaybillGibStatus.sent,
        docSide: EwaybillDocSide.sales,
        amount: 10.5,
      );
      final map = row.toMap();
      expect(map['ettn'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(map['gib_status'], 'SENT');
      expect(map['doc_side'], 'sales');
      expect(map['ONAY'], 0);

      final back = EwaybillStatusRecord.fromMap(map);
      expect(back.ettn, row.ettn);
      expect(back.gibStatus, EwaybillGibStatus.sent);
      expect(back.gibStatusCode, 'SENT');
      expect(back.documentNo, 'IRS1');
      expect(back.amount, 10.5);
    });
  });

  group('EwaybillStatusSeed', () {
    test('route ve stub satırlarda ETTN/GİB dolu', () {
      expect(EwaybillStatusSeed.route, EwaybillStatusScreen.routeName);
      expect(EwaybillStatusSeed.submenuTitle, 'e-İrsaliye Durum');
      expect(EwaybillStatusSeed.tableName, 'ewaybill_status');
      expect(EwaybillStatusSeed.defaultRows, isNotEmpty);
      for (final r in EwaybillStatusSeed.defaultRows) {
        expect(r.ettn, isNotEmpty);
        expect(EwaybillGibStatus.isKnown(r.gibStatusCode), isTrue);
        expect(r.documentNo, isNotEmpty);
      }
      expect(EwaybillStatusSeed.salesRows.length, greaterThan(0));
      expect(EwaybillStatusSeed.purchaseRows.length, greaterThan(0));
      expect(
        EwaybillStatusSeed.defaultMaps.first['ettn'],
        isNotEmpty,
      );
    });
  });
}
