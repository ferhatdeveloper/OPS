// Dosya Adı: report_layout_designer_screen_test.dart
// Açıklama: Rapor dizayn dens ekranı — sütun toggle smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_layout_designer_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_layout_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('Cari Extre dizayn: sütunlar + sayfa boyutu', (tester) async {
    final store = ReportLayoutStore(memory: <String, String>{});
    await pumpStubWithL10n(
      tester,
      ReportLayoutDesignerScreen(
        reportId: 'cari_extre',
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rapor Dizaynı'), findsOneWidget);
    expect(find.text('CARİ HESAP EKSTRESİ'), findsOneWidget);
    expect(find.text('Tüm alanlar'), findsOneWidget);
    expect(find.text('Ref No Tarih'), findsOneWidget);
    expect(find.text('Borç'), findsOneWidget);
    expect(find.text('Alacak'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);

    // İlk Switch (Üst bilgi) değil — sütun switch’lerinden birini kapat
    final switches = find.byType(Switch);
    expect(switches, findsWidgets);
    // Header / footer / totals / density = 4; ardından sütunlar
    await tester.tap(switches.at(4));
    await tester.pumpAndSettle();

    final loaded = await store.load('cari_extre');
    expect(loaded.columns.first.visible, isFalse);
  });
}
