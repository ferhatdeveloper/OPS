// Dosya Adı: partial_delivery_provider_test.dart
// Açıklama: Kısmi teslimat provider/SQLite iskelet kaydet testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/delivery/model/partial_delivery_model.dart';
import 'package:exfin_ops/modules/field_sales/delivery/viewmodel/partial_delivery_provider.dart';
import 'package:exfin_ops/modules/field_sales/delivery/viewmodel/partial_delivery_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PartialDeliveryRecord map', () {
    test('toMap / fromMap satırları taşır', () {
      final record = PartialDeliveryRecord(
        id: 'pd-1',
        workplace: 'İşyeri A',
        factory: 'Fabrika 1',
        warehouse: 'Araç Depo',
        deliveryDate: DateTime.utc(2026, 7, 26),
        lines: const [
          PartialDeliveryLine(
            code: 'KSM-1',
            name: 'Kalem',
            qty: '1/2',
          ),
        ],
        status: 'Pending',
        isSynced: false,
        createdAt: DateTime.utc(2026, 7, 26, 10),
      );

      final map = record.toMap();
      expect(map['id'], 'pd-1');
      expect(map['workplace'], 'İşyeri A');
      expect(map['warehouse'], 'Araç Depo');
      expect(map['is_synced'], 0);
      expect(map['lines_json'], isNotEmpty);

      final loaded = PartialDeliveryRecord.fromMap(map);
      expect(loaded.id, 'pd-1');
      expect(loaded.lines, hasLength(1));
      expect(loaded.lines.first.code, 'KSM-1');
      expect(loaded.lines.first.qty, '1/2');
      expect(loaded.status, 'Pending');
    });
  });

  group('PartialDeliveryRepository SQLite iskelet', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute(SqlQuerys.createPartialDeliveriesTable);
          await database.execute(SqlQuerys.createSyncQueueTable);
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('insert kaydı partial_deliveries tablosuna yazar', () async {
      final repo = const PartialDeliveryRepository();
      final record = PartialDeliveryRecord(
        id: 'pd-save-1',
        workplace: 'WP',
        factory: 'FAC',
        warehouse: 'WH',
        deliveryDate: DateTime.utc(2026, 7, 26),
        lines: const [
          PartialDeliveryLine(code: 'A', name: 'Ürün', qty: '2/5'),
        ],
        createdAt: DateTime.utc(2026, 7, 26, 12),
      );

      await repo.insert(db, record);

      final rows = await db.query(
        'partial_deliveries',
        where: 'id = ?',
        whereArgs: ['pd-save-1'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['warehouse'], 'WH');
      expect(rows.first['is_synced'], 0);

      final loaded = PartialDeliveryRecord.fromMap(rows.first);
      expect(loaded.lines.first.qty, '2/5');
    });

    test('enqueueSyncQueue sync_queue satırı ekler', () async {
      final repo = const PartialDeliveryRepository();
      await repo.enqueueSyncQueue(
        db,
        entityId: 'pd-q-1',
        payload: {'id': 'pd-q-1', 'warehouse': 'WH'},
      );

      final jobs = await db.query(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['partial_delivery', 'pd-q-1'],
      );
      expect(jobs, hasLength(1));
      expect(jobs.first['payload'], contains('pd-q-1'));
    });
  });

  group('PartialDeliveryNotifier guard', () {
    test('boş satır listesi requires_lines döner', () async {
      final result = PartialDeliveryNotifier.validateLines(const []);
      expect(result, 'field_sales.partial_delivery.requires_lines');
    });

    test('dolu satır listesi null döner', () async {
      final result = PartialDeliveryNotifier.validateLines(const [
        PartialDeliveryLine(code: 'X', name: 'Y', qty: '1'),
      ]);
      expect(result, isNull);
    });

    test('save SQLite + sync_queue yazar', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {},
      );
      addTearDown(db.close);

      final notifier = PartialDeliveryNotifier(dbOverride: () async => db);
      final ok = await notifier.save(
        workplace: 'WP',
        factory: 'FAC',
        warehouse: 'WH',
        deliveryDate: DateTime.utc(2026, 7, 26),
        lines: const [
          PartialDeliveryLine(code: 'A', name: 'Ürün', qty: '1/2'),
        ],
      );

      expect(ok, isTrue);
      expect(notifier.state.lastSavedId, isNotNull);

      final rows = await db.query('partial_deliveries');
      expect(rows, hasLength(1));
      final jobs = await db.query(
        'sync_queue',
        where: 'entity_type = ?',
        whereArgs: ['partial_delivery'],
      );
      expect(jobs, hasLength(1));
      expect(jobs.first['entity_id'], notifier.state.lastSavedId);
    });
  });
}
