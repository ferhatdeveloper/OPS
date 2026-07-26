// Dosya Adı: collection_customer_guard_test.dart
// Açıklama: Tahsilat kaydında boş cari (customerId) engelinin unit testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/collection_provider.dart';

void main() {
  group('CollectionNotifier customerId guard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('isValidCustomerId boş veya whitespace için false döner', () {
      expect(CollectionNotifier.isValidCustomerId(null), isFalse);
      expect(CollectionNotifier.isValidCustomerId(''), isFalse);
      expect(CollectionNotifier.isValidCustomerId('   '), isFalse);
      expect(CollectionNotifier.isValidCustomerId('cust-1'), isTrue);
    });

    test(
      'saveCollection boş customerId ile false döner ve hata mesajı set eder',
      () async {
        final notifier = container.read(collectionProvider.notifier);

        final result = await notifier.saveCollection(
          customerId: '',
          amount: 100,
          paymentType: 'Cash',
        );

        expect(result, isFalse);
        final state = container.read(collectionProvider);
        expect(
          state.error,
          'field_sales.collection_save_requires_customer',
        );
      },
    );

    test(
      'saveCollection whitespace customerId ile false döner',
      () async {
        final notifier = container.read(collectionProvider.notifier);

        final result = await notifier.saveCollection(
          customerId: '   ',
          amount: 50,
          paymentType: 'Cash',
        );

        expect(result, isFalse);
        final state = container.read(collectionProvider);
        expect(
          state.error,
          'field_sales.collection_save_requires_customer',
        );
      },
    );
  });
}
