// Dosya Adı: report_pdf_viewer_screen_test.dart
// Açıklama: Dens in-app PDF viewer smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_pdf_viewer_screen.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_app_bar.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('boş PDF → dens AppBar + empty mesaj', (tester) async {
    await pumpStubWithL10n(
      tester,
      ReportPdfViewerScreen(
        bytes: Uint8List(0),
        title: '',
      ),
    );

    expect(find.byType(FieldSalesDensAppBar), findsOneWidget);
    expect(find.text('Rapor PDF'), findsOneWidget);
    expect(find.text('Görüntülenecek PDF yok.'), findsOneWidget);
  });
}
