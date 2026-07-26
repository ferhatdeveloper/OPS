// Dosya Adı: day_sales_gate_test.dart
// Açıklama: Mesai satış gate sınıflandırma ve isDayOpen testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/other/model/day_status_record.dart';
import 'package:exfin_ops/modules/field_sales/other/viewmodel/day_sales_gate.dart';
import 'package:exfin_ops/modules/field_sales/other/viewmodel/day_status_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DaySalesGate', () {
    test('sipariş/fatura/irsaliye/tahsilat mesai gerektirir', () {
      expect(
        DaySalesGate.requiresOpenDay(moduleName: 'Sipariş Girişi'),
        isTrue,
      );
      expect(
        DaySalesGate.requiresOpenDay(moduleName: 'Satış Faturası'),
        isTrue,
      );
      expect(
        DaySalesGate.requiresOpenDay(moduleName: 'Tahsilat Girişi'),
        isTrue,
      );
      expect(
        DaySalesGate.requiresOpenDay(route: '/field-sales/waybill-wholesale'),
        isTrue,
      );
      expect(
        DaySalesGate.requiresOpenDay(moduleName: 'Müşteri Listesi'),
        isFalse,
      );
    });
  });

  group('DayStatusStore.isDayOpen', () {
    test('varsayılan kayıtta mesai kapalı', () async {
      final store = DayStatusStore();
      expect(await store.isDayOpen(), isFalse);
      expect((await store.load()).isDayOpen, isFalse);
    });

    test('isDayStarted true ve completed false ise açık', () async {
      final store = DayStatusStore();
      await store.save(
        const DayStatusRecord(
          plate: '34 ABC 01',
          startKm: 100,
          isDayStarted: true,
          completed: false,
        ),
      );
      expect(await store.isDayOpen(), isTrue);
    });

    test('completed true ise kapalı', () async {
      final store = DayStatusStore();
      await store.save(
        const DayStatusRecord(
          plate: '34 ABC 01',
          startKm: 100,
          endKm: 150,
          isDayStarted: false,
          completed: true,
        ),
      );
      expect(await store.isDayOpen(), isFalse);
    });
  });

  group('day_gate l10n', () {
    test('day_gate_required TR çözülür', () async {
      final l10n = await AppLocalization.resolve();
      expect(l10n.isLoaded, isTrue);
      expect(
        l10n.translate('field_sales.day_gate_required'),
        contains('Mesai'),
      );
    });
  });
}
