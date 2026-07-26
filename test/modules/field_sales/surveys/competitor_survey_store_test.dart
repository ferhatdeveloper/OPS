// Dosya Adı: competitor_survey_store_test.dart
// Açıklama: Rakip anket SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/surveys/model/competitor_survey_record.dart';
import 'package:exfin_ops/modules/field_sales/surveys/viewmodel/competitor_survey_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CompetitorSurveyStore', () {
    test('boş prefs yüklenince varsayılan döner', () async {
      const store = CompetitorSurveyStore();
      final record = await store.load();
      expect(record.brandName, isEmpty);
      expect(record.observedPrice, isNull);
      expect(record.onPromotion, isFalse);
    });

    test('save / load turu kalıcıdır', () async {
      const store = CompetitorSurveyStore();
      final updatedAt = DateTime(2026, 7, 26, 14, 30);
      await store.save(
        CompetitorSurveyRecord(
          customerCode: 'C002',
          brandName: 'Rakip',
          productName: 'Ürün X',
          observedPrice: 19.9,
          hasStock: true,
          onPromotion: true,
          notes: 'promo',
          updatedAt: updatedAt,
        ),
      );

      final loaded = await store.load();
      expect(loaded.customerCode, 'C002');
      expect(loaded.brandName, 'Rakip');
      expect(loaded.productName, 'Ürün X');
      expect(loaded.observedPrice, 19.9);
      expect(loaded.onPromotion, isTrue);
      expect(loaded.updatedAt, updatedAt);

      await store.clear();
      expect((await store.load()).productName, isEmpty);
    });
  });
}
