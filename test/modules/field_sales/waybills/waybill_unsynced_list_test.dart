// Dosya Adı: waybill_unsynced_list_test.dart
// Açıklama: Bekleyen / transfer edilmeyen irsaliye listesi is_synced=0
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/mbt_sales_purchase_queue_body.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/waybill_type.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_repository.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_unsynced_store.dart';
import 'package:exfin_ops/modules/field_sales/waybills/widgets/waybill_unsynced_dens_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WaybillRepository.listUnsynced is_synced=0', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createWaybillsTable);
          await database.execute(SqlQuerys.createCustomersTable);
        },
      );
      await db.insert('customers', {
        'id': 'cust-a',
        'name': 'Sevk Market',
        'code': 'ARP-A',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('yalnız is_synced=0 döner; synced hariç', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('waybills', {
        'id': 'wb-unsynced',
        'customer_id': 'cust-a',
        'waybill_date': now,
        'waybill_type': WaybillType.wholesale.localKey,
        'total_amount': 100,
        'status': 'Completed',
        'is_synced': 0,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('waybills', {
        'id': 'wb-synced',
        'customer_id': 'cust-a',
        'waybill_date': now,
        'waybill_type': WaybillType.purchase.localKey,
        'total_amount': 50,
        'status': 'Completed',
        'is_synced': 1,
        'created_at': now,
        'updated_at': now,
      });

      const repo = WaybillRepository();
      final rows = await repo.listUnsynced(db);

      expect(rows.length, 1);
      expect(rows.first.id, 'wb-unsynced');
      expect(rows.first.isSynced, 0);
      expect(rows.first.customerId, 'cust-a');
      expect(rows.first.customerName, 'Sevk Market');
      expect(rows.first.customerCode, 'ARP-A');
      expect(rows.first.waybillType, WaybillType.wholesale.localKey);
    });

    test('boş tablo → boş liste', () async {
      const repo = WaybillRepository();
      final rows = await repo.listUnsynced(db);
      expect(rows, isEmpty);
    });

    test('WaybillUnsyncedStore.loadUnsynced inject DB', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('waybills', {
        'id': 'wb-store',
        'customer_id': 'cust-a',
        'waybill_date': now,
        'waybill_type': WaybillType.purchase.localKey,
        'total_amount': 12.5,
        'status': 'Completed',
        'notes': 'Alım sevk',
        'is_synced': 0,
        'created_at': now,
        'updated_at': now,
      });

      final store = WaybillUnsyncedStore(openDb: () async => db);
      final rows = await store.loadUnsynced();
      expect(rows.length, 1);
      expect(rows.first.id, 'wb-store');
      expect(rows.first.isSynced, 0);
    });
  });

  group('WaybillUnsyncedDensTile', () {
    test('purchase → ALIŞ side + cari kod·ad', () async {
      final l10n = AppLocalization(const Locale('tr', 'TR'));
      final ok = await l10n.load();
      expect(ok, isTrue, reason: 'TR çeviri yüklenmeli');

      final row = WaybillUnsyncedRow(
        id: 'wb-1',
        customerId: 'cust-a',
        customerCode: 'ARP-A',
        customerName: 'Sevk Market',
        waybillDate: DateTime(2026, 7, 26),
        waybillType: WaybillType.purchase.localKey,
        totalAmount: 12.5,
        notes: 'Alım',
        isSynced: 0,
      );
      final queue = WaybillUnsyncedDensTile.toQueueRow(row, l10n);
      expect(queue.side, MbtQueueDocSide.purchase);
      expect(queue.title, 'Alım');
      expect(
        queue.subtitle,
        isNot(equals('field_sales.waybill_pending_row_subtitle')),
      );
      expect(queue.subtitle, contains('ARP-A'));
      expect(queue.subtitle, contains('Sevk Market'));
    });
  });
}
