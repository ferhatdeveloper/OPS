// Dosya Adı: menu_favorites_store_test.dart
// Açıklama: Favori menü UUID’lerinin SQLite round-trip / seed sonrası restore
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/favorites/viewmodel/menu_favorites_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(SqlQuerys.createMenuTable);
        await database.execute(SqlQuerys.createMenuFavoritesTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertMenu({
    required String uuid,
    required String title,
    int isFavorite = 0,
  }) async {
    await db.insert('menu', {
      'uuid': uuid,
      'title': title,
      'is_visible': 1,
      'is_favorite': isFavorite,
      'module_name': 'FieldSales',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  test('add/remove menu_favorites SQLite round-trip', () async {
    final store = MenuFavoritesStore(db);
    await insertMenu(uuid: 'fs_customers', title: 'Cari');

    expect(await store.listUuids(), isEmpty);

    await store.add('fs_customers');
    expect(await store.listUuids(), ['fs_customers']);
    expect(await store.contains('fs_customers'), isTrue);

    // Yeniden açılmış DB simülasyonu: aynı connection’da yeniden oku
    final store2 = MenuFavoritesStore(db);
    expect(await store2.listUuids(), ['fs_customers']);

    await store2.remove('fs_customers');
    expect(await store2.listUuids(), isEmpty);
    expect(await store2.contains('fs_customers'), isFalse);
  });

  test('seed wipe sonrası applyFavoritesToMenu is_favorite geri yükler', () async {
    final store = MenuFavoritesStore(db);
    await insertMenu(uuid: 'fs_customers', title: 'Cari', isFavorite: 1);
    await insertMenu(uuid: 'fs_order', title: 'Sipariş', isFavorite: 1);
    await insertMenu(uuid: 'fs_invoice', title: 'Fatura', isFavorite: 0);

    // Legacy menu.is_favorite → menu_favorites
    await store.migrateFromMenuFlags();
    expect(
      await store.listUuids(),
      containsAll(['fs_customers', 'fs_order']),
    );

    // Seed gibi menüyü sil + yeniden insert (is_favorite=0)
    await db.delete('menu');
    await insertMenu(uuid: 'fs_customers', title: 'Cari', isFavorite: 0);
    await insertMenu(uuid: 'fs_order', title: 'Sipariş', isFavorite: 0);
    await insertMenu(uuid: 'fs_invoice', title: 'Fatura', isFavorite: 0);

    await store.applyFavoritesToMenu();

    final rows = await db.query(
      'menu',
      columns: ['uuid', 'is_favorite'],
      orderBy: 'uuid',
    );
    final byUuid = {
      for (final r in rows) r['uuid'] as String: r['is_favorite'] as int,
    };
    expect(byUuid['fs_customers'], 1);
    expect(byUuid['fs_order'], 1);
    expect(byUuid['fs_invoice'], 0);
  });

  test('replaceAll favori setini senkron tutar', () async {
    final store = MenuFavoritesStore(db);
    await store.add('fs_customers');
    await store.replaceAll(['fs_order', 'fs_stock']);
    expect(await store.listUuids(), ['fs_order', 'fs_stock']);
  });
}
