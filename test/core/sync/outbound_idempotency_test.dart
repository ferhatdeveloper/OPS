// Dosya Adı: outbound_idempotency_test.dart
// Açıklama: Kararlı fiş NUMBER / çift fatura engeli birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/logo/logo_tiger_push_adapter.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/core/sync/outbound_idempotency.dart';
import 'package:exfin_ops/core/sync/outbound_sync_phases.dart';
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
  });

  group('OutboundSyncPhase', () {
    test('normalize', () {
      expect(OutboundSyncPhase.normalize(null), OutboundSyncPhase.logo);
      expect(OutboundSyncPhase.normalize(''), OutboundSyncPhase.logo);
      expect(
        OutboundSyncPhase.normalize('postgrest'),
        OutboundSyncPhase.postgrest,
      );
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
  });
}
