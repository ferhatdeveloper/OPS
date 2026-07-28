// Dosya Adı: report_category_list_screen_test.dart
// Açıklama: Rapor kategori dens listesi + Parametreler smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_category.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_category_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_parameters_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('CARİ kategori listesinde Cari Extre görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      const ReportCategoryListScreen(category: MbtReportCategory.cari),
    );
    expect(find.text('CARİ'), findsOneWidget);
    expect(find.text('CARİ HESAP EKSTRESİ'), findsOneWidget);
    expect(find.text('TAHSİLAT LİSTESİ'), findsOneWidget);
  });

  testWidgets('STOK kategori 9 rapor başlığı', (tester) async {
    await pumpStubWithL10n(
      tester,
      const ReportCategoryListScreen(category: MbtReportCategory.stok),
    );
    expect(find.text('STOK'), findsOneWidget);
    expect(find.text('STOK BAKİYE LİSTESİ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('EN ÇOK ALINAN ÜRÜNLER'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('EN ÇOK ALINAN ÜRÜNLER'), findsOneWidget);
  });

  testWidgets('Parametreler: preset + dizayn düzenle + aksiyonlar',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const ReportParametersScreen(reportId: 'cari_extre'),
    );
    expect(find.text('Parametreler'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Bu Hafta'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.text('Bu Yıl'), findsOneWidget);
    expect(find.text('BAŞLANGIÇ'), findsOneWidget);
    expect(find.text('BİTİŞ'), findsOneWidget);
    expect(find.text('Cari seçimi'), findsOneWidget);
    expect(find.text('Tüm'), findsWidgets);
    expect(find.text('DİZAYN'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
    expect(find.text('E-MAIL'), findsOneWidget);
    expect(find.text('Görüntüle'), findsWidgets);
  });

  testWidgets('Tahsilat parametreleri: cari seçimi + ÖZELKOD',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const ReportParametersScreen(reportId: 'tahsilat_listesi'),
    );
    expect(find.text('Cari seçimi'), findsOneWidget);
    expect(find.text('Cari seçimi 2'), findsOneWidget);
    expect(find.text('ÖZELKOD 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Düzenle'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Düzenle'), findsOneWidget);
  });

  testWidgets('Stok Bakiye: stok KOD metin + cari seçici + bakiye',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const ReportParametersScreen(reportId: 'stok_bakiye'),
    );
    expect(find.text('KOD'), findsOneWidget);
    expect(find.text('Cari seçimi'), findsOneWidget);
    expect(find.text("'0'DAN BÜYÜK OLANLAR"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Düzenle'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Düzenle'), findsOneWidget);
  });
}
