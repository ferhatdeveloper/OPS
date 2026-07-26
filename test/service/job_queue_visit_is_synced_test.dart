// Dosya Adı: job_queue_visit_is_synced_test.dart
// Açıklama: Visit kuyruk sync sonrası is_synced tablo eşlemesi birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/service/job_queue_entity_map.dart';

void main() {
  group('jobQueueEntityTable', () {
    test('visit / visits → visits (is_synced hedefi)', () {
      expect(jobQueueEntityTable('visit'), 'visits');
      expect(jobQueueEntityTable('visits'), 'visits');
      expect(jobQueueEntityTable('VISIT'), 'visits');
    });

    test('bilinen diğer tipler korunur', () {
      expect(jobQueueEntityTable('order'), 'orders');
      expect(jobQueueEntityTable('invoice'), 'invoices');
      expect(jobQueueEntityTable('collection'), 'collections');
      expect(jobQueueEntityTable('waybill'), 'waybills');
      expect(jobQueueEntityTable('stock_count'), 'stock_counts');
    });

    test('bilinmeyen tip null', () {
      expect(jobQueueEntityTable('unknown_xyz'), isNull);
    });
  });

  group('visit queue payload → is_synced yolu', () {
    test('boş payload → hazır değil (is_synced işaretlenmez)', () {
      expect(isVisitQueuePayloadReady(null), isFalse);
      expect(isVisitQueuePayloadReady({}), isFalse);
    });

    test('dolu payload → ok/skipped gövdesi (kuyruk sonrası is_synced)', () {
      expect(
        isVisitQueuePayloadReady({
          'local_visit_id': 'v-1',
          'customer_code': 'C100',
        }),
        isTrue,
      );
      final data = visitQueueSkippedData({
        'local_visit_id': 'v-1',
        'customer_code': 'C100',
        'reason_code': 'ORDER',
      });
      expect(data['skipped'], isTrue);
      expect(data['entity_type'], 'visit');
      expect(data['entity_id'], 'v-1');
    });
  });
}
