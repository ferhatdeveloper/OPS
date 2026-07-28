// Dosya Adı: menu_favorites_store.dart
// Açıklama: Sık kullanılan menü UUID’lerini SQLite menu_favorites tablosunda tutar
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

/// {@template menu_favorites_store}
/// Favori menü UUID kalıcılığı (`menu_favorites`).
///
/// `seedFieldSalesMockData` menü satırlarını silip yeniden yazdığı için
/// `menu.is_favorite` tek başına yetmez; UUID’ler bu tabloda saklanır.
///
/// Kullanım örneği:
/// ```dart
/// final store = MenuFavoritesStore(db);
/// await store.add('fs_customers');
/// await store.applyFavoritesToMenu();
/// ```
/// {@endtemplate}
class MenuFavoritesStore {
  /// [tableName]: SQLite tablo adı
  static const String tableName = 'menu_favorites';

  /// [_db]: Açık SQLite bağlantısı
  final Database _db;

  /// {@macro menu_favorites_store}
  MenuFavoritesStore(this._db);

  /// {@template menu_favorites_store_list_uuids}
  /// Kayıtlı favori menü UUID listesi (sıralı).
  ///
  /// Dönüş değeri:
  /// - [List<String>]: UUID listesi
  /// {@endtemplate}
  Future<List<String>> listUuids() async {
    final rows = await _db.query(
      tableName,
      columns: ['menu_uuid'],
      orderBy: 'menu_uuid ASC',
    );
    return rows
        .map((r) => (r['menu_uuid'] as String?)?.trim() ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
  }

  /// {@template menu_favorites_store_contains}
  /// UUID favoride mi?
  ///
  /// Parametreler:
  /// - [menuUuid]: Menü UUID
  ///
  /// Dönüş değeri:
  /// - [bool]: Kayıtlıysa true
  /// {@endtemplate}
  Future<bool> contains(String menuUuid) async {
    final uuid = menuUuid.trim();
    if (uuid.isEmpty) return false;
    final rows = await _db.query(
      tableName,
      columns: ['menu_uuid'],
      where: 'menu_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// {@template menu_favorites_store_add}
  /// Favoriye ekler (idempotent upsert).
  ///
  /// Parametreler:
  /// - [menuUuid]: Menü UUID
  /// {@endtemplate}
  Future<void> add(String menuUuid) async {
    final uuid = menuUuid.trim();
    if (uuid.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      tableName,
      {
        'menu_uuid': uuid,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// {@template menu_favorites_store_remove}
  /// Favoriden çıkarır.
  ///
  /// Parametreler:
  /// - [menuUuid]: Menü UUID
  /// {@endtemplate}
  Future<void> remove(String menuUuid) async {
    final uuid = menuUuid.trim();
    if (uuid.isEmpty) return;
    await _db.delete(
      tableName,
      where: 'menu_uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// {@template menu_favorites_store_replace_all}
  /// Favori setini tamamen değiştirir.
  ///
  /// Parametreler:
  /// - [menuUuids]: Yeni favori UUID listesi
  /// {@endtemplate}
  Future<void> replaceAll(List<String> menuUuids) async {
    final cleaned = menuUuids
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    await _db.transaction((txn) async {
      await txn.delete(tableName);
      final now = DateTime.now().toIso8601String();
      for (final uuid in cleaned) {
        await txn.insert(tableName, {
          'menu_uuid': uuid,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  /// {@template menu_favorites_store_migrate_from_menu_flags}
  /// Mevcut `menu.is_favorite = 1` satırlarını `menu_favorites`’a taşır.
  /// Seed öncesi çağrılır.
  /// {@endtemplate}
  Future<void> migrateFromMenuFlags() async {
    final rows = await _db.query(
      'menu',
      columns: ['uuid'],
      where: 'is_favorite = 1',
    );
    for (final row in rows) {
      final uuid = (row['uuid'] as String?)?.trim() ?? '';
      if (uuid.isEmpty) continue;
      await add(uuid);
    }
  }

  /// {@template menu_favorites_store_apply_to_menu}
  /// `menu_favorites` → `menu.is_favorite` eşlemesi (seed sonrası).
  /// {@endtemplate}
  Future<void> applyFavoritesToMenu() async {
    final uuids = await listUuids();
    await _db.transaction((txn) async {
      await txn.update('menu', {'is_favorite': 0});
      for (final uuid in uuids) {
        await txn.update(
          'menu',
          {'is_favorite': 1},
          where: 'uuid = ?',
          whereArgs: [uuid],
        );
      }
    });
  }
}
