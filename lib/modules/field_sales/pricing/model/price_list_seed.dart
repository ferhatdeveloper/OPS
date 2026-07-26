// Dosya Adı: price_list_seed.dart
// Açıklama: Fiyat listesi dens SQLite seed (price_lists / items / maps)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template price_list_seed}
/// `price_lists` / `price_list_items` / `customer_price_maps` boşken
/// dens stub seed satırları (mock ürün `prod_1`…`prod_3`).
///
/// Kullanım örneği:
/// ```dart
/// for (final map in PriceListSeed.listMaps) {
///   await db.insert(PriceListSeed.listsTable, map);
/// }
/// ```
/// {@endtemplate}
class PriceListSeed {
  PriceListSeed._();

  /// [route]: Named route — menü / AppRoutes
  static const String route = '/field-sales/price-list';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Fiyat Listesi';

  /// [listsTable]: Fiyat listesi tablosu
  static const String listsTable = 'price_lists';

  /// [itemsTable]: Liste kalemleri tablosu
  static const String itemsTable = 'price_list_items';

  /// [mapsTable]: Cari ↔ liste eşleme tablosu
  static const String mapsTable = 'customer_price_maps';

  /// [idGenel]: Genel (perakende) liste
  static const String idGenel = 'pl_genel';

  /// [idBayi]: Bayi liste
  static const String idBayi = 'pl_bayi';

  /// Aktif dens fiyat listeleri.
  static const List<Map<String, dynamic>> listMaps = [
    {
      'id': idGenel,
      'name': 'Genel Fiyat Listesi',
      'currency': 'TRY',
      'is_active': 1,
      'is_synced': 0,
    },
    {
      'id': idBayi,
      'name': 'Bayi Fiyat Listesi',
      'currency': 'TRY',
      'is_active': 1,
      'is_synced': 0,
    },
  ];

  /// Liste kalemleri (mock `prod_*` + birim fiyat).
  static const List<Map<String, dynamic>> itemMaps = [
    {
      'id': 'pli_genel_1',
      'price_list_id': idGenel,
      'product_id': 'prod_1',
      'unit_name': 'Adet',
      'price': 45.0,
      'min_quantity': 0.0,
    },
    {
      'id': 'pli_genel_2',
      'price_list_id': idGenel,
      'product_id': 'prod_2',
      'unit_name': 'Paket',
      'price': 120.0,
      'min_quantity': 0.0,
    },
    {
      'id': 'pli_genel_3',
      'price_list_id': idGenel,
      'product_id': 'prod_3',
      'unit_name': 'Teneke',
      'price': 185.9,
      'min_quantity': 0.0,
    },
    {
      'id': 'pli_bayi_1',
      'price_list_id': idBayi,
      'product_id': 'prod_1',
      'unit_name': 'Adet',
      'price': 39.5,
      'min_quantity': 10.0,
    },
    {
      'id': 'pli_bayi_2',
      'price_list_id': idBayi,
      'product_id': 'prod_2',
      'unit_name': 'Paket',
      'price': 105.0,
      'min_quantity': 5.0,
    },
    {
      'id': 'pli_bayi_3',
      'price_list_id': idBayi,
      'product_id': 'prod_3',
      'unit_name': 'Teneke',
      'price': 169.0,
      'min_quantity': 2.0,
    },
  ];

  /// Cari ↔ liste eşlemeleri (mock `cust_*`).
  static const List<Map<String, dynamic>> mapMaps = [
    {
      'id': 'cpm_cust_1',
      'customer_id': 'cust_1',
      'price_list_id': idBayi,
      'is_active': 1,
      'is_synced': 0,
      'created_at': '2026-07-26T00:00:00.000',
    },
    {
      'id': 'cpm_cust_2',
      'customer_id': 'cust_2',
      'price_list_id': idGenel,
      'is_active': 1,
      'is_synced': 0,
      'created_at': '2026-07-26T00:00:00.000',
    },
  ];

  /// {@template price_list_seed_item_count}
  /// Verilen liste id için seed kalem adedi.
  ///
  /// Parametreler:
  /// - [priceListId]: `price_lists.id`
  ///
  /// Dönüş değeri:
  /// - [int]: Kalem sayısı
  /// {@endtemplate}
  static int itemCountFor(String priceListId) {
    return itemMaps
        .where((m) => m['price_list_id'] == priceListId)
        .length;
  }
}
