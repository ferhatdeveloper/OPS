// Dosya Adı: price_list_seed_test.dart
// Açıklama: Fiyat listesi dens seed + dens satır birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/pricing/model/price_list_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/pricing/model/price_list_seed.dart';
import 'package:exfin_ops/modules/field_sales/pricing/view/price_list_screen.dart';

void main() {
  group('PriceListSeed', () {
    test('route ve tablolar dolu; kalemler listelere bağlı', () {
      expect(PriceListSeed.route, PriceListScreen.routeName);
      expect(PriceListSeed.submenuTitle, 'Fiyat Listesi');
      expect(PriceListSeed.listsTable, 'price_lists');
      expect(PriceListSeed.itemsTable, 'price_list_items');
      expect(PriceListSeed.mapsTable, 'customer_price_maps');
      expect(PriceListSeed.listMaps, isNotEmpty);
      expect(PriceListSeed.itemMaps, isNotEmpty);
      expect(PriceListSeed.mapMaps, isNotEmpty);

      final listIds = PriceListSeed.listMaps
          .map((m) => m['id'] as String)
          .toSet();
      for (final item in PriceListSeed.itemMaps) {
        expect(listIds.contains(item['price_list_id']), isTrue);
        expect((item['price'] as num) > 0, isTrue);
        expect(item['product_id'], isNotEmpty);
      }
      for (final map in PriceListSeed.mapMaps) {
        expect(listIds.contains(map['price_list_id']), isTrue);
        expect(map['customer_id'], isNotEmpty);
      }
      expect(
        PriceListSeed.itemCountFor(PriceListSeed.idGenel),
        3,
      );
      expect(
        PriceListSeed.itemCountFor(PriceListSeed.idBayi),
        3,
      );
    });
  });

  group('PriceListDensRow', () {
    test('fromSeed aktif satır ve kalem adedi üretir', () {
      final rows = PriceListDensRow.fromSeed();
      expect(rows.length, PriceListSeed.listMaps.length);
      for (final r in rows) {
        expect(r.name, isNotEmpty);
        expect(r.currency, isNotEmpty);
        expect(r.itemCount, greaterThan(0));
        expect(r.isActive, isTrue);
      }
    });

    test('fromListMap is_active=0 satırı işaretler', () {
      final row = PriceListDensRow.fromListMap(
        {
          'id': 'pl_x',
          'name': 'Pasif',
          'currency': 'USD',
          'is_active': 0,
        },
        itemCount: 1,
      );
      expect(row.isActive, isFalse);
      expect(row.currency, 'USD');
      expect(row.itemCount, 1);
    });

    test('fromMaps yalnızca aktifleri ada göre sıralar', () {
      final rows = PriceListDensRow.fromMaps(
        listMaps: const [
          {
            'id': 'b',
            'name': 'Beta',
            'currency': 'TRY',
            'is_active': 1,
          },
          {
            'id': 'a',
            'name': 'Alpha',
            'currency': 'TRY',
            'is_active': 1,
          },
          {
            'id': 'z',
            'name': 'Zulu',
            'currency': 'TRY',
            'is_active': 0,
          },
        ],
        itemCountByListId: const {'a': 2, 'b': 4, 'z': 9},
      );
      expect(rows.length, 2);
      expect(rows.first.name, 'Alpha');
      expect(rows.first.itemCount, 2);
      expect(rows.last.name, 'Beta');
      expect(rows.last.itemCount, 4);
    });
  });
}
