// Dosya Adı: collections_logo_sync_mapper_test.dart
// Açıklama: Banka/çek/senet Logo sync_queue mapper stub enqueue testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_row.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/check_list_status.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/finance_movement_type.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/promissory_list_row.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/promissory_list_status.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/bank_card_store.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/collections_logo_sync_mapper.dart';

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
      onCreate: (database, version) async {
        await database.execute(SqlQuerys.createSyncQueueTable);
        await database.execute(SqlQuerys.createBankCardsTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('banka kartı payload + enqueue', () async {
    final record = BankCardRecord(
      id: 'bc1',
      code: 'BNK01',
      name: 'Ziraat',
      nameKey: '',
      balanceTl: 100,
    );
    final jobId = await CollectionsLogoSyncMapper.enqueueBankCard(
      db: db,
      record: record,
      operation: 'upsert',
    );
    expect(jobId, isNotEmpty);
    final jobs = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [
        CollectionsLogoSyncMapper.bankCardEntityType,
        'bc1',
      ],
    );
    expect(jobs, hasLength(1));
    final payload =
        jsonDecode(jobs.first['payload'] as String) as Map<String, dynamic>;
    expect(payload['CODE'], 'BNK01');
    expect(payload['stub'], isTrue);
    expect(payload['operation'], 'upsert');
  });

  test('çek CSCARD DOC=1 enqueue', () async {
    final row = CheckListRow(
      id: 'chk1',
      customerId: 'C001',
      amount: 250,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 7, 28),
      checkNumber: 'CK-99',
      bankName: 'İş Bankası',
      status: CheckListStatus.collection,
    );
    await CollectionsLogoSyncMapper.enqueueCheck(
      db: db,
      row: row,
      operation: 'upsert',
    );
    final jobs = await db.query(
      'sync_queue',
      where: 'entity_type = ?',
      whereArgs: [CollectionsLogoSyncMapper.checkEntityType],
    );
    expect(jobs, hasLength(1));
    final payload =
        jsonDecode(jobs.first['payload'] as String) as Map<String, dynamic>;
    expect(payload['DOC'], 1);
    expect(payload['SERINO'], 'CK-99');
    expect(payload['stub'], isTrue);
  });

  test('senet CSCARD DOC=2 enqueue', () async {
    final row = PromissoryListRow(
      id: 'pn1',
      customerId: 'C002',
      amount: 500,
      noteNumber: 'SN-01',
      status: PromissoryListStatus.collection,
    );
    await CollectionsLogoSyncMapper.enqueuePromissory(
      db: db,
      row: row,
      operation: 'delete',
    );
    final jobs = await db.query(
      'sync_queue',
      where: 'entity_type = ?',
      whereArgs: [CollectionsLogoSyncMapper.promissoryEntityType],
    );
    expect(jobs, hasLength(1));
    final payload =
        jsonDecode(jobs.first['payload'] as String) as Map<String, dynamic>;
    expect(payload['DOC'], 2);
    expect(payload['operation'], 'delete');
  });

  test('BankCardStore create sync_queue yazar', () async {
    final store = BankCardStore(openDb: () async => db);
    await store.ensureReady();
    final created = await store.create(code: 'X01', name: 'Test Bank');
    final jobs = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [
        CollectionsLogoSyncMapper.bankCardEntityType,
        created.id,
      ],
    );
    expect(jobs, isNotEmpty);
  });
}
