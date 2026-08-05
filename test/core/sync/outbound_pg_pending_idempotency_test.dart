// Dosya Adı: outbound_pg_pending_idempotency_test.dart
// Açıklama: Ortak invoices.id + PG pending + Logo idempotency birim testleri
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/services/logo_api_service.dart';
import 'package:exfin_ops/core/sync/outbound_idempotency.dart';
import 'package:exfin_ops/core/sync/outbound_mirror_status.dart';
import 'package:exfin_ops/core/sync/outbound_sync_phases.dart';
import 'package:exfin_ops/core/sync/postgrest_document_mirror.dart';
import 'package:exfin_ops/service/job_queue_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mirror çağrılarını kaydeden test double.
class _RecordingMirror extends PostgrestDocumentMirror {
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<bool> mirror({
    required String entityType,
    required String entityId,
    String? logoRef,
    String? idempotencyCode,
    Map<String, dynamic>? payload,
    bool logoSynced = true,
    String? syncStatus,
  }) async {
    calls.add({
      'entityType': entityType,
      'entityId': entityId,
      'logoRef': logoRef,
      'idempotencyCode': idempotencyCode,
      'logoSynced': logoSynced,
      'syncStatus': syncStatus,
    });
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const invoiceId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  group('PostgrestDocumentMirror.buildUpsertBody', () {
    test('aynı invoices.id → aynı id/ops_doc_id/client_doc_id (çift yok)', () {
      final a = PostgrestDocumentMirror.buildUpsertBody(
        entityId: invoiceId,
        firmNr: '001',
        logoSynced: false,
        idempotencyCode: OutboundIdempotency.ficheNumber('invoice', invoiceId),
      );
      final b = PostgrestDocumentMirror.buildUpsertBody(
        entityId: '  $invoiceId  ',
        firmNr: '001',
        logoSynced: false,
        idempotencyCode: OutboundIdempotency.ficheNumber('invoice', invoiceId),
      );
      expect(a['id'], invoiceId);
      expect(a['ops_doc_id'], invoiceId);
      expect(a['client_doc_id'], invoiceId);
      expect(a['id'], b['id']);
      expect(a['idempotency_code'], b['idempotency_code']);
    });

    test('Logo fail yedeği → logo_pending + logo_synced=0, logo_ref yok', () {
      final body = PostgrestDocumentMirror.buildUpsertBody(
        entityId: invoiceId,
        firmNr: '001',
        logoRef: null,
        logoSynced: false,
        syncStatus: PostgrestDocumentMirror.statusLogoPending,
        idempotencyCode: 'OIABCDEF123456',
      );
      expect(body['sync_status'], OutboundMirrorStatus.logoPending);
      expect(body['logo_synced'], 0);
      expect(body['is_synced'], 0);
      expect(body.containsKey('logo_ref'), isFalse);
    });

    test('Logo success → confirmed + logo_ref + logo_synced=1', () {
      final body = PostgrestDocumentMirror.buildUpsertBody(
        entityId: invoiceId,
        firmNr: '001',
        logoRef: 'LOGO-REF-99',
        logoSynced: true,
        syncStatus: PostgrestDocumentMirror.statusConfirmed,
        idempotencyCode: 'OIABCDEF123456',
      );
      expect(body['sync_status'], OutboundMirrorStatus.confirmed);
      expect(body['logo_synced'], 1);
      expect(body['logo_ref'], 'LOGO-REF-99');
      expect(body['id'], invoiceId);
    });
  });

  group('JobQueueService — invoices.id enqueue + PG pending', () {
    late Database db;
    late JobQueueService queue;
    late _RecordingMirror mirror;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE sync_queue (
              id TEXT PRIMARY KEY,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              payload TEXT,
              priority INTEGER DEFAULT 0,
              retry_count INTEGER DEFAULT 0,
              last_error TEXT,
              scheduled_at TEXT,
              sync_phase TEXT,
              created_at TEXT
            )
          ''');
          await database.execute('''
            CREATE TABLE invoices (
              id TEXT PRIMARY KEY,
              customer_id TEXT,
              invoice_date TEXT,
              total_amount REAL,
              status TEXT,
              is_synced INTEGER DEFAULT 0,
              approval_status INTEGER DEFAULT 0,
              logo_ref TEXT,
              pg_synced INTEGER DEFAULT 0
            )
          ''');
        },
      );
      await db.insert('invoices', {
        'id': invoiceId,
        'customer_id': 'C1',
        'invoice_date': '2026-08-05',
        'total_amount': 100,
        'status': 'Completed',
        'is_synced': 0,
        'approval_status': 1,
      });

      queue = JobQueueService();
      queue.resetTestHooks();
      mirror = _RecordingMirror();
      queue.openDbForTest = () async => db;
      queue.postgrestMirrorForTest = mirror;
      queue.autoProcessQueue = false;
    });

    tearDown(() async {
      queue.resetTestHooks();
      await db.close();
    });

    test('aynı invoices.id ikinci enqueue → tek queue satırı', () async {
      await queue.enqueue(
        entityType: 'invoice',
        entityId: invoiceId,
        payload: {'ops_doc_id': invoiceId, 'NUMBER': 'OIAA'},
      );
      await queue.enqueue(
        entityType: 'invoice',
        entityId: invoiceId,
        payload: {'ops_doc_id': invoiceId, 'NUMBER': 'OIAA', 'retry': 1},
      );

      final jobs = await db.query('sync_queue');
      expect(jobs, hasLength(1));
      expect(jobs.first['entity_id'], invoiceId);
      expect(jobs.first['sync_phase'], OutboundSyncPhase.pgPending);
    });

    test('Logo fail → PG pending yazılır; phase=logo kalır', () async {
      queue.logoSyncForTest = (type, id, payload) async =>
          LogoApiResult.fail('Logo down (mock)');

      await queue.enqueue(
        entityType: 'invoice',
        entityId: invoiceId,
        payload: {
          'ops_doc_id': invoiceId,
          'NUMBER': OutboundIdempotency.ficheNumber('invoice', invoiceId),
          'ARP_CODE': 'C1',
        },
      );
      await queue.processQueue();

      expect(mirror.calls, isNotEmpty);
      final pending = mirror.calls.first;
      expect(pending['entityId'], invoiceId);
      expect(pending['logoSynced'], isFalse);
      expect(
        pending['syncStatus'],
        PostgrestDocumentMirror.statusLogoPending,
      );
      expect(pending['logoRef'], isNull);

      final jobs = await db.query('sync_queue');
      expect(jobs, hasLength(1));
      expect(jobs.first['sync_phase'], OutboundSyncPhase.logo);
      expect(jobs.first['retry_count'], greaterThan(0));

      final inv = await db.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      expect(inv.first['logo_ref'], isNull);
      expect(inv.first['is_synced'], 0);
    });

    test('Logo success → logo_ref + confirmed mirror; kuyruk silinir', () async {
      queue.logoSyncForTest = (type, id, payload) async => LogoApiResult.ok({
            'logo_ref': 'LR-555',
            'tiger': true,
            'data': {'LOGICALREF': 'LR-555'},
          });

      await queue.enqueue(
        entityType: 'invoice',
        entityId: invoiceId,
        payload: {
          'ops_doc_id': invoiceId,
          'NUMBER': OutboundIdempotency.ficheNumber('invoice', invoiceId),
          'ARP_CODE': 'C1',
        },
      );
      await queue.processQueue();

      expect(mirror.calls.length, greaterThanOrEqualTo(2));
      final pending = mirror.calls.first;
      final confirmed = mirror.calls.last;
      expect(pending['logoSynced'], isFalse);
      expect(
        pending['syncStatus'],
        PostgrestDocumentMirror.statusLogoPending,
      );
      expect(confirmed['logoSynced'], isTrue);
      expect(
        confirmed['syncStatus'],
        PostgrestDocumentMirror.statusConfirmed,
      );
      expect(confirmed['logoRef'], 'LR-555');
      expect(confirmed['entityId'], invoiceId);

      final jobs = await db.query('sync_queue');
      expect(jobs, isEmpty);

      final inv = await db.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      expect(inv.first['logo_ref'], 'LR-555');
      expect(inv.first['is_synced'], 1);
      expect(inv.first['pg_synced'], 1);
    });
  });
}
