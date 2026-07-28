// Dosya Adı: report_dens_empty_state_test.dart
// Açıklama: Rapor dens empty-state widget (query [])
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_dens_empty_state.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_result_list_pane.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('ReportDensEmptyState mesaj + hint gösterir', (tester) async {
    await pumpStubWithL10n(
      tester,
      const Scaffold(body: ReportDensEmptyState()),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Gösterilecek satır yok'), findsOneWidget);
    expect(
      find.text('Filtreleri değiştirip tekrar Görüntüle deneyin.'),
      findsOneWidget,
    );
  });

  testWidgets('ReportResultListPane boş rows dens empty', (tester) async {
    final layout = ReportLayoutDefaults.forReportId('cari_extre');
    await pumpStubWithL10n(
      tester,
      Scaffold(
        body: ReportResultListPane(layout: layout, rows: const []),
      ),
    );

    expect(find.byType(ReportDensEmptyState), findsOneWidget);
    expect(find.text('Gösterilecek satır yok'), findsOneWidget);
  });
}
