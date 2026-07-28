// Dosya Adı: customer_list_weekday_filter_test.dart
// Açıklama: Cari liste gün tab indeksi + rota filtresi birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_model.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/weekly_route_weekday.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/weekly_route_plan_store.dart';

void main() {
  group('CustomerListScreen weekday tabs', () {
    test('dayTabCount = 1 (tüm) + 7 gün', () {
      expect(CustomerListScreen.dayTabCount, 8);
    });

    test('weekdayForTab — 0 null, 1=Pzt … 7=Paz', () {
      expect(CustomerListScreen.weekdayForTab(0), isNull);
      expect(
        CustomerListScreen.weekdayForTab(1)?.dayOfWeek,
        WeeklyRouteWeekday.monday,
      );
      expect(
        CustomerListScreen.weekdayForTab(7)?.dayOfWeek,
        WeeklyRouteWeekday.sunday,
      );
    });

    test('filtre — gün planındaki cariler; tüm günler hepsi', () {
      final now = DateTime(2026, 7, 27);
      final customers = [
        CustomerModel(id: 'a', name: 'A', createdAt: now, updatedAt: now),
        CustomerModel(id: 'b', name: 'B', createdAt: now, updatedAt: now),
        CustomerModel(id: 'c', name: 'C', createdAt: now, updatedAt: now),
      ];

      final mon = WeeklyRoutePlanStore.filterCustomersByRouteDay(
        customers: customers,
        idOf: (c) => c.id,
        routeCustomerIds: {'a', 'c'},
      );
      expect(mon.map((c) => c.id).toList(), ['a', 'c']);

      final all = WeeklyRoutePlanStore.filterCustomersByRouteDay(
        customers: customers,
        idOf: (c) => c.id,
        routeCustomerIds: null,
      );
      expect(all.length, 3);
    });
  });
}
