// Dosya Adı: logo_active_firm_period_test.dart
// Açıklama: ActiveCompany → Tiger firma/dönem override birim testleri
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/logo/logo_active_firm_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(LogoActiveFirmPeriod.clear);

  group('LogoActiveFirmPeriod.applyFromCodes', () {
    test('leading zero kodları int override üretir', () {
      final ok = LogoActiveFirmPeriod.applyFromCodes(
        companyNo: '012',
        periodNo: '05',
      );
      expect(ok, isTrue);
      expect(LogoActiveFirmPeriod.firmNr, 12);
      expect(LogoActiveFirmPeriod.periodNr, 5);
      expect(LogoActiveFirmPeriod.hasOverride, isTrue);
    });

    test('geçersiz veya sıfır kod false döner, override yazılmaz', () {
      expect(
        LogoActiveFirmPeriod.applyFromCodes(
          companyNo: 'abc',
          periodNo: '01',
        ),
        isFalse,
      );
      expect(LogoActiveFirmPeriod.hasOverride, isFalse);

      expect(
        LogoActiveFirmPeriod.applyFromCodes(
          companyNo: '0',
          periodNo: '01',
        ),
        isFalse,
      );
      expect(
        LogoActiveFirmPeriod.applyFromCodes(
          companyNo: '1',
          periodNo: '0',
        ),
        isFalse,
      );
    });

    test('set negatif/sıfır değerleri yok sayar', () {
      LogoActiveFirmPeriod.set(firmNr: 10, periodNr: 2);
      LogoActiveFirmPeriod.set(firmNr: 0, periodNr: 3);
      expect(LogoActiveFirmPeriod.firmNr, 10);
      expect(LogoActiveFirmPeriod.periodNr, 2);
    });

    test('clear override’ı kaldırır', () {
      LogoActiveFirmPeriod.applyFromCodes(
        companyNo: '401',
        periodNo: '1',
      );
      LogoActiveFirmPeriod.clear();
      expect(LogoActiveFirmPeriod.firmNr, isNull);
      expect(LogoActiveFirmPeriod.periodNr, isNull);
      expect(LogoActiveFirmPeriod.hasOverride, isFalse);
    });
  });
}
