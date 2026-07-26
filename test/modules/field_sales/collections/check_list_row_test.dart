// Dosya Adı: check_list_row_test.dart
// Açıklama: Çek listesi dens satır — check tipi filtre + durum süzgeç
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_row.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_status.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/collection_model.dart';

void main() {
  group('CheckListStatus', () {
    test('MBT sekme sırası 8 durum', () {
      expect(CheckListStatus.tabs.length, 8);
      expect(CheckListStatus.tabs.first, CheckListStatus.collateral);
      expect(CheckListStatus.tabs.last, CheckListStatus.issuedCompany);
    });

    test('fromCode eşlemesi', () {
      expect(
        CheckListStatus.fromCode('collection'),
        CheckListStatus.collection,
      );
      expect(
        CheckListStatus.fromCode('paid_company'),
        CheckListStatus.paidCompany,
      );
      expect(
        CheckListStatus.fromCode(null),
        CheckListStatus.collection,
      );
    });
  });

  group('CheckListRow', () {
    test('yalnız payment_type=check collections dens satırı olur', () {
      final check = CollectionModel(
        id: 'c1',
        customerId: 'C001',
        amount: 1500,
        paymentType: 'check',
        collectionDate: DateTime(2026, 7, 26),
        checkNumber: 'CHK-1',
        bankName: 'Ziraat',
      );
      final cash = CollectionModel(
        id: 'c2',
        customerId: 'C001',
        amount: 100,
        paymentType: 'cash',
        collectionDate: DateTime(2026, 7, 26),
      );

      expect(CheckListRow.isCheckPaymentType('Check'), isTrue);
      expect(CheckListRow.isCheckPaymentType('çek'), isTrue);
      expect(CheckListRow.isCheckPaymentType('cash'), isFalse);

      final row = CheckListRow.fromCollection(check);
      expect(row, isNotNull);
      expect(row!.checkNumber, 'CHK-1');
      expect(row.status, CheckListStatus.collection);
      expect(CheckListRow.fromCollection(cash), isNull);
    });

    test('fromCollections yalnızca check satırlarını alır', () {
      final rows = CheckListRow.fromCollections([
        CollectionModel(
          id: '1',
          customerId: 'A',
          amount: 10,
          paymentType: 'cash',
          collectionDate: DateTime(2026, 7, 1),
        ),
        CollectionModel(
          id: '2',
          customerId: 'B',
          amount: 20,
          paymentType: 'Check',
          collectionDate: DateTime(2026, 7, 2),
          checkNumber: 'X',
        ),
      ]);
      expect(rows.length, 1);
      expect(rows.first.id, '2');
    });

    test('durum + arama filtre ve toplam/adet', () {
      final all = CheckListSeed.defaultRows;
      final collateral = CheckListRow.filter(
        all,
        status: CheckListStatus.collateral,
      );
      expect(collateral, isNotEmpty);
      for (final r in collateral) {
        expect(r.status, CheckListStatus.collateral);
      }

      final hit = CheckListRow.filter(
        all,
        status: CheckListStatus.collection,
        query: 'CHK-SEED-COL',
      );
      expect(hit.length, 1);
      expect(CheckListRow.totalAmount(hit), hit.first.amount);
      expect(CheckListRow.formatAmount(1250.5), '1.250,50');
    });

    test('toMap/fromMap check_status + payment_type=check', () {
      final seed = CheckListSeed.defaultRows.first;
      final back = CheckListRow.fromMap(seed.toMap());
      expect(back, isNotNull);
      expect(back!.id, seed.id);
      expect(back.status, seed.status);
      expect(CheckListRow.isCheckPaymentType(back.paymentType), isTrue);
    });
  });

  group('CheckListSeed', () {
    test('route + her sekmede en az bir örnek', () {
      expect(CheckListSeed.route, '/field-sales/checks');
      expect(CheckListSeed.defaultRows, isNotEmpty);
      for (final status in CheckListStatus.tabs) {
        final found = CheckListSeed.defaultRows.any((r) => r.status == status);
        expect(found, isTrue, reason: 'eksik durum: ${status.code}');
      }
      for (final r in CheckListSeed.defaultRows) {
        expect(CheckListRow.isCheckPaymentType(r.paymentType), isTrue);
      }
    });
  });
}
