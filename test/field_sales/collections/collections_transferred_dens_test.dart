// Dosya Adı: collections_transferred_dens_test.dart
// Açıklama: K09 Transfer edilen tahsilat dens — is_synced=1 SQLite filtre
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/collection_transferred_row.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collections_transferred_screen.dart';

void main() {
  group('CollectionTransferredRow dens (is_synced=1)', () {
    test('yalnız transfer edilen (is_synced=1) satırlar alınır', () {
      final rows = CollectionTransferredRow.fromCollectionMaps([
        {
          'id': 't1',
          'customer_id': 'C1',
          'customer_name': 'ABC Market',
          'amount': 150.5,
          'payment_type': 'cash',
          'collection_date': '2026-07-25T10:00:00.000',
          'document_no': 'TH-001',
          'cash_code': '01',
          'is_synced': 1,
        },
        {
          'id': 'u1',
          'customer_id': 'C2',
          'customer_name': 'Bekleyen',
          'amount': 90,
          'payment_type': 'check',
          'collection_date': '2026-07-26T09:00:00.000',
          'is_synced': 0,
        },
      ]);

      expect(rows.length, 1);
      expect(rows.first.id, 't1');
      expect(rows.first.customerName, 'ABC Market');
      expect(rows.first.amountDisplay, contains('150.50'));
      expect(rows.first.dateDisplay, '25-07-2026');
      expect(
        rows.first.paymentTypeL10nKey,
        'field_sales.finance_type_cash_in',
      );
      expect(rows.first.documentNo, 'TH-001');
    });

    test('tarihe göre yeni → eski sıralar', () {
      final rows = CollectionTransferredRow.fromCollectionMaps([
        {
          'id': 'old',
          'customer_name': 'Eski',
          'amount': 10,
          'payment_type': 'cash',
          'collection_date': '2026-07-20',
          'is_synced': 1,
        },
        {
          'id': 'new',
          'customer_name': 'Yeni',
          'amount': 20,
          'payment_type': 'note',
          'collection_date': '2026-07-26',
          'is_synced': 1,
        },
      ]);

      expect(rows.map((r) => r.id).toList(), ['new', 'old']);
    });

    test('customer_name yoksa customer_id kullanılır', () {
      final rows = CollectionTransferredRow.fromCollectionMaps([
        {
          'id': 'x',
          'customer_id': 'CARI-9',
          'amount': 1,
          'payment_type': 'credit_card',
          'collection_date': '2026-07-01',
          'is_synced': 1,
        },
      ]);
      expect(rows.single.customerName, 'CARI-9');
      expect(
        rows.single.paymentTypeL10nKey,
        'field_sales.finance_type_card_in',
      );
    });
  });

  group('CollectionsTransferredScreen densCache', () {
    test('applyDensCacheFromMaps densCount = densRows.length', () {
      final n = CollectionsTransferredScreen.applyDensCacheFromMaps([
        {
          'id': 'a',
          'customer_name': 'A',
          'amount': 5,
          'payment_type': 'cash',
          'collection_date': '2026-07-26',
          'is_synced': 1,
        },
        {
          'id': 'b',
          'customer_name': 'B',
          'amount': 7,
          'payment_type': 'cash',
          'collection_date': '2026-07-25',
          'is_synced': 0,
        },
      ]);
      expect(n, 1);
      expect(CollectionsTransferredScreen.densCount, 1);
      expect(CollectionsTransferredScreen.densRows.length, 1);
    });

    test('boş sync listesi densCount = 0', () {
      final n = CollectionsTransferredScreen.applyDensCacheFromMaps([
        {
          'id': 'pending',
          'customer_name': 'P',
          'amount': 1,
          'payment_type': 'cash',
          'collection_date': '2026-07-26',
          'is_synced': 0,
        },
      ]);
      expect(n, 0);
      expect(CollectionsTransferredScreen.densCount, 0);
    });
  });
}
