// Dosya Adı: waybill_pending_store_test.dart
// Açıklama: Bekleyen irsaliye dens — SQLite approval_status=0 sorgu/seed
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_pending_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WaybillPendingStore', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createWaybillsTable);
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('boş tablo → seed dens pending (approval_status=0)', () async {
      final store = WaybillPendingStore(openDb: () async => db);
      final rows = await store.loadPending();

      expect(rows, isNotEmpty);
      expect(rows.every((r) => (r['approval_status'] as int?) == 0), isTrue);
      expect(
        rows.any((r) => r['waybill_type'] == 'waybill_wholesale'),
        isTrue,
      );
      expect(
        rows.any((r) => r['waybill_type'] == 'waybill_purchase'),
        isTrue,
      );
    });

    test('yalnız onaylı kayıt → pending seed eklenir', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('waybills', {
        'id': 'wb-approved',
        'customer_id': 'C-OK',
        'waybill_date': now,
        'waybill_type': 'waybill_wholesale',
        'total_amount': 10,
        'status': 'Completed',
        'approval_status': 1,
        'is_synced': 0,
        'created_at': now,
        'updated_at': now,
      });

      final store = WaybillPendingStore(openDb: () async => db);
      final rows = await store.loadPending();

      expect(rows, isNotEmpty);
      expect(rows.every((r) => r['id'] != 'wb-approved'), isTrue);
      expect(rows.every((r) => (r['approval_status'] as int?) == 0), isTrue);
    });

    test('mevcut pending → yeniden seed yok', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('waybills', {
        'id': 'wb-pending-only',
        'customer_id': 'C-P',
        'waybill_date': now,
        'waybill_type': 'waybill_wholesale',
        'total_amount': 99,
        'status': 'Pending',
        'approval_status': 0,
        'is_synced': 0,
        'created_at': now,
        'updated_at': now,
      });

      final store = WaybillPendingStore(openDb: () async => db);
      final rows = await store.loadPending();

      expect(rows.length, 1);
      expect(rows.first['id'], 'wb-pending-only');
    });
  });
}
