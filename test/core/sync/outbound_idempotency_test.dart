// Dosya Adı: outbound_idempotency_test.dart
// Açıklama: Kararlı fiş NUMBER / PG pending mirror / faz birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/logo/logo_tiger_push_adapter.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/core/sync/outbound_idempotency.dart';
import 'package:exfin_ops/core/sync/outbound_mirror_status.dart';
import 'package:exfin_ops/core/sync/outbound_sync_phases.dart';
import 'package:exfin_ops/core/sync/postgrest_document_mirror.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundIdempotency', () {
    test('aynı entityId → aynı NUMBER (retry güvenli)', () {
      const id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      final a = OutboundIdempotency.ficheNumber('invoice', id);
      final b = OutboundIdempotency.ficheNumber('invoice', id);
      expect(a, b);
      expect(a.startsWith('OI'), isTrue);
      expect(a.length, 14);
    });

    test('farklı tip → farklı prefix', () {
      const id = '11111111-2222-3333-4444-555555555555';
      expect(
        OutboundIdempotency.ficheNumber('order', id).startsWith('OO'),
        isTrue,
      );
      expect(
        OutboundIdempotency.ficheNumber('waybill', id).startsWith('OD'),
        isTrue,
      );
    });

    test('~ NUMBER → kararlı kod uygulanır', () {
      final record = <String, dynamic>{'NUMBER': '~', 'ARP_CODE': 'C1'};
      OutboundIdempotency.applyToRecord(
        record,
        entityType: 'invoice',
        entityId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      expect(record['NUMBER'], isNot(equals('~')));
      expect(OutboundIdempotency.needsStableNumber(record['NUMBER']), isFalse);
    });

    test('mevcut NUMBER korunur', () {
      final record = <String, dynamic>{'NUMBER': 'FAT-100'};
      OutboundIdempotency.applyToRecord(
        record,
        entityType: 'invoice',
        entityId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      expect(record['NUMBER'], 'FAT-100');
    });

    test('force:true → ops_doc_id NUMBER (Tiger push)', () {
      const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
      final record = <String, dynamic>{'NUMBER': 'FAT-100'};
      OutboundIdempotency.applyToRecord(
        record,
        entityType: 'invoice',
        entityId: id,
        force: true,
      );
      expect(
        record['NUMBER'],
        OutboundIdempotency.ficheNumber('invoice', id),
      );
    });

    test('itemMatchesNumber — FICHENO / NUMBER', () {
      const n = 'OIAAAAAAAAAAAA';
      expect(
        OutboundIdempotency.itemMatchesNumber({'NUMBER': n}, n),
        isTrue,
      );
      expect(
        OutboundIdempotency.itemMatchesNumber({'FICHENO': n}, n),
        isTrue,
      );
      expect(
        OutboundIdempotency.itemMatchesNumber({'NUMBER': 'OTHER'}, n),
        isFalse,
      );
      expect(
        OutboundIdempotency.itemMatchesNumber({'NUMBER': n}, '~'),
        isFalse,
      );
    });
  });

  group('OutboundSyncPhase', () {
    test('normalize', () {
      expect(
        OutboundSyncPhase.normalize(null),
        OutboundSyncPhase.pgPending,
      );
      expect(
        OutboundSyncPhase.normalize(''),
        OutboundSyncPhase.pgPending,
      );
      expect(
        OutboundSyncPhase.normalize('logo'),
        OutboundSyncPhase.logo,
      );
      expect(
        OutboundSyncPhase.normalize('postgrest'),
        OutboundSyncPhase.postgrest,
      );
      expect(
        OutboundSyncPhase.normalize('pg_pending'),
        OutboundSyncPhase.pgPending,
      );
    });
  });

  group('OutboundIdempotency.opsDocId / clientDocId', () {
    test('alias aynı UUID', () {
      expect(
        OutboundIdempotency.opsDocId('  aabb-cc  '),
        'aabb-cc',
      );
      expect(
        OutboundIdempotency.clientDocId('  aabb-cc  '),
        OutboundIdempotency.opsDocId('  aabb-cc  '),
      );
    });
  });

  group('OutboundMirrorStatus + PostgrestDocumentMirror body', () {
    test('mirror sabitleri birleşik', () {
      expect(
        PostgrestDocumentMirror.statusLogoPending,
        OutboundMirrorStatus.logoPending,
      );
      expect(
        PostgrestDocumentMirror.statusConfirmed,
        OutboundMirrorStatus.confirmed,
      );
      expect(OutboundMirrorStatus.logoPending, 'logo_pending');
      expect(OutboundMirrorStatus.confirmed, 'confirmed');
    });

    test('pending body: logo_synced=0, aynı ops_doc_id', () {
      const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
      final number = OutboundIdempotency.ficheNumber('invoice', id);
      final body = PostgrestDocumentMirror.buildUpsertBody(
        entityId: id,
        firmNr: '001',
        logoRef: null,
        idempotencyCode: number,
        logoSynced: false,
        syncStatus: OutboundMirrorStatus.logoPending,
        payload: {
          'ops_doc_id': id,
          'client_doc_id': id,
          'NUMBER': number,
        },
      );

      expect(body['id'], id);
      expect(body['ops_doc_id'], id);
      expect(body['client_doc_id'], id);
      expect(body['logo_synced'], 0);
      expect(body['is_synced'], 0);
      expect(body['sync_status'], OutboundMirrorStatus.logoPending);
      expect(body.containsKey('logo_ref'), isFalse);
      expect(body['idempotency_code'], number);
    });

    test('confirmed body: logo_ref + logo_synced=1', () {
      const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
      final body = PostgrestDocumentMirror.buildUpsertBody(
        entityId: id,
        firmNr: '001',
        logoRef: '12345',
        idempotencyCode: OutboundIdempotency.ficheNumber('invoice', id),
        logoSynced: true,
        syncStatus: OutboundMirrorStatus.confirmed,
      );

      expect(body['logo_ref'], '12345');
      expect(body['logo_synced'], 1);
      expect(body['sync_status'], OutboundMirrorStatus.confirmed);
      expect(body['id'], body['ops_doc_id']);
    });
  });

  group('LogoTigerPushAdapter + idempotency', () {
    test('fromQueuePayload entityId ile NUMBER doldurur', () {
      final mapped = LogoPayloadMapper.invoiceFromLocal(
        invoice: {'id': 'inv-uuid-1', 'invoice_date': '2026-07-28'},
        items: [
          {'product_code': 'P1', 'quantity': 1, 'price': 10},
        ],
        customerCode: 'C1',
        type: 'wholesale',
      );
      // Mapper NUMBER boş/~ bırakabilir
      mapped['NUMBER'] = '~';
      final t = LogoTigerPushAdapter.fromQueuePayload(
        'invoice',
        mapped,
        entityId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      expect(t, isNotNull);
      expect(t!.restRecord['NUMBER'], isNot(equals('~')));
      expect(
        t.restRecord['NUMBER'],
        OutboundIdempotency.ficheNumber(
          'invoice',
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        ),
      );
    });

    test('fromQueuePayload force → yabancı NUMBER ezilir', () {
      const id = 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff';
      final mapped = LogoPayloadMapper.invoiceFromLocal(
        invoice: {'id': id, 'invoice_date': '2026-08-05'},
        items: [
          {'product_code': 'P1', 'quantity': 1, 'price': 10},
        ],
        customerCode: 'C1',
        type: 'wholesale',
      );
      mapped['NUMBER'] = 'FAT-FOREIGN';
      final t = LogoTigerPushAdapter.fromQueuePayload(
        'invoice',
        mapped,
        entityId: id,
      );
      expect(
        t!.restRecord['NUMBER'],
        OutboundIdempotency.ficheNumber('invoice', id),
      );
    });
  });
}
