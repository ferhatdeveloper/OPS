// Dosya Adı: active_context_switcher_test.dart
// Açıklama: Firma bağlam geçişi — store kaydı (sync kapalı) birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/companies/model/active_company_session.dart';
import 'package:exfin_ops/modules/field_sales/companies/viewmodel/active_company_store.dart';
import 'package:exfin_ops/modules/field_sales/companies/viewmodel/active_context_switcher.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/active_warehouse_session.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/active_warehouse_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveCompanyStore.resetMemory();
    ActiveWarehouseStore.resetMemory();
  });

  group('ActiveContextSwitcher', () {
    test('applyCompany firma/dönemi prefs + belleğe yazar (sync kapalı)',
        () async {
      const switcher = ActiveContextSwitcher(
        companyStore: ActiveCompanyStore(
          syncLogoPrefs: false,
          syncPostgresContext: false,
        ),
        syncMaster: false,
        clearCache: false,
        persistLocalDb: false,
      );

      const session = ActiveCompanySession(
        companyId: 'mbt_001',
        companyName: 'MBT',
        companyNo: '001',
        periodNo: '01',
        startDate: '01-01-2024',
        endDate: '31-12-2024',
      );

      final result = await switcher.applyCompany(session);

      expect(result.company.companyNo, '001');
      expect(result.company.periodNo, '01');
      expect(ActiveCompanyStore.current?.appBarLabel, 'MBT ( 001_01 )');

      final loaded = await const ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      ).load();
      expect(loaded.companyNo, '001');
      expect(loaded.periodNo, '01');
    });

    test('applyWarehouse ambar oturumunu kaydeder', () async {
      const switcher = ActiveContextSwitcher(
        syncMaster: false,
        clearCache: false,
      );
      await switcher.applyWarehouse(
        const ActiveWarehouseSession(
          code: 'MRK',
          name: 'Merkez Depo',
          type: 'center',
        ),
      );

      expect(ActiveWarehouseStore.current?.code, 'MRK');
      final loaded = await const ActiveWarehouseStore().load();
      expect(loaded.code, 'MRK');
      expect(loaded.name, 'Merkez Depo');
      expect(loaded.label, 'MRK · Merkez Depo');
    });
  });
}
