// Dosya Adı: logo_job_store_test.dart
// Açıklama: Logo job_queue dens — sync_queue store birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/sync/model/logo_job_record.dart';
import 'package:exfin_ops/modules/field_sales/sync/viewmodel/logo_job_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('loadAll gerçek sync_queue satırlarını döner', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = LogoJobStore(openDb: () async => db);
    await store.ensureReady();

    await db.insert(LogoJobStore.tableName, {
      'id': 'job-1',
      'entity_type': 'order',
      'entity_id': 'O-100',
      'priority': 1,
      'retry_count': 0,
      'created_at': '2026-07-26T10:00:00.000',
    });
    await db.insert(LogoJobStore.tableName, {
      'id': 'job-2',
      'entity_type': 'invoice',
      'entity_id': 'I-200',
      'priority': 0,
      'retry_count': 2,
      'last_error': 'Logo 500',
      'created_at': '2026-07-26T09:00:00.000',
    });

    final rows = await store.loadAll();
    expect(rows.length, 2);
    // priority DESC → job-1 önce
    expect(rows.first.id, 'job-1');
    expect(rows.first.entityType, 'order');
    expect(rows.first.entityId, 'O-100');
    expect(rows.first.titleLine, 'order · O-100');
    expect(rows.last.id, 'job-2');
    expect(rows.last.retryCount, 2);
    expect(rows.last.lastError, 'Logo 500');
  });

  test('loadAll boş tabloda boş liste (seed yok)', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final store = LogoJobStore(openDb: () async => db);
    final rows = await store.loadAll();
    expect(rows, isEmpty);
  });

  test('fromMap / toMap round-trip dens alanları korur', () {
    const row = LogoJobRecord(
      id: 'j1',
      entityType: 'collection',
      entityId: 'C-9',
      retryCount: 1,
      lastError: 'timeout',
      createdAt: '2026-07-26',
    );
    final again = LogoJobRecord.fromMap(row.toMap());
    expect(again.id, row.id);
    expect(again.entityType, row.entityType);
    expect(again.entityId, row.entityId);
    expect(again.retryCount, 1);
    expect(again.lastError, 'timeout');
    expect(again.titleLine, 'collection · C-9');
  });
}
