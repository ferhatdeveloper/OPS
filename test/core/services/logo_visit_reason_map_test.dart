// Dosya Adı: logo_visit_reason_map_test.dart
// Açıklama: visits.reason_code → Logo/sync payload map birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_reason_master.dart';

void main() {
  group('LogoPayloadMapper visit reason_code', () {
    test('master kodları resolve ile korunur', () {
      for (final code in VisitReasonMaster.codes) {
        expect(
          LogoPayloadMapper.resolveVisitReasonCode(code),
          code,
        );
      }
    });

    test('küçük harf / alias → master kod', () {
      expect(
        LogoPayloadMapper.resolveVisitReasonCode('routine'),
        LogoPayloadMapper.visitReasonRoutine,
      );
      expect(
        LogoPayloadMapper.resolveVisitReasonCode('rutin'),
        LogoPayloadMapper.visitReasonRoutine,
      );
      expect(
        LogoPayloadMapper.resolveVisitReasonCode('tahsilat'),
        LogoPayloadMapper.visitReasonCollection,
      );
      expect(
        LogoPayloadMapper.resolveVisitReasonCode('siparis'),
        LogoPayloadMapper.visitReasonOrder,
      );
      expect(
        LogoPayloadMapper.resolveVisitReasonCode('new_customer'),
        LogoPayloadMapper.visitReasonNewCustomer,
      );
    });

    test('boş / null → null', () {
      expect(LogoPayloadMapper.resolveVisitReasonCode(null), isNull);
      expect(LogoPayloadMapper.resolveVisitReasonCode(''), isNull);
      expect(LogoPayloadMapper.resolveVisitReasonCode('  '), isNull);
    });

    test('bilinmeyen → OTHER', () {
      expect(
        LogoPayloadMapper.resolveVisitReasonCode('NOPE'),
        LogoPayloadMapper.visitReasonOther,
      );
    });

    test('visitFromLocal reason_code → visit_type / SPECODE', () {
      final payload = LogoPayloadMapper.visitFromLocal(
        visit: {
          'id': 'v-1',
          'reason_code': 'ORDER',
          'notes': 'SEBEP: Sipariş Alma',
          'check_in_at': '2026-07-26T10:00:00.000',
          'check_out_at': '2026-07-26T10:15:00.000',
          'check_in_lat': 41.0,
          'check_in_long': 29.0,
          'status': 'Completed',
          'duration_minutes': 15,
        },
        customerCode: 'C100',
        customerName: 'Demo Cari',
        salesmanCode: 'P01',
      );

      expect(payload['customer_code'], 'C100');
      expect(payload['customer_name'], 'Demo Cari');
      expect(payload['reason_code'], 'ORDER');
      expect(payload['visit_type'], 'ORDER');
      expect(payload['SPECODE'], 'ORDER');
      expect(payload['special_code'], 'ORDER');
      expect(payload['notes'], 'SEBEP: Sipariş Alma');
      expect(payload['status'], 'Completed');
      expect(payload['salesman_code'], 'P01');
      expect(payload['local_visit_id'], 'v-1');
      expect(payload['check_in_time'], isNotNull);
      expect(payload['check_in_lat'], 41.0);
      expect(payload['check_in_lng'], 29.0);
    });

    test('visitFromLocal visit_type alias kabul eder', () {
      final payload = LogoPayloadMapper.visitFromLocal(
        visit: {
          'id': 'v-2',
          'visit_type': 'COLLECTION',
          'status': 'Completed',
        },
        customerCode: 'C200',
      );
      expect(payload['reason_code'], 'COLLECTION');
      expect(payload['visit_type'], 'COLLECTION');
      expect(payload['SPECODE'], 'COLLECTION');
    });

    test('reason_code yoksa SPECODE/visit_type yok', () {
      final payload = LogoPayloadMapper.visitFromLocal(
        visit: {'id': 'v-3', 'status': 'Open'},
        customerCode: 'C300',
      );
      expect(payload.containsKey('reason_code'), isFalse);
      expect(payload.containsKey('visit_type'), isFalse);
      expect(payload.containsKey('SPECODE'), isFalse);
      expect(payload['customer_code'], 'C300');
    });
  });
}
