// Dosya Adı: weekly_route_weekday_test.dart
// Açıklama: Haftalık rota gün eşlemesi birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/routes/model/weekly_route_weekday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyRouteWeekday', () {
    test('DateTime.weekday → 1=Pzt … 7=Paz', () {
      // 2026-07-27 = Pazartesi
      final mon = WeeklyRouteWeekday.fromDateTime(DateTime(2026, 7, 27));
      expect(mon.dayOfWeek, DateTime.monday);
      expect(mon.tabIndex, 0);
      expect(mon.l10nKey, 'field_sales.weekday_monday');
      expect(mon.stableRouteId(), 'weekly-route-dow-1');
      expect(
        mon.stableRouteId(salespersonId: 'u-1'),
        'weekly-route-sp-u-1-dow-1',
      );

      final sun = WeeklyRouteWeekday.fromDateTime(DateTime(2026, 8, 2));
      expect(sun.dayOfWeek, DateTime.sunday);
      expect(sun.tabIndex, 6);
      expect(sun.l10nKey, 'field_sales.weekday_sunday');
      expect(sun.stableRouteId(), 'weekly-route-dow-7');
    });

    test('fromTabIndex / tryParse sınırları', () {
      expect(WeeklyRouteWeekday.fromTabIndex(0).dayOfWeek, 1);
      expect(WeeklyRouteWeekday.fromTabIndex(6).dayOfWeek, 7);
      expect(WeeklyRouteWeekday.fromTabIndex(99).dayOfWeek, 7);
      expect(WeeklyRouteWeekday.tryParse(0), isNull);
      expect(WeeklyRouteWeekday.tryParse(8), isNull);
      expect(WeeklyRouteWeekday.tryParse(3)?.dayOfWeek, 3);
    });

    test('allDays Pazartesi→Pazar sırası', () {
      expect(WeeklyRouteWeekday.allDays, [1, 2, 3, 4, 5, 6, 7]);
    });
  });
}
