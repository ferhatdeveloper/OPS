// Dosya Adı: customer_save_queue_test.dart
// Açıklama: Cari kaydı sync_queue upsert payload birim testi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('cari upsert map + sync_queue satırı yazılır', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createSyncQueueTable);

    final customer = CustomerModel(
      id: 'cust-1',
      code: 'C-100',
      name: 'Demo Cari',
      createdAt: DateTime(2026, 7, 27),
      updatedAt: DateTime(2026, 7, 27),
    );
    final map = customer.toMap();

    await db.transaction((txn) async {
      await txn.insert(
        'customers',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert('sync_queue', {
        'id': const Uuid().v4(),
        'entity_type': 'customer',
        'entity_id': customer.id,
        'payload': jsonEncode({...map, 'op': 'upsert'}),
        'priority': 0,
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    final rows = await db.query('customers', where: 'id = ?', whereArgs: ['cust-1']);
    expect(rows, hasLength(1));
    expect(rows.first['name'], 'Demo Cari');

    final queue = await db.query('sync_queue');
    expect(queue, hasLength(1));
    expect(queue.first['entity_type'], 'customer');
    final payload =
        jsonDecode(queue.first['payload'] as String) as Map<String, dynamic>;
    expect(payload['op'], 'upsert');
    expect(payload['code'], 'C-100');
  });

  test('deactivate is_active=0 + queue', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
    await db.insert('customers', {
      'id': 'cust-2',
      'name': 'Pasif olacak',
      'is_active': 1,
      'created_at': '2026-07-27T00:00:00.000',
      'updated_at': '2026-07-27T00:00:00.000',
    });

    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'customers',
        {'is_active': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: ['cust-2'],
      );
      await txn.insert('sync_queue', {
        'id': const Uuid().v4(),
        'entity_type': 'customer',
        'entity_id': 'cust-2',
        'payload': jsonEncode({'id': 'cust-2', 'op': 'deactivate'}),
        'priority': 0,
        'retry_count': 0,
        'created_at': now,
      });
    });

    final row = (await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: ['cust-2'],
    )).first;
    expect(row['is_active'], 0);
  });
}
