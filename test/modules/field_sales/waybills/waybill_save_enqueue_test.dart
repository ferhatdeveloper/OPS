// Dosya Adı: waybill_save_enqueue_test.dart
// Açıklama: İrsaliye Kaydet → SQLite + sync_queue enqueue; dispatch TYPE koruma
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/waybill_model.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/waybill_type.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WaybillRepository.validate', () {
    test('boş cari → false + requires_customer', () {
      final result = WaybillRepository.validate(
        customerId: '',
        lines: [
          WaybillLineInput(
            productId: 'p1',
            productCode: 'P1',
            quantity: 1,
          ),
        ],
      );
      expect(result.isValid, isFalse);
      expect(result.errorKey, 'field_sales.waybill_save_requires_customer');
    });

    test('geçerli cari ama kalem yok → min_products', () {
      final result = WaybillRepository.validate(
        customerId: 'cari-1',
        lines: const [],
      );
      expect(result.isValid, isFalse);
      expect(result.errorKey, 'field_sales.waybill_min_products');
    });

    test('cari + kalem → geçerli', () {
      final result = WaybillRepository.validate(
        customerId: 'cari-1',
        lines: [
          WaybillLineInput(
            productId: 'p1',
            productCode: 'P1',
            quantity: 2,
          ),
        ],
      );
      expect(result.isValid, isTrue);
      expect(result.errorKey, isNull);
    });
  });

  group('WaybillRepository.saveAndEnqueue SQLite + dispatch TYPE', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createWaybillsTable);
          await database.execute(SqlQuerys.createWaybillItemsTable);
          await database.execute(SqlQuerys.createSyncQueueTable);
          await database.execute(SqlQuerys.createCustomersTable);
        },
      );
      await db.insert('customers', {
        'id': 'cust-w',
        'name': 'Sevk Cari',
        'code': 'ARP-W',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('toptan: waybills + items + sync_queue dispatch TYPE wholesale',
        () async {
      const repo = WaybillRepository();
      final saved = await repo.saveAndEnqueue(
        db,
        customerId: 'cust-w',
        waybillType: WaybillType.wholesale,
        lines: [
          WaybillLineInput(
            productId: 'prd-1',
            productCode: 'SKU-1',
            quantity: 3,
            unitPrice: 10,
          ),
        ],
      );

      expect(saved.ok, isTrue);
      expect(saved.waybillId, isNotEmpty);

      final headers = await db.query(
        'waybills',
        where: 'id = ?',
        whereArgs: [saved.waybillId],
      );
      expect(headers, hasLength(1));
      expect(headers.first['customer_id'], 'cust-w');
      expect(headers.first['waybill_type'], 'waybill_wholesale');
      expect(headers.first['is_synced'], 0);

      final items = await db.query(
        'waybill_items',
        where: 'waybill_id = ?',
        whereArgs: [saved.waybillId],
      );
      expect(items, hasLength(1));
      expect(items.first['product_id'], 'prd-1');
      expect((items.first['quantity'] as num).toDouble(), 3);

      final jobs = await db.query(
        'sync_queue',
        where: 'entity_id = ?',
        whereArgs: [saved.waybillId],
      );
      expect(jobs, hasLength(1));
      expect(jobs.first['entity_type'], 'dispatch');
      final payload = jsonDecode(jobs.first['payload'] as String)
          as Map<String, dynamic>;
      expect(payload['entity'], 'dispatch');
      expect(payload['type'], 'wholesale');
      expect(payload['dispatch_type'], 'waybill_wholesale');
      expect(payload['customer_code'], 'ARP-W');
      expect(payload.containsKey('invoice_type'), isFalse);
      expect(payload['type'], isNot(8));
      expect(payload['type'], isNot('8'));
      final lines = payload['items'] as List;
      expect(lines, hasLength(1));
      expect(lines.first['product_code'], 'SKU-1');
    });

    test('alış: purchase kanalı; toptan ile aynı TYPE flatten yok', () async {
      const repo = WaybillRepository();
      final saved = await repo.saveAndEnqueue(
        db,
        customerId: 'cust-w',
        waybillType: WaybillType.purchase,
        lines: [
          WaybillLineInput(
            productId: 'prd-2',
            productCode: 'SKU-2',
            quantity: 1,
          ),
        ],
      );

      expect(saved.ok, isTrue);
      final headers = await db.query(
        'waybills',
        where: 'id = ?',
        whereArgs: [saved.waybillId],
      );
      expect(headers.first['waybill_type'], 'waybill_purchase');

      final jobs = await db.query(
        'sync_queue',
        where: 'entity_id = ?',
        whereArgs: [saved.waybillId],
      );
      final payload = jsonDecode(jobs.first['payload'] as String)
          as Map<String, dynamic>;
      expect(payload['type'], 'purchase');
      expect(payload['dispatch_type'], 'waybill_purchase');
      expect(payload.containsKey('invoice_type'), isFalse);
      expect(payload['type'], isNot('wholesale'));
    });

    test('geçersiz cari kaydetmez ve kuyruk yazmaz', () async {
      const repo = WaybillRepository();
      final saved = await repo.saveAndEnqueue(
        db,
        customerId: '  ',
        waybillType: WaybillType.wholesale,
        lines: [
          WaybillLineInput(
            productId: 'prd-1',
            productCode: 'SKU-1',
            quantity: 1,
          ),
        ],
      );
      expect(saved.ok, isFalse);
      expect(saved.errorKey, 'field_sales.waybill_save_requires_customer');
      expect(await db.query('waybills'), isEmpty);
      expect(await db.query('sync_queue'), isEmpty);
    });
  });

  group('WaybillRepository.list dens SQLite', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createWaybillsTable);
          await database.execute(SqlQuerys.createWaybillItemsTable);
          await database.execute(SqlQuerys.createSyncQueueTable);
          await database.execute(SqlQuerys.createCustomersTable);
        },
      );
      await db.insert('customers', {
        'id': 'cust-a',
        'name': 'Cari A',
        'code': 'ARP-A',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('customers', {
        'id': 'cust-b',
        'name': 'Cari B',
        'code': 'ARP-B',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('kaydet sonrası list tüm satırları döner (tarih azalan)', () async {
      const repo = WaybillRepository();
      final older = await repo.saveAndEnqueue(
        db,
        customerId: 'cust-a',
        waybillType: WaybillType.wholesale,
        lines: [
          WaybillLineInput(
            productId: 'p1',
            productCode: 'P1',
            quantity: 1,
            unitPrice: 10,
          ),
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final newer = await repo.saveAndEnqueue(
        db,
        customerId: 'cust-b',
        waybillType: WaybillType.purchase,
        lines: [
          WaybillLineInput(
            productId: 'p2',
            productCode: 'P2',
            quantity: 2,
            unitPrice: 5,
          ),
        ],
      );

      final all = await repo.list(db);
      expect(all, hasLength(2));
      expect(all.first.id, newer.waybillId);
      expect(all.last.id, older.waybillId);
    });

    test('customerId filtresi yalnızca ilgili cariyi döner', () async {
      const repo = WaybillRepository();
      await repo.saveAndEnqueue(
        db,
        customerId: 'cust-a',
        waybillType: WaybillType.wholesale,
        lines: [
          WaybillLineInput(
            productId: 'p1',
            productCode: 'P1',
            quantity: 1,
          ),
        ],
      );
      await repo.saveAndEnqueue(
        db,
        customerId: 'cust-b',
        waybillType: WaybillType.wholesale,
        lines: [
          WaybillLineInput(
            productId: 'p2',
            productCode: 'P2',
            quantity: 1,
          ),
        ],
      );

      final filtered = await repo.list(db, customerId: 'cust-a');
      expect(filtered, hasLength(1));
      expect(filtered.first.customerId, 'cust-a');
    });
  });

  group('WaybillModel map', () {
    test('toMap / fromMap waybill_type taşır', () {
      final model = WaybillModel(
        id: 'wb-1',
        customerId: 'c1',
        waybillDate: DateTime.utc(2026, 7, 26),
        waybillType: WaybillType.wholesale.localKey,
        status: 'Completed',
        isSynced: 0,
      );
      final map = model.toMap();
      expect(map['waybill_type'], 'waybill_wholesale');
      expect(map['is_synced'], 0);
      final loaded = WaybillModel.fromMap(map);
      expect(loaded.waybillType, 'waybill_wholesale');
      expect(loaded.customerId, 'c1');
    });
  });
}
