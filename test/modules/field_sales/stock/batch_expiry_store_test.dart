// Dosya Adı: batch_expiry_store_test.dart
// Açıklama: Parti / SKT SQLite store + seed fallback birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/stock/model/batch_expiry_seed.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/batch_expiry_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('loadAllOrSeed boş tabloda seed fallback', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = BatchExpiryStore(openDb: () async => db);
    final rows = await store.loadAllOrSeed();
    expect(rows, isNotEmpty);
    expect(rows.length, BatchExpirySeed.defaultRows.length);
    expect(rows.first.lotNo, BatchExpirySeed.defaultRows.first.lotNo);
  });

  test('loadAllOrSeed SQLite satırlarını önceler', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = BatchExpiryStore(openDb: () async => db);
    await store.ensureReady();

    final live = BatchExpirySeed.defaultRows.first.copyWith(
      id: 'be_live_only',
      lotNo: 'LIVE-LOT',
    );
    await db.insert(BatchExpiryStore.tableName, live.toMap());

    final rows = await store.loadAllOrSeed();
    expect(rows.length, 1);
    expect(rows.first.id, 'be_live_only');
    expect(rows.first.lotNo, 'LIVE-LOT');
  });

  test('loadAll soft-delete satırını hariç tutar', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = BatchExpiryStore(openDb: () async => db);
    await store.ensureReady();

    final live = BatchExpirySeed.defaultRows.first;
    final deleted = live.copyWith(id: 'be_del', isDeleted: 1, lotNo: 'DEL');
    await db.insert(BatchExpiryStore.tableName, live.toMap());
    await db.insert(BatchExpiryStore.tableName, deleted.toMap());

    final rows = await store.loadAll();
    expect(rows.length, 1);
    expect(rows.first.id, live.id);
    expect(rows.any((r) => r.id == 'be_del'), isFalse);
  });
}
