// Dosya Adı: batch_expiry_record_test.dart
// Açıklama: Parti / SKT dens model + seed birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/batch_expiry_record.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/batch_expiry_seed.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/batch_expiry_screen.dart';

void main() {
  group('BatchExpiryStatus', () {
    test('kodlar benzersiz ve bilinen', () {
      final codes = BatchExpiryStatus.values.map((e) => e.code).toSet();
      expect(codes.length, BatchExpiryStatus.values.length);
      expect(BatchExpiryStatus.isKnown('OK'), isTrue);
      expect(BatchExpiryStatus.isKnown('NEAR'), isTrue);
      expect(BatchExpiryStatus.isKnown('EXPIRED'), isTrue);
      expect(BatchExpiryStatus.isKnown('nope'), isFalse);
      expect(
        BatchExpiryStatus.fromCode('near_expiry'),
        BatchExpiryStatus.near,
      );
      expect(BatchExpiryStatus.fromCode(null), BatchExpiryStatus.ok);
    });

    test('fromExpiry eşikleri', () {
      final now = DateTime(2026, 7, 26);
      expect(
        BatchExpiryStatus.fromExpiry(
          expiryDate: DateTime(2026, 6, 1),
          now: now,
        ),
        BatchExpiryStatus.expired,
      );
      expect(
        BatchExpiryStatus.fromExpiry(
          expiryDate: DateTime(2026, 8, 10),
          now: now,
          nearDays: 30,
        ),
        BatchExpiryStatus.near,
      );
      expect(
        BatchExpiryStatus.fromExpiry(
          expiryDate: DateTime(2027, 1, 1),
          now: now,
        ),
        BatchExpiryStatus.ok,
      );
    });
  });

  group('BatchExpiryRecord', () {
    test('toMap/fromMap lot ve SKT korur', () {
      final row = BatchExpiryRecord(
        id: 't1',
        productCode: 'STK001',
        productName: 'Demo',
        lotNo: 'L1',
        expiryDate: DateTime(2026, 12, 31),
        quantity: 10.5,
        status: BatchExpiryStatus.near,
      );
      final map = row.toMap();
      expect(map['lot_no'], 'L1');
      expect(map['product_code'], 'STK001');
      expect(map['status'], 'NEAR');
      expect(map['ONAY'], 0);
      expect(map['expiry_date'], isNotEmpty);

      final back = BatchExpiryRecord.fromMap(map);
      expect(back.lotNo, 'L1');
      expect(back.resolvedStatus, BatchExpiryStatus.near);
      expect(back.quantity, 10.5);
      expect(back.expiryDate.year, 2026);
    });
  });

  group('BatchExpirySeed', () {
    test('route ve stub satırlarda lot/SKT dolu', () {
      expect(BatchExpirySeed.route, BatchExpiryScreen.routeName);
      expect(BatchExpirySeed.submenuTitle, 'Parti / SKT');
      expect(BatchExpirySeed.tableName, 'batch_expiry');
      expect(BatchExpirySeed.defaultRows, isNotEmpty);
      for (final r in BatchExpirySeed.defaultRows) {
        expect(r.lotNo, isNotEmpty);
        expect(r.productCode, isNotEmpty);
        expect(BatchExpiryStatus.isKnown(r.statusCode), isTrue);
      }
      expect(BatchExpirySeed.okRows, isNotEmpty);
      expect(BatchExpirySeed.nearRows, isNotEmpty);
      expect(BatchExpirySeed.expiredRows, isNotEmpty);
      expect(
        BatchExpirySeed.defaultMaps.first['lot_no'],
        isNotEmpty,
      );
      expect(BatchExpirySeed.formatDate(DateTime(2026, 7, 26)), '26-07-2026');
    });
  });
}
