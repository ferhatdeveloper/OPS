// Dosya Adı: active_company_store_test.dart
// Açıklama: Aktif firma/dönem session/prefs kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/modules/field_sales/companies/model/active_company_session.dart';
import 'package:exfin_ops/modules/field_sales/companies/viewmodel/active_company_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveCompanyStore.resetMemory();
  });

  group('ActiveCompanySession', () {
    test('appBarLabel MBT biçiminde firma_dönem gösterir', () {
      const session = ActiveCompanySession(
        companyId: 'mbt_001',
        companyName: 'MBT',
        companyNo: '001',
        periodNo: '01',
      );
      expect(session.appBarLabel, 'MBT ( 001_01 )');
      expect(session.densChipLabel, '001_01');
      expect(session.isNotEmpty, isTrue);
    });

    test('empty oturum isEmpty', () {
      expect(ActiveCompanySession.empty.isEmpty, isTrue);
    });
  });

  group('ActiveCompanyStore', () {
    test('boş prefs yüklenince empty döner', () async {
      const store = ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      );
      final session = await store.load();
      expect(session.isEmpty, isTrue);
      expect(ActiveCompanyStore.current, isNull);
    });

    test('kaydet ve yükle firma/dönem alanlarını korur', () async {
      const store = ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      );
      const session = ActiveCompanySession(
        companyId: 'mbt_001',
        companyName: 'MBT',
        companyNo: '001',
        periodNo: '01',
        startDate: '01-01-2024',
        endDate: '31-12-2024',
      );

      await store.save(session);

      expect(ActiveCompanyStore.current, session);

      final loaded = await store.load();
      expect(loaded.companyId, 'mbt_001');
      expect(loaded.companyName, 'MBT');
      expect(loaded.companyNo, '001');
      expect(loaded.periodNo, '01');
      expect(loaded.startDate, '01-01-2024');
      expect(loaded.endDate, '31-12-2024');
      expect(ActiveCompanyStore.current?.appBarLabel, 'MBT ( 001_01 )');
    });

    test('clear prefs ve belleği sıfırlar', () async {
      const store = ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      );
      await store.save(
        const ActiveCompanySession(
          companyId: 'x',
          companyName: 'X',
          companyNo: '002',
          periodNo: '02',
        ),
      );
      await store.clear();
      expect(ActiveCompanyStore.current, isNull);
      final loaded = await store.load();
      expect(loaded.isEmpty, isTrue);
    });
  });
}
