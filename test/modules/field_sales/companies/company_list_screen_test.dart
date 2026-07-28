// Dosya Adı: company_list_screen_test.dart
// Açıklama: Şirketler dens route, sekme çözümleme ve satır model testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/companies/view/company_list_screen.dart';

void main() {
  group('CompanyListScreen route', () {
    test('routeName menü path ile aynı', () {
      expect(
        CompanyListScreen.routeName,
        '/field-sales/companies',
      );
    });

    test('CompanyPeriodRow dens alanları', () {
      const row = CompanyPeriodRow(
        companyId: 'firm-uuid',
        name: 'Tenant Firma',
        companyNo: '003',
        periodNo: '01',
        startDate: '01-01-2026',
        endDate: '31-12-2026',
      );
      expect(row.name, 'Tenant Firma');
      expect(row.companyNo, '003');
      expect(row.periodNo, '01');
    });

    test('CompanyFirmRow dens alanları', () {
      const firm = CompanyFirmRow(
        companyId: 'firm-uuid',
        name: 'Tenant Firma',
        companyNo: '003',
      );
      expect(firm.name, 'Tenant Firma');
      expect(firm.companyNo, '003');
    });
  });

  group('CompanyListScreen.resolveTab', () {
    test('enum argümanı aynen döner', () {
      expect(
        CompanyListScreen.resolveTab(CompanyContextTab.periods),
        CompanyContextTab.periods,
      );
    });

    test('int indeks sekmeye map olur', () {
      expect(CompanyListScreen.resolveTab(0), CompanyContextTab.firms);
      expect(CompanyListScreen.resolveTab(1), CompanyContextTab.periods);
      expect(CompanyListScreen.resolveTab(2), CompanyContextTab.warehouses);
    });

    test('string alias depo sekmesine gider', () {
      expect(
        CompanyListScreen.resolveTab('warehouses'),
        CompanyContextTab.warehouses,
      );
      expect(
        CompanyListScreen.resolveTab('depo'),
        CompanyContextTab.warehouses,
      );
    });

    test('bilinmeyen / null firmalar sekmesi', () {
      expect(CompanyListScreen.resolveTab(null), CompanyContextTab.firms);
      expect(CompanyListScreen.resolveTab('x'), CompanyContextTab.firms);
    });
  });
}
