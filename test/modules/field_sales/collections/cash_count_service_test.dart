// Dosya Adı: cash_count_service_test.dart
// Açıklama: Kasa sayımı yerel kayıt + sync_queue birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/cash_count_record.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/cash_count_service.dart';

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
        await db.execute(SqlQuerys.createCashCountsTable);
        await db.execute(SqlQuerys.createSyncQueueTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CashCountRecord', () {
    test('toMap / fromMap round-trip', () {
      final record = CashCountRecord(
        id: 'cc-1',
        cashCode: '100 01 01',
        countDate: DateTime(2026, 7, 26),
        expectedAmount: 1500.0,
        countedAmount: 1480.5,
        notes: 'Gün sonu',
        lines: const [
          CashCountLine(denomination: '200', qty: '5'),
          CashCountLine(denomination: '100', qty: '4'),
        ],
        onay: 1,
        isSynced: false,
        createdAt: DateTime(2026, 7, 26, 10),
        updatedAt: DateTime(2026, 7, 26, 10),
      );

      final restored = CashCountRecord.fromMap(record.toMap());
      expect(restored.id, 'cc-1');
      expect(restored.cashCode, '100 01 01');
      expect(restored.countDate.day, 26);
      expect(restored.expectedAmount, 1500.0);
      expect(restored.countedAmount, 1480.5);
      expect(restored.difference, closeTo(-19.5, 0.001));
      expect(restored.notes, 'Gün sonu');
      expect(restored.lines, hasLength(2));
      expect(restored.lines.first.denomination, '200');
      expect(restored.lines.first.qty, '5');
      expect(restored.onay, 1);
      expect(restored.isSynced, isFalse);
    });
  });

  group('CashCountService.saveLocalAndQueue', () {
    test('yerel cash_counts + sync_queue satırı yazar', () async {
      final record = CashCountRecord(
        id: 'cc-save-1',
        cashCode: '100 01 01',
        countDate: DateTime(2026, 7, 26),
        expectedAmount: 1000,
        countedAmount: 1000,
        notes: null,
        lines: const [
          CashCountLine(denomination: '100', qty: '10'),
        ],
        onay: 1,
        isSynced: false,
        createdAt: DateTime(2026, 7, 26, 12),
        updatedAt: DateTime(2026, 7, 26, 12),
      );

      final id = await CashCountService.saveLocalAndQueue(
        db: db,
        record: record,
      );

      expect(id, 'cc-save-1');

      final local = await db.query(
        'cash_counts',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(local, hasLength(1));
      expect(local.first['cash_code'], '100 01 01');
      expect(local.first['is_synced'], 0);
      expect(local.first['ONAY'], 1);

      final queue = await db.query(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['cash_count', id],
      );
      expect(queue, hasLength(1));
      final payload = jsonDecode(queue.first['payload'] as String) as Map;
      expect(payload['id'], id);
      expect(payload['entity'], 'cash_count');
      expect(payload['cash_code'], '100 01 01');
      expect(payload['counted_amount'], 1000);
      expect(payload['lines'], isA<List>());
    });
  });
}
