// Dosya Adı: stock_count_service_test.dart
// Açıklama: Sayım fişi yerel kayıt + sync_queue birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/stock_count_record.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/stock_count_service.dart';

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
        await db.execute(SqlQuerys.createStockCountsTable);
        await db.execute(SqlQuerys.createSyncQueueTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('StockCountRecord', () {
    test('toMap / fromMap round-trip', () {
      final record = StockCountRecord(
        id: 'sc-1',
        workplace: 'Merkez İşyeri',
        factory: 'Fabrika 01',
        warehouse: 'Araç Depo',
        slipDate: DateTime(2026, 7, 26),
        lines: const [
          StockCountLine(code: 'SKU-1', name: 'Kalem', qty: '3'),
        ],
        onay: 1,
        isSynced: false,
        createdAt: DateTime(2026, 7, 26, 10),
        updatedAt: DateTime(2026, 7, 26, 10),
      );

      final restored = StockCountRecord.fromMap(record.toMap());
      expect(restored.id, 'sc-1');
      expect(restored.workplace, 'Merkez İşyeri');
      expect(restored.factory, 'Fabrika 01');
      expect(restored.warehouse, 'Araç Depo');
      expect(restored.slipDate.day, 26);
      expect(restored.lines, hasLength(1));
      expect(restored.lines.first.code, 'SKU-1');
      expect(restored.lines.first.qty, '3');
      expect(restored.onay, 1);
      expect(restored.isSynced, isFalse);
    });
  });

  group('StockCountService.saveLocalAndQueue', () {
    test('yerel stock_counts + sync_queue satırı yazar', () async {
      final record = StockCountRecord(
        id: 'sc-save-1',
        workplace: 'Merkez İşyeri',
        factory: 'Fabrika 01',
        warehouse: 'Merkez Depo',
        slipDate: DateTime(2026, 7, 26),
        lines: const [
          StockCountLine(code: 'SKU-9', name: 'Örnek', qty: '2'),
        ],
        onay: 1,
        isSynced: false,
        createdAt: DateTime(2026, 7, 26, 12),
        updatedAt: DateTime(2026, 7, 26, 12),
      );

      final id = await StockCountService.saveLocalAndQueue(
        db: db,
        record: record,
      );

      expect(id, 'sc-save-1');

      final local = await db.query(
        'stock_counts',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(local, hasLength(1));
      expect(local.first['warehouse'], 'Merkez Depo');
      expect(local.first['is_synced'], 0);
      expect(local.first['ONAY'], 1);

      final queue = await db.query(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['stock_count', id],
      );
      expect(queue, hasLength(1));
      final payload = jsonDecode(queue.first['payload'] as String) as Map;
      expect(payload['id'], id);
      expect(payload['entity'], 'stock_count');
      expect(payload['warehouse'], 'Merkez Depo');
      expect(payload['lines'], isA<List>());
      expect((payload['lines'] as List).first['product_code'], 'SKU-9');
    });
  });
}
