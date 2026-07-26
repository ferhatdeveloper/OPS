// Dosya Adı: price_list_store.dart
// Açıklama: Fiyat listesi dens satırları SQLite okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/price_list_dens_row.dart';
import '../model/price_list_seed.dart';

/// {@template price_list_store}
/// `price_lists` / `price_list_items` tablolarını oluşturur (yoksa)
/// ve aktif dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = PriceListStore();
/// final rows = await store.loadDensRows();
/// ```
/// {@endtemplate}
class PriceListStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro price_list_store}
  const PriceListStore({this.openDb});

  /// {@template price_list_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template price_list_store_ensure}
  /// Fiyat listesi tablolarını oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createPriceListsTable);
    await db.execute(SqlQuerys.createPriceListItemsTable);
    await db.execute(SqlQuerys.createCustomerPriceMapsTable);
  }

  /// {@template price_list_store_load_dens}
  /// Aktif dens fiyat listelerini kalem adediyle döner.
  /// Tablo boş / hata → seed dens satırlar.
  ///
  /// Dönüş değeri:
  /// - [List<PriceListDensRow>]: Dens satırlar
  /// {@endtemplate}
  Future<List<PriceListDensRow>> loadDensRows() async {
    try {
      await ensureReady();
      final db = await _db();
      final listMaps = await db.query(
        PriceListSeed.listsTable,
        orderBy: 'name ASC',
      );
      if (listMaps.isEmpty) {
        return PriceListDensRow.fromSeed();
      }
      final counts = <String, int>{};
      for (final list in listMaps) {
        final id = (list['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final countRows = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM ${PriceListSeed.itemsTable} '
          'WHERE price_list_id = ?',
          [id],
        );
        counts[id] = (countRows.first['c'] as num?)?.toInt() ?? 0;
      }
      return PriceListDensRow.fromMaps(
        listMaps: listMaps,
        itemCountByListId: counts,
      );
    } catch (_) {
      return PriceListDensRow.fromSeed();
    }
  }

  /// {@template price_list_store_load_items}
  /// Verilen listenin kalem map’lerini döner.
  ///
  /// Parametreler:
  /// - [priceListId]: Liste id
  ///
  /// Dönüş değeri:
  /// - [List]: price_list_items satırları
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> loadItems(String priceListId) async {
    try {
      await ensureReady();
      final db = await _db();
      return db.query(
        PriceListSeed.itemsTable,
        where: 'price_list_id = ?',
        whereArgs: [priceListId],
        orderBy: 'product_id ASC',
      );
    } catch (_) {
      return PriceListSeed.itemMaps
          .where((m) => m['price_list_id'] == priceListId)
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false);
    }
  }
}
