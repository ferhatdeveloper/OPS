// Dosya Adı: collection_untransferred_dens_tile_test.dart
// Açıklama: Tahsilat dens → MbtQueueRow birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/collection_untransferred_record.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/collection_untransferred_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collections_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/widgets/collection_untransferred_dens_tile.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/mbt_sales_purchase_queue_body.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalization l10n;

  setUpAll(() async {
    l10n = AppLocalization(const Locale('tr', 'TR'));
    final ok = await l10n.load();
    assert(ok);
  });

  group('CollectionUntransferredSeed', () {
    test('route ve satırlar isSynced=false', () {
      expect(
        CollectionUntransferredSeed.route,
        CollectionsUntransferredScreen.routeName,
      );
      expect(CollectionUntransferredSeed.defaultRows, isNotEmpty);
      for (final r in CollectionUntransferredSeed.defaultRows) {
        expect(r.isSynced, isFalse);
        expect(r.documentNo, isNotEmpty);
        expect(r.customerCode, isNotEmpty);
      }
      expect(CollectionUntransferredSeed.salesRows, isNotEmpty);
      expect(CollectionUntransferredSeed.purchaseRows, isNotEmpty);
    });
  });

  group('CollectionUntransferredDensTile', () {
    test('toQueueRow dens alanları taşır', () {
      final record = CollectionUntransferredRecord(
        id: 'cu-1',
        documentNo: 'TH-100',
        customerCode: 'C001',
        customerName: 'Demo Cari',
        amount: 150.5,
        paymentType: 'Cash',
        collectionDate: DateTime(2026, 7, 26),
        docSide: CollectionUntransferredDocSide.sales,
        cashCode: '01',
        currencyCode: 'TRY',
      );
      final row = CollectionUntransferredDensTile.toQueueRow(record, l10n);
      expect(row.id, 'cu-1');
      expect(row.side, MbtQueueDocSide.sales);
      expect(row.title, 'TH-100');
      expect(row.subtitle, contains('C001'));
      expect(row.subtitle, contains('Demo Cari'));
      expect(row.searchBlob, contains('Cash'));
      expect(row.searchBlob, contains('01'));
    });

    test('toQueueRows seed uzunluğu korunur', () {
      final rows = CollectionUntransferredDensTile.toQueueRows(
        CollectionUntransferredSeed.defaultRows,
        l10n,
      );
      expect(rows.length, CollectionUntransferredSeed.defaultRows.length);
    });
  });
}
