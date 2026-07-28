// Dosya Adı: visit_open_redirect_test.dart
// Açıklama: Açık ziyaret yönlendirme saf mantık birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/routes/viewmodel/visit_open_redirect_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRedirectToOpenVisit', () {
    test('yalnızca visit_already_open anahtarı', () {
      expect(
        shouldRedirectToOpenVisit(kVisitAlreadyOpenErrorKey),
        isTrue,
      );
      expect(shouldRedirectToOpenVisit('field_sales.too_far'), isFalse);
    });
  });

  group('openVisitRedirectCustomerId', () {
    test('trim + boş kontrol', () {
      expect(openVisitRedirectCustomerId('  abc  '), 'abc');
      expect(openVisitRedirectCustomerId(''), isNull);
    });
  });
}
