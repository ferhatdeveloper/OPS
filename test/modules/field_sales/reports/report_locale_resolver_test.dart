// Dosya Adı: report_locale_resolver_test.dart
// Açıklama: Rapor dili fall-back zinciri birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/reports/model/report_layout.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_locale_resolver.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_language_preference_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportLocaleResolver', () {
    test('layout locale ayar ve uygulama dilinden önce gelir', () {
      expect(
        ReportLocaleResolver.resolve(
          layoutLocale: 'en',
          settingsDefault: 'ar',
          appLocale: 'tr',
        ),
        'en',
      );
    });

    test('layout yoksa ayarlar varsayılanı kullanılır', () {
      expect(
        ReportLocaleResolver.resolve(
          layoutLocale: null,
          settingsDefault: 'ku',
          appLocale: 'tr',
        ),
        'ku',
      );
    });

    test('layout ve ayar yoksa uygulama dili', () {
      expect(
        ReportLocaleResolver.resolve(
          layoutLocale: '',
          settingsDefault: null,
          appLocale: 'fa',
        ),
        'fa',
      );
    });

    test('ckb → ku normalize', () {
      expect(ReportLocaleResolver.normalize('ckb'), 'ku');
    });
  });

  group('ReportLayout.locale JSON', () {
    test('locale roundtrip', () {
      final base = ReportLayoutDefaults.forReportId('cari_extre')
          .copyWith(locale: 'ar');
      final restored = ReportLayout.fromJson(base.toJson());
      expect(restored.locale, 'ar');
      expect(restored, base);
    });

    test('clearLocale null yazar', () {
      final withLocale = ReportLayoutDefaults.forReportId('cari_extre')
          .copyWith(locale: 'en');
      final cleared = withLocale.copyWith(clearLocale: true);
      expect(cleared.locale, isNull);
    });
  });

  group('ReportLanguagePreferenceStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('boş prefs null döner', () async {
      const store = ReportLanguagePreferenceStore();
      expect(await store.load(), isNull);
    });

    test('kaydet ve yükle', () async {
      const store = ReportLanguagePreferenceStore();
      await store.save('de');
      expect(await store.load(), 'de');
      await store.save(null);
      expect(await store.load(), isNull);
    });
  });
}
