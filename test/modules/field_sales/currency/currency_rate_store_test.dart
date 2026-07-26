// Dosya Adı: currency_rate_store_test.dart
// Açıklama: Döviz kuru SharedPreferences load/save testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/currency/model/currency_rate_record.dart';
import 'package:exfin_ops/modules/field_sales/currency/model/currency_rate_seed.dart';
import 'package:exfin_ops/modules/field_sales/currency/viewmodel/currency_rate_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CurrencyRateStore', () {
    test('boş prefs yüklenince seed varsayılanları döner', () async {
      const store = CurrencyRateStore();
      final record = await store.load();

      expect(record.rates.length, CurrencyRateSeed.codes.length);
      expect(record.rates['USD'], '47,2497');
      expect(record.rates['TL'], '1,0000');
      for (final code in CurrencyRateSeed.codes) {
        expect(record.rates.containsKey(code), isTrue);
      }
    });

    test('kaydet ve yükle tarih + tüm kurları korur', () async {
      const store = CurrencyRateStore();
      final rates = {
        for (final row in CurrencyRateSeed.defaultRows) row.code: row.rateText,
      };
      rates['USD'] = '48,1234';
      rates['EUR'] = '54,0000';

      await store.save(
        CurrencyRateRecord(
          rateDate: DateTime(2026, 7, 26),
          rates: rates,
        ),
      );

      final loaded = await store.load();
      expect(loaded.rateDate.year, 2026);
      expect(loaded.rateDate.month, 7);
      expect(loaded.rateDate.day, 26);
      expect(loaded.rates['USD'], '48,1234');
      expect(loaded.rates['EUR'], '54,0000');
      expect(loaded.rates['TL'], '1,0000');
    });

    test('kaydetme kur metinlerinde trim uygular', () async {
      const store = CurrencyRateStore();
      await store.save(
        CurrencyRateRecord(
          rateDate: DateTime(2026, 1, 1),
          rates: {
            for (final code in CurrencyRateSeed.codes) code: ' 1,0000 ',
          },
        ),
      );

      final loaded = await store.load();
      expect(loaded.rates['USD'], '1,0000');
    });

    test('mevcut prefs anahtarlarından yükler', () async {
      SharedPreferences.setMockInitialValues({
        CurrencyRateStore.prefsDate: '2026-03-15',
        CurrencyRateStore.prefsRates:
            '{"USD":"40,0000","EUR":"45,0000","TL":"1,0000"}',
      });

      const store = CurrencyRateStore();
      final loaded = await store.load();
      expect(loaded.rateDate.year, 2026);
      expect(loaded.rateDate.month, 3);
      expect(loaded.rateDate.day, 15);
      expect(loaded.rates['USD'], '40,0000');
      expect(loaded.rates['EUR'], '45,0000');
      // Eksik kodlar seed ile tamamlanır
      expect(loaded.rates['GBP'], '63,0648');
      expect(loaded.rates['TL'], '1,0000');
    });

    test('Hatwan pull sonrası satış kurları store.save ile kalır', () async {
      const store = CurrencyRateStore();
      final base = CurrencyRateRecord.defaults(
        rateDate: DateTime(2026, 7, 26),
      );
      // Pull wire: eşleşen kodlara TR formatlı satış kuru yaz
      final afterPull = Map<String, String>.from(base.rates);
      afterPull['USD'] = '1520,0000';
      afterPull['EUR'] = '112,8500';
      afterPull['TRY'] = '42,0000';

      await store.save(
        CurrencyRateRecord(
          rateDate: base.rateDate,
          rates: afterPull,
        ),
      );

      final loaded = await store.load();
      expect(loaded.rates['USD'], '1520,0000');
      expect(loaded.rates['EUR'], '112,8500');
      expect(loaded.rates['TRY'], '42,0000');
      expect(loaded.rates['TL'], '1,0000');
    });
  });
}
