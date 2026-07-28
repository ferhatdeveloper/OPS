// Dosya Adı: collection_currency_exchange_test.dart
// Açıklama: Tahsilat döviz kuru hesabı birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/currency/engine/collection_currency_exchange.dart';

void main() {
  group('CollectionCurrencyExchange.normalize', () {
    test('tl → TRY, boş → boş', () {
      expect(CollectionCurrencyExchange.normalize('tl'), 'TRY');
      expect(CollectionCurrencyExchange.normalize(' usd '), 'USD');
      expect(CollectionCurrencyExchange.normalize(''), '');
      expect(CollectionCurrencyExchange.normalize(null), '');
    });
  });

  group('CollectionCurrencyExchange.isDefaultCurrency', () {
    test('aynı kod (TL alias) varsayılan sayılır', () {
      expect(
        CollectionCurrencyExchange.isDefaultCurrency('TRY', 'TRY'),
        isTrue,
      );
      expect(
        CollectionCurrencyExchange.isDefaultCurrency('TL', 'TRY'),
        isTrue,
      );
      expect(
        CollectionCurrencyExchange.isDefaultCurrency('USD', 'TRY'),
        isFalse,
      );
    });
  });

  group('CollectionCurrencyExchange.parseRate', () {
    test('TR ve EN ondalık', () {
      expect(CollectionCurrencyExchange.parseRate('47,2497'), 47.2497);
      expect(CollectionCurrencyExchange.parseRate('47.2497'), 47.2497);
      expect(CollectionCurrencyExchange.parseRate('1.250,75'), 1250.75);
      expect(CollectionCurrencyExchange.parseRate(''), isNull);
      expect(CollectionCurrencyExchange.parseRate(null), isNull);
    });
  });

  group('CollectionCurrencyExchange.toBaseAmount', () {
    test('MBT: tutar × kur = merkez', () {
      expect(
        CollectionCurrencyExchange.toBaseAmount(
          amountInCurrency: 10,
          exchangeRate: 47.25,
        ),
        closeTo(472.5, 0.0001),
      );
      expect(
        CollectionCurrencyExchange.toBaseAmount(
          amountInCurrency: 100,
          exchangeRate: 1,
        ),
        100,
      );
    });

    test('geçersiz girdi → 0', () {
      expect(
        CollectionCurrencyExchange.toBaseAmount(
          amountInCurrency: 0,
          exchangeRate: 47,
        ),
        0,
      );
      expect(
        CollectionCurrencyExchange.toBaseAmount(
          amountInCurrency: 10,
          exchangeRate: 0,
        ),
        0,
      );
      expect(
        CollectionCurrencyExchange.toBaseAmount(
          amountInCurrency: -5,
          exchangeRate: 2,
        ),
        0,
      );
    });
  });

  group('CollectionCurrencyExchange.resolveRate', () {
    test('varsayılan dövizde kur 1', () {
      expect(
        CollectionCurrencyExchange.resolveRate(
          currencyCode: 'IQD',
          defaultCurrency: 'IQD',
          rates: const {'USD': '1310', 'IQD': '1'},
        ),
        1.0,
      );
    });

    test('yabancı dövizde store kuru', () {
      expect(
        CollectionCurrencyExchange.resolveRate(
          currencyCode: 'USD',
          defaultCurrency: 'TRY',
          rates: const {'USD': '47,2497'},
        ),
        closeTo(47.2497, 0.0001),
      );
    });

    test('kur yoksa 0', () {
      expect(
        CollectionCurrencyExchange.resolveRate(
          currencyCode: 'EUR',
          defaultCurrency: 'TRY',
          rates: const {},
        ),
        0,
      );
    });
  });
}
