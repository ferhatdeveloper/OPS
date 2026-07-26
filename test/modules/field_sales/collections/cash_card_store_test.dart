// Dosya Adı: cash_card_store_test.dart
// Açıklama: CashCardMaster → SQLite cash_cards seed/sync birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_master.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/cash_card_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CashCardSeed', () {
    test('master kodları ile SQLite map hizası', () {
      expect(CashCardSeed.tableName, 'cash_cards');
      expect(CashCardSeed.defaultRows.length, CashCardMaster.options.length);
      expect(
        CashCardSeed.defaultRows.map((r) => r.code).toList(),
        CashCardMaster.codes,
      );
      final maps = CashCardSeed.defaultMaps;
      expect(maps, hasLength(4));
      expect(maps.first['code'], '100 01 01');
      expect(maps.first['name_key'], 'field_sales.cash_card_merkez_tl');
      expect(maps.first['name'], 'MERKEZ TL KASA');
      expect(maps.first['is_active'], 1);
      expect(maps.first['is_synced'], 0);
      expect(maps.last['code'], '200 01 01');
    });
  });

  group('CashCardStore', () {
    late Database db;
    late CashCardStore store;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      store = CashCardStore(openDb: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('ensureReady boş tabloyu master seed ile doldurur', () async {
      await store.ensureReady();

      final rows = await store.listActive();
      expect(rows, hasLength(CashCardMaster.codes.length));
      expect(rows.map((r) => r.code).toList(), CashCardMaster.codes);
      expect(rows.first.nameKey, 'field_sales.cash_card_merkez_tl');
      expect(rows.first.name, 'MERKEZ TL KASA');
    });

    test('seedIfEmpty ikinci çağrıda çoğaltmaz', () async {
      await store.ensureReady();
      await store.seedIfEmpty(db);

      final count = await store.count();
      expect(count, CashCardMaster.codes.length);
    });

    test('syncFromMaster eksik kodu upsert eder', () async {
      await store.ensureReady();
      await db.delete(
        CashCardSeed.tableName,
        where: 'code = ?',
        whereArgs: ['200 01 01'],
      );
      expect(await store.count(), 3);

      final upserted = await store.syncFromMaster();
      expect(upserted, CashCardMaster.codes.length);

      final rows = await store.listActive();
      expect(rows.map((r) => r.code), contains('200 01 01'));
      expect(rows, hasLength(4));
    });

    test('pendingSyncCount is_synced=0 satırları sayar', () async {
      await store.ensureReady();
      expect(await store.pendingSyncCount(), 4);

      await db.update(
        CashCardSeed.tableName,
        {'is_synced': 1},
        where: 'code = ?',
        whereArgs: ['100 01 01'],
      );
      expect(await store.pendingSyncCount(), 3);
    });

    test('markAllSynced bekleyenleri kapatır', () async {
      await store.ensureReady();
      await store.markAllSynced();
      expect(await store.pendingSyncCount(), 0);
    });
  });
}
