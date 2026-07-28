// Dosya Adı: appearance_settings_store_test.dart
// Açıklama: Görünüm ayarları SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/settings/model/appearance_settings_record.dart';
import 'package:exfin_ops/modules/field_sales/settings/viewmodel/appearance_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppearanceSettingsStore', () {
    test('boş prefs yüklenince varsayılan kayıt döner', () async {
      const store = AppearanceSettingsStore();
      final record = await store.load();

      expect(
        record.fontSize,
        AppearanceSettingsRecord.defaultFontSize,
      );
      expect(
        record.primaryColorValue,
        AppearanceSettingsRecord.defaultPrimaryColorValue,
      );
      expect(record.textScaleFactor, 1.0);
    });

    test('kaydet ve yükle font + rengi korur', () async {
      const store = AppearanceSettingsStore();
      await store.save(
        const AppearanceSettingsRecord(
          fontSize: 11,
          primaryColorValue: 0xFF1565C0,
        ),
      );

      final loaded = await store.load();
      expect(loaded.fontSize, 11);
      expect(loaded.primaryColorValue, 0xFF1565C0);
      expect(
        loaded.textScaleFactor,
        closeTo(11 / AppearanceSettingsRecord.defaultFontSize, 0.001),
      );
    });

    test('save font boyutunu min/max aralığına sıkıştırır', () async {
      const store = AppearanceSettingsStore();
      await store.save(const AppearanceSettingsRecord(fontSize: 1));
      expect(
        (await store.load()).fontSize,
        AppearanceSettingsRecord.minFontSize,
      );

      await store.save(const AppearanceSettingsRecord(fontSize: 99));
      expect(
        (await store.load()).fontSize,
        AppearanceSettingsRecord.maxFontSize,
      );
    });
  });

  group('AppearanceSettingsRecord', () {
    test('clampFontSize sınırları uygular', () {
      expect(
        AppearanceSettingsRecord.clampFontSize(5),
        AppearanceSettingsRecord.minFontSize,
      );
      expect(
        AppearanceSettingsRecord.clampFontSize(25),
        AppearanceSettingsRecord.maxFontSize,
      );
      expect(AppearanceSettingsRecord.clampFontSize(12), 12);
    });
  });
}
