// Dosya Adı: price_list_dens_row.dart
// Açıklama: Fiyat listesi dens satırı — price_lists + kalem özeti
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'price_list_seed.dart';

/// {@template price_list_dens_row}
/// Plasiyer fiyat listesi dens satırı (ad · para birimi · kalem adedi).
///
/// Kullanım örneği:
/// ```dart
/// final row = PriceListDensRow.fromListMap(map, itemCount: 3);
/// print(row.currency); // TRY
/// ```
/// {@endtemplate}
class PriceListDensRow {
  /// [id]: price_lists.id
  final String id;

  /// [name]: Liste adı
  final String name;

  /// [currency]: Para birimi kodu
  final String currency;

  /// [itemCount]: Aktif kalem sayısı
  final int itemCount;

  /// [isActive]: Liste aktif mi
  final bool isActive;

  /// {@macro price_list_dens_row}
  const PriceListDensRow({
    required this.id,
    required this.name,
    required this.currency,
    required this.itemCount,
    this.isActive = true,
  });

  /// {@template price_list_dens_row_from_list_map}
  /// Tek `price_lists` satırını dens satıra çevirir.
  ///
  /// Parametreler:
  /// - [map]: SQLite price_lists satırı
  /// - [itemCount]: İlişkili kalem adedi
  ///
  /// Dönüş değeri:
  /// - [PriceListDensRow]: Dens satır
  /// {@endtemplate}
  factory PriceListDensRow.fromListMap(
    Map<String, dynamic> map, {
    int itemCount = 0,
  }) {
    final flag = map['is_active'];
    var active = true;
    if (flag is int) {
      active = flag == 1;
    } else if (flag != null) {
      active = flag.toString() == '1' ||
          flag.toString().toLowerCase() == 'true';
    }
    return PriceListDensRow(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      currency: (map['currency'] ?? 'TRY').toString(),
      itemCount: itemCount,
      isActive: active,
    );
  }

  /// {@template price_list_dens_row_from_seed}
  /// Seed listelerinden dens satır listesi üretir.
  ///
  /// Dönüş değeri:
  /// - [List]: Dens fiyat listesi satırları
  /// {@endtemplate}
  static List<PriceListDensRow> fromSeed() {
    return PriceListSeed.listMaps
        .map(
          (m) => PriceListDensRow.fromListMap(
            m,
            itemCount: PriceListSeed.itemCountFor(
              (m['id'] ?? '').toString(),
            ),
          ),
        )
        .where((r) => r.isActive)
        .toList(growable: false);
  }

  /// {@template price_list_dens_row_from_maps}
  /// SQLite listeleri + kalem sayımı ile dens satırlar.
  ///
  /// Parametreler:
  /// - [listMaps]: price_lists satırları
  /// - [itemCountByListId]: liste id → kalem adedi
  ///
  /// Dönüş değeri:
  /// - [List]: Aktif dens satırlar (ada göre)
  /// {@endtemplate}
  static List<PriceListDensRow> fromMaps({
    required List<Map<String, dynamic>> listMaps,
    required Map<String, int> itemCountByListId,
  }) {
    final rows = listMaps
        .map(
          (m) {
            final id = (m['id'] ?? '').toString();
            return PriceListDensRow.fromListMap(
              m,
              itemCount: itemCountByListId[id] ?? 0,
            );
          },
        )
        .where((r) => r.isActive)
        .toList();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return List<PriceListDensRow>.unmodifiable(rows);
  }
}
