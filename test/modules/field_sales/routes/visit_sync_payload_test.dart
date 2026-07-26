// Dosya Adı: visit_sync_payload_test.dart
// Açıklama: VisitModel.reasonCode → Logo/sync payload wire birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/route_model.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/visit_provider.dart';

void main() {
  group('buildVisitSyncPayload', () {
    test('reasonCode → reason_code / visit_type / SPECODE', () {
      final visit = VisitModel(
        id: 'v-wire-1',
        customerId: 'cust-1',
        checkInAt: DateTime(2026, 7, 26, 10),
        checkOutAt: DateTime(2026, 7, 26, 10, 20),
        notes: 'SEBEP: Sipariş Alma',
        reasonCode: 'ORDER',
        status: 'Completed',
        durationMinutes: 20,
      );

      final payload = buildVisitSyncPayload(
        visit: visit,
        customerCode: 'C100',
        customerName: 'Demo',
        salesmanCode: 'P01',
      );

      expect(payload['local_visit_id'], 'v-wire-1');
      expect(payload['customer_code'], 'C100');
      expect(payload['reason_code'], 'ORDER');
      expect(payload['visit_type'], 'ORDER');
      expect(payload['SPECODE'], 'ORDER');
      expect(payload['special_code'], 'ORDER');
      expect(payload['salesman_code'], 'P01');
      expect(
        LogoPayloadMapper.resolveVisitReasonCode(visit.reasonCode),
        'ORDER',
      );
    });

    test('entity_type sabiti visit', () {
      expect(LogoPayloadMapper.visitEntityType, 'visit');
    });

    test('reasonCode yoksa SPECODE eklenmez', () {
      final visit = VisitModel(
        id: 'v-wire-2',
        customerId: 'cust-2',
        checkInAt: DateTime(2026, 7, 26),
        status: 'Completed',
      );
      final payload = buildVisitSyncPayload(
        visit: visit,
        customerCode: 'C200',
      );
      expect(payload.containsKey('reason_code'), isFalse);
      expect(payload.containsKey('SPECODE'), isFalse);
    });
  });
}
