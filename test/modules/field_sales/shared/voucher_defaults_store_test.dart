// Dosya Adı: voucher_defaults_store_test.dart
// Açıklama: Fiş ön değerleri SharedPreferences load/save testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/shared/model/voucher_defaults_record.dart';
import 'package:exfin_ops/modules/field_sales/shared/viewmodel/voucher_defaults_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VoucherDefaultsStore', () {
    test('boş prefs yüklenince boş kayıt döner', () async {
      const store = VoucherDefaultsStore();
      final record = await store.load();

      expect(record.description, isEmpty);
      expect(record.description2, isEmpty);
      expect(record.plateNo, isEmpty);
      expect(record.specialCode1, isEmpty);
    });

    test('kaydet ve yükle tüm alanları korur', () async {
      const store = VoucherDefaultsStore();
      await store.save(
        const VoucherDefaultsRecord(
          description: 'Saha satış',
          description2: 'Not 2',
          plateNo: '34ABC123',
          specialCode1: 'OPS',
        ),
      );

      final loaded = await store.load();
      expect(loaded.description, 'Saha satış');
      expect(loaded.description2, 'Not 2');
      expect(loaded.plateNo, '34ABC123');
      expect(loaded.specialCode1, 'OPS');
    });

    test('kaydetme trim uygular', () async {
      const store = VoucherDefaultsStore();
      await store.save(
        const VoucherDefaultsRecord(
          description: '  trim  ',
          plateNo: ' 34X ',
          specialCode1: ' A ',
        ),
      );

      final loaded = await store.load();
      expect(loaded.description, 'trim');
      expect(loaded.plateNo, '34X');
      expect(loaded.specialCode1, 'A');
    });

    test('mevcut prefs anahtarlarından yükler', () async {
      SharedPreferences.setMockInitialValues({
        VoucherDefaultsStore.prefsDescription: 'Açıklama',
        VoucherDefaultsStore.prefsDescription2: 'Açıklama 2',
        VoucherDefaultsStore.prefsPlateNo: '06XYZ01',
        VoucherDefaultsStore.prefsSpecialCode1: 'K1',
      });

      const store = VoucherDefaultsStore();
      final loaded = await store.load();
      expect(loaded.description, 'Açıklama');
      expect(loaded.description2, 'Açıklama 2');
      expect(loaded.plateNo, '06XYZ01');
      expect(loaded.specialCode1, 'K1');
    });
  });
}
