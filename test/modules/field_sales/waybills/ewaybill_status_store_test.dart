// Dosya Adı: ewaybill_status_store_test.dart
// Açıklama: ewaybill_status SQLite store seed + loadAll birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/ewaybill_status_seed.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/ewaybill_status_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('EwaybillStatusStore', () {
    test('ensureReady boş tabloya seed yazar; loadAll okur', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      addTearDown(() async => db.close());

      final store = EwaybillStatusStore(openDb: () async => db);
      await store.ensureReady();

      final rows = await store.loadAll();
      expect(rows.length, EwaybillStatusSeed.defaultRows.length);
      expect(rows.first.ettn, isNotEmpty);
      expect(rows.any((r) => r.documentNo.isNotEmpty), isTrue);

      // İkinci çağrı re-seed etmez
      await store.ensureReady();
      final again = await store.loadAll();
      expect(again.length, rows.length);
    });

    test('is_deleted satırları loadAll dışı', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      addTearDown(() async => db.close());

      await db.execute(SqlQuerys.createEwaybillStatusTable);
      final live = EwaybillStatusSeed.defaultRows.first;
      await db.insert(EwaybillStatusSeed.tableName, live.toMap());
      await db.insert(
        EwaybillStatusSeed.tableName,
        live.copyWith(id: 'deleted-1', isDeleted: 1).toMap(),
      );

      final store = EwaybillStatusStore(openDb: () async => db);
      final rows = await store.loadAll();
      expect(rows.length, 1);
      expect(rows.first.id, live.id);
    });
  });
}
