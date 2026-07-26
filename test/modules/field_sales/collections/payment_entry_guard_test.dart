// Dosya Adı: payment_entry_guard_test.dart
// Açıklama: Ödeme (payment out) cari-önce guard birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/init/navigation/routes.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/collection_provider.dart';

void main() {
  group('Payment entry cari-önce', () {
    test('payment-entry customerFirstRoutes içinde', () {
      expect(
        AppRoutes.customerFirstRoutes.contains(
          AppRoutes.fieldSalesPaymentEntry,
        ),
        isTrue,
      );
    });

    test('virman customerFirst değil', () {
      expect(
        AppRoutes.customerFirstRoutes.contains(AppRoutes.fieldSalesVirman),
        isFalse,
      );
    });

    test('geçersiz customerId ödeme için false', () {
      expect(CollectionNotifier.isValidCustomerId(null), isFalse);
      expect(CollectionNotifier.isValidCustomerId(''), isFalse);
      expect(CollectionNotifier.isValidCustomerId('P-1'), isTrue);
    });

    test('argumentsForSeedRoute payment id geçirir', () {
      expect(
        AppRoutes.argumentsForSeedRoute(
          AppRoutes.fieldSalesPaymentEntry,
          visitCustomerId: 'C-22',
        ),
        'C-22',
      );
    });
  });
}
