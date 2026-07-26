// Dosya Adı: report_dens_form_test.dart
// Açıklama: Rapor dens form iskeletinde tarih / satır / Yedekle-İndir görünürlüğü
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/collection_report_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_backup_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/sales_report_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/visit_report_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('MBT rapor dens form iskeleti', () {
    testWidgets('Satış raporu: tarih, satırlar, Yedekle/İndir görünür',
        (tester) async {
      await pumpStubWithL10n(tester, const SalesReportScreen());
      expect(find.text('Satış Raporu'), findsOneWidget);
      expect(find.text('Başlangıç Tarihi'), findsOneWidget);
      expect(find.text('Bitiş Tarihi'), findsOneWidget);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Henüz rapor satırı yok.'), findsOneWidget);
      expect(find.text('Yedekle'), findsOneWidget);
      expect(find.text('İndir'), findsOneWidget);
      expect(find.text('Raporu Getir'), findsOneWidget);
    });

    testWidgets('Tahsilat raporu: dens alanlar görünür', (tester) async {
      await pumpStubWithL10n(tester, const CollectionReportScreen());
      expect(find.text('Tahsilat Raporu'), findsOneWidget);
      expect(find.text('Başlangıç Tarihi'), findsOneWidget);
      expect(find.text('Yedekle'), findsOneWidget);
      expect(find.text('İndir'), findsOneWidget);
    });

    testWidgets('Ziyaret raporu: dens alanlar görünür', (tester) async {
      await pumpStubWithL10n(tester, const VisitReportScreen());
      expect(find.text('Ziyaret Raporu'), findsOneWidget);
      expect(find.text('Bitiş Tarihi'), findsOneWidget);
      expect(find.text('Yedekle'), findsOneWidget);
      expect(find.text('İndir'), findsOneWidget);
    });

    testWidgets('Rapor Yedekle/İndir: dens host alanlar görünür',
        (tester) async {
      await pumpStubWithL10n(tester, const ReportBackupScreen());
      expect(find.text('Rapor Yedekle/İndir'), findsOneWidget);
      expect(find.text('Başlangıç Tarihi'), findsOneWidget);
      expect(find.text('Bitiş Tarihi'), findsOneWidget);
      expect(find.text('Yedekle'), findsOneWidget);
      expect(find.text('İndir'), findsOneWidget);
      expect(find.text('Raporu Getir'), findsOneWidget);
    });
  });
}
