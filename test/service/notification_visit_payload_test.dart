// Dosya Adı: notification_visit_payload_test.dart
// Açıklama: Bildirim visit payload parse birim testi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/service/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visitPayload / parseVisitCustomerId round-trip', () {
    expect(
      NotificationService.visitPayload('cust-1'),
      'visit:cust-1',
    );
    expect(
      NotificationService.parseVisitCustomerId('visit:cust-1'),
      'cust-1',
    );
    expect(NotificationService.parseVisitCustomerId('other'), isNull);
    expect(NotificationService.parseVisitCustomerId('visit:'), isNull);
    expect(NotificationService.parseVisitCustomerId(null), isNull);
  });
}
