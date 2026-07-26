// Dosya Adı: product_catalog_store.dart
// Açıklama: Ürün katalog dens satırları SQLite okuma + minimal seed
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/product_catalog_row.dart';
import '../model/product_catalog_seed.dart';

/// {@template product_catalog_store}
/// `products` tablosunu oluşturur, boşsa seedler, dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = ProductCatalogStore();
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class ProductCatalogStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro product_catalog_store}
  const ProductCatalogStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = ProductCatalogSeed.tableName;

  /// {@template product_catalog_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template product_catalog_store_ensure}
  /// Tabloyu oluşturur (yoksa) ve boşsa seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createProductsTable);
    await seedIfEmpty(db);
  }

  /// {@template product_catalog_store_seed_if_empty}
  /// Tablo boşsa MBT dens örnek ürünleri ekler.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    for (final row in ProductCatalogSeed.defaultRows) {
      batch.insert(
        tableName,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template product_catalog_store_load_all}
  /// Tüm ürün dens satırlarını ada göre artan sırada döner.
  ///
  /// Parametreler:
  /// - [search]: Opsiyonel kod/ad/barkod filtresi
  ///
  /// Dönüş değeri:
  /// - [List<ProductCatalogRow>]: Dens katalog satırları
  /// {@endtemplate}
  Future<List<ProductCatalogRow>> loadAll({String search = ''}) async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      orderBy: 'LOWER(name) ASC, LOWER(code) ASC',
    );
    final rows = ProductCatalogRow.fromMaps(maps);
    final q = search.trim();
    if (q.isEmpty) return rows;
    return rows.where((r) => r.matches(q)).toList(growable: false);
  }
}
