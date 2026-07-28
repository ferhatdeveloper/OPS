// Dosya Adı: product_catalog_store.dart
// Açıklama: Ürün katalog dens — SQLite CRUD + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/tenant/postgrest_master_sync.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../service/postgres_service.dart';
import '../model/product_catalog_row.dart';
import '../model/product_catalog_seed.dart';

/// {@template product_catalog_store}
/// `products` tablosunu oluşturur, boşsa seedler, dens satırları okur;
/// upsert / silme offline-first sync_queue ile.
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

  /// [entityType]: sync_queue entity_type
  static const String entityType = 'product';

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
  ///
  /// Parametreler:
  /// - [seed]: true ise boş tabloya dens seed yazar (liste okuma)
  /// {@endtemplate}
  Future<void> ensureReady({bool seed = true}) async {
    final db = await _db();
    await db.execute(SqlQuerys.createProductsTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
    if (!seed) return;
    final rest = PostgresService.instance.activeRemoteRestUrl.trim();
    if (rest.isEmpty) {
      await seedIfEmpty(db);
    }
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

  /// Katalog listesinde gösterilecek son eklenen ürün adedi
  static const int recentLimit = 50;

  /// {@template product_catalog_store_load_all}
  /// Son eklenen ürün dens satırlarını döner (varsayılan 50).
  /// Sıra: `created_at` / `updated_at` azalan.
  ///
  /// Parametreler:
  /// - [search]: Opsiyonel kod/ad/barkod filtresi (son N içinde)
  /// - [limit]: Maksimum satır (0 = sınırsız; varsayılan [recentLimit])
  ///
  /// Dönüş değeri:
  /// - [List<ProductCatalogRow>]: Dens katalog satırları
  /// {@endtemplate}
  Future<List<ProductCatalogRow>> loadAll({
    String search = '',
    int limit = recentLimit,
  }) async {
    await ensureReady();
    // Kiracı PostgREST aktifse ürünleri uzak → SQLite yenile
    final rest = PostgresService.instance.activeRemoteRestUrl.trim();
    if (rest.isNotEmpty) {
      try {
        await PostgrestMasterSync().syncCustomersAndProducts();
      } catch (_) {}
    }
    final db = await _db();
    final maps = await db.query(
      tableName,
      orderBy:
          'COALESCE(NULLIF(created_at, ""), NULLIF(updated_at, "")) DESC, '
          'rowid DESC',
      limit: limit > 0 ? limit : null,
    );
    // Sorgu sırasını koru (yeniden ada göre sıralama yok)
    var rows = maps.map(ProductCatalogRow.fromMap).toList(growable: false);
    final q = search.trim();
    if (q.isEmpty) return rows;
    return rows.where((r) => r.matches(q)).toList(growable: false);
  }

  /// {@template product_catalog_store_upsert}
  /// Ürünü SQLite'a yazar ve sync_queue'ya ekler.
  ///
  /// Parametreler:
  /// - [row]: Kaydedilecek dens satır
  ///
  /// Dönüş değeri:
  /// - [ProductCatalogRow]: Kaydedilen satır
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: Kod veya ad boş
  /// {@endtemplate}
  Future<ProductCatalogRow> upsert(ProductCatalogRow row) async {
    final code = row.code.trim();
    final name = row.name.trim();
    if (code.isEmpty || name.isEmpty) {
      throw ArgumentError('product code/name required');
    }

    await ensureReady(seed: false);
    final db = await _db();
    final id = row.id.trim().isEmpty ? const Uuid().v4() : row.id.trim();
    String? createdAt;
    final existing = await db.query(
      tableName,
      columns: ['created_at'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      createdAt = existing.first['created_at']?.toString();
    }
    final saved = ProductCatalogRow(
      id: id,
      code: code,
      name: name,
      barcode: row.barcode.trim(),
      unit: row.unit.trim().isEmpty ? 'ADET' : row.unit.trim(),
      price: row.price,
      vatRate: row.vatRate,
      stockQuantity: row.stockQuantity,
      category: row.category.trim(),
    );
    final map = saved.toMap();
    if (createdAt != null && createdAt.isNotEmpty) {
      map['created_at'] = createdAt;
    }
    final jobId = const Uuid().v4();

    await db.transaction((txn) async {
      await txn.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert('sync_queue', {
        'id': jobId,
        'entity_type': entityType,
        'entity_id': id,
        'payload': jsonEncode({...map, 'op': 'upsert'}),
        'priority': 0,
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    if (openDb == null) {
      JobQueueService().processQueue();
    }
    return saved;
  }

  /// {@template product_catalog_store_delete}
  /// Ürünü SQLite'tan siler ve sync_queue'ya delete ekler.
  ///
  /// Parametreler:
  /// - [productId]: products.id
  ///
  /// Dönüş değeri:
  /// - [bool]: Silinen satır varsa true
  /// {@endtemplate}
  Future<bool> deleteById(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return false;

    await ensureReady(seed: false);
    final db = await _db();
    final jobId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    var deleted = 0;

    await db.transaction((txn) async {
      deleted = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deleted > 0) {
        await txn.insert('sync_queue', {
          'id': jobId,
          'entity_type': entityType,
          'entity_id': id,
          'payload': jsonEncode({
            'id': id,
            'op': 'delete',
            'updated_at': now,
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': now,
        });
      }
    });

    if (deleted > 0 && openDb == null) {
      JobQueueService().processQueue();
    }
    return deleted > 0;
  }

  /// {@template product_catalog_store_get_by_id}
  /// Tek ürün dens satırı.
  /// {@endtemplate}
  Future<ProductCatalogRow?> getById(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return null;
    await ensureReady(seed: false);
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductCatalogRow.fromMap(maps.first);
  }
}
