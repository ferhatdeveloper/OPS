// Dosya Adı: active_company_dens_chip_test.dart
// Açıklama: Aktif firma dens chip etiket + tıklama navigasyon testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/companies/model/active_company_session.dart';
import 'package:exfin_ops/modules/field_sales/companies/view/company_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/companies/viewmodel/active_company_store.dart';
import 'package:exfin_ops/modules/field_sales/companies/widgets/active_company_dens_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveCompanyStore.resetMemory();
  });

  group('ActiveCompanyDensChip.resolveLabel', () {
    test('boş oturum null döner', () {
      expect(ActiveCompanyDensChip.resolveLabel(null), isNull);
      expect(
        ActiveCompanyDensChip.resolveLabel(ActiveCompanySession.empty),
        isNull,
      );
    });

    test('dolu oturum densChipLabel döner', () {
      const session = ActiveCompanySession(
        companyId: 'mbt_001',
        companyName: 'MBT',
        companyNo: '001',
        periodNo: '01',
      );
      expect(
        ActiveCompanyDensChip.resolveLabel(session),
        '001_01',
      );
    });
  });

  group('ActiveCompanyDensChip widget', () {
    testWidgets('etiket gösterir ve tıklanınca firma listesine gider',
        (tester) async {
      await const ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      ).save(
        const ActiveCompanySession(
          companyId: 'mbt_001',
          companyName: 'MBT',
          companyNo: '001',
          periodNo: '01',
        ),
      );

      await pumpStubWithL10n(tester, const ActiveCompanyDensChip());
      await tester.pumpAndSettle();

      expect(find.textContaining('001_01'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.byKey(ActiveCompanyDensChip.tapKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CompanyListScreen), findsOneWidget);
    });

    testWidgets('store revision sonrası etiket yenilenir', (tester) async {
      await const ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      ).save(
        const ActiveCompanySession(
          companyId: 'a',
          companyName: 'Alpha',
          companyNo: '001',
          periodNo: '01',
        ),
      );

      await pumpStubWithL10n(tester, const ActiveCompanyDensChip());
      await tester.pumpAndSettle();
      expect(find.textContaining('001_01'), findsOneWidget);

      await const ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      ).save(
        const ActiveCompanySession(
          companyId: 'b',
          companyName: 'Beta',
          companyNo: '002',
          periodNo: '02',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('002_02'), findsOneWidget);
    });
  });
}
