// Dosya Adı: visit_queue_filter_test.dart
// Açıklama: K11 visit sync_queue filtre birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/visit_queue_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterVisitQueueJobs', () {
    test('yalnızca visit / visits satırlarını bırakır', () {
      final filtered = filterVisitQueueJobs([
        {'entity_type': 'order', 'entity_id': 'O1'},
        {'entity_type': 'visit', 'entity_id': 'V1'},
        {'entity_type': 'invoice', 'entity_id': 'I1'},
        {'entity_type': 'visits', 'entity_id': 'V2'},
        {'entity_type': 'VISIT', 'entity_id': 'V3'},
      ]);

      expect(filtered.map((e) => e['entity_id']), ['V1', 'V2', 'V3']);
    });

    test('boş liste → boş', () {
      expect(filterVisitQueueJobs(const []), isEmpty);
    });

    test('visitEntityType sabiti ile uyumlu', () {
      final filtered = filterVisitQueueJobs([
        {
          'entity_type': LogoPayloadMapper.visitEntityType,
          'entity_id': 'X',
        },
      ]);
      expect(filtered, hasLength(1));
    });
  });
}
