// Dosya Adı: warehouse_master_store_test.dart
// Açıklama: Ambar master dens CRUD + sync_queue birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_master_seed.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/warehouse_master_store.dart';

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
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createWarehousesTable);
        await db.execute(SqlQuerys.createSyncQueueTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('seed + create + update + softDelete + sync_queue', () async {
    final store = WarehouseMasterStore(openDb: () async => db);
    await store.ensureReady();
    final seeded = await store.listActive();
    expect(seeded.length, WarehouseMasterSeed.defaultRows.length);

    final created = await store.create(
      code: 'TST',
      name: 'Test Ambar',
      type: WarehouseMasterSeed.typeVehicle,
    );
    expect(created.code, 'TST');
    expect(created.type, WarehouseMasterSeed.typeVehicle);

    final queueAfterCreate = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [created.id],
    );
    expect(queueAfterCreate, isNotEmpty);
    expect(queueAfterCreate.first['entity_type'], 'warehouse');
    expect(
      (queueAfterCreate.first['payload'] as String).contains('"op":"upsert"'),
      isTrue,
    );

    final updated = await store.update(
      WarehouseMasterRecord(
        id: created.id,
        code: created.code,
        name: 'Test Ambar 2',
        type: created.type,
        createdAt: created.createdAt,
      ),
    );
    expect(updated.name, 'Test Ambar 2');
    final found = await store.findByCode('TST');
    expect(found?.name, 'Test Ambar 2');

    final ok = await store.softDelete(created.id);
    expect(ok, isTrue);
    final after = await store.listActive();
    expect(after.any((r) => r.id == created.id), isFalse);

    final queueDel = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [created.id],
    );
    expect(
      queueDel.any(
        (r) => (jsonDecode(r['payload'] as String) as Map)['op'] == 'delete',
      ),
      isTrue,
    );
  });

  test('create boş kod ArgumentError', () async {
    final store = WarehouseMasterStore(openDb: () async => db);
    expect(
      () => store.create(code: '', name: 'X'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
