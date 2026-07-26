// Dosya Adı: virman_save_guard_test.dart
// Açıklama: Virman kaydı validasyon guard birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/collection_provider.dart';

void main() {
  group('CollectionNotifier.saveVirman guard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('boş kasa kodları false + hata anahtarı', () async {
      final notifier = container.read(collectionProvider.notifier);
      final result = await notifier.saveVirman(
        fromSafeCode: '',
        toSafeCode: '02',
        amount: 100,
      );
      expect(result, isFalse);
      expect(
        container.read(collectionProvider).error,
        'field_sales.virman_requires_accounts',
      );
    });

    test('aynı kasa kodları false', () async {
      final notifier = container.read(collectionProvider.notifier);
      final result = await notifier.saveVirman(
        fromSafeCode: '01',
        toSafeCode: '01',
        amount: 50,
      );
      expect(result, isFalse);
      expect(
        container.read(collectionProvider).error,
        'field_sales.virman_same_account',
      );
    });

    test('geçersiz tutar false', () async {
      final notifier = container.read(collectionProvider.notifier);
      final result = await notifier.saveVirman(
        fromSafeCode: '01',
        toSafeCode: '02',
        amount: 0,
      );
      expect(result, isFalse);
      expect(
        container.read(collectionProvider).error,
        'field_sales.payment_invalid_amount',
      );
    });
  });

  group('LogoPayloadMapper.virmanFromLocal', () {
    test('payment_type virman; ARP yok; kaynak/hedef kasa dolu', () {
      final payload = LogoPayloadMapper.virmanFromLocal(
        amount: 250.5,
        fromSafeCode: '01',
        toSafeCode: '02',
        description: 'Test virman',
      );
      expect(payload['payment_type'], 'virman');
      expect(payload['amount'], 250.5);
      expect(payload['safe_code'], '01');
      expect(payload['target_safe_code'], '02');
      expect(payload.containsKey('customer_code'), isFalse);
      expect(payload.containsKey('ARP_CODE'), isFalse);
      expect(payload['description'], 'Test virman');
    });

    test('cash tahsilat tipine flatten etmez', () {
      final payload = LogoPayloadMapper.virmanFromLocal(
        amount: 10,
        fromSafeCode: 'A',
        toSafeCode: 'B',
      );
      expect(payload['payment_type'], isNot(equals('cash')));
      expect(payload['payment_type'], 'virman');
    });
  });
}
