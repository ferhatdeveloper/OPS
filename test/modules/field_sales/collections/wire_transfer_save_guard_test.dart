// Dosya Adı: wire_transfer_save_guard_test.dart
// Açıklama: Havale/EFT kaydı validasyon guard birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/finance_movement_type.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/collection_provider.dart';

void main() {
  group('CollectionNotifier.saveWireTransfer guard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('boş cari false + hata anahtarı', () async {
      final notifier = container.read(collectionProvider.notifier);
      final result = await notifier.saveWireTransfer(
        customerId: '',
        amount: 100,
        bankCode: 'BNK01',
      );
      expect(result, isFalse);
      expect(
        container.read(collectionProvider).error,
        'field_sales.wire_requires_customer',
      );
    });

    test('geçersiz tutar false', () async {
      final notifier = container.read(collectionProvider.notifier);
      final result = await notifier.saveWireTransfer(
        customerId: 'C001',
        amount: 0,
        bankCode: 'BNK01',
      );
      expect(result, isFalse);
      expect(
        container.read(collectionProvider).error,
        'field_sales.payment_invalid_amount',
      );
    });

    test('boş banka kodu false', () async {
      final notifier = container.read(collectionProvider.notifier);
      final result = await notifier.saveWireTransfer(
        customerId: 'C001',
        amount: 50,
        bankCode: '  ',
      );
      expect(result, isFalse);
      expect(
        container.read(collectionProvider).error,
        'field_sales.wire_requires_bank_code',
      );
    });
  });

  group('FinanceMovementType wire normalize', () {
    test('havale/eft/wire → wire API kodu', () {
      expect(FinanceMovementType.normalizeApiCode('wire'), 'wire');
      expect(FinanceMovementType.normalizeApiCode('EFT'), 'wire');
      expect(FinanceMovementType.normalizeApiCode('havale'), 'wire');
      expect(FinanceMovementType.normalizeApiCode('wire_transfer'), 'wire');
      expect(FinanceMovementType.wireApiCode, 'wire');
    });

    test('virman transfer alias bozulmaz', () {
      expect(FinanceMovementType.normalizeApiCode('virman'), 'virman');
      expect(FinanceMovementType.normalizeApiCode('transfer'), 'virman');
    });
  });
}
