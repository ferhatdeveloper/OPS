// Dosya Adı: company_list_screen_test.dart
// Açıklama: Şirketler dens route seed ve stub satır smoke testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/companies/view/company_list_screen.dart';

void main() {
  group('CompanyListScreen route seed', () {
    test('routeName menü seed path ile aynı', () {
      expect(
        CompanyListScreen.routeName,
        '/field-sales/companies',
      );
    });

    test('MBT stub satırı dens alanları dolu', () {
      const row = CompanyPeriodRow(
        companyId: 'mbt_001',
        name: 'MBT',
        companyNo: '001',
        periodNo: '01',
        startDate: '01-01-2024',
        endDate: '31-12-2024',
      );
      expect(row.name, 'MBT');
      expect(row.companyNo, '001');
      expect(row.periodNo, '01');
      expect(row.startDate, '01-01-2024');
      expect(row.endDate, '31-12-2024');
    });
  });
}
