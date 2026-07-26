// Dosya Adı: admin_kpi_summary_screen_smoke_test.dart
// Açıklama: Yönetici KPI özet ekranı smoke (l10n + SQLite aggregate override)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/yonetici/model/admin_kpi_summary.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/view/admin_kpi_summary_screen.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/viewmodel/admin_kpi_provider.dart';

import 'stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('AdminKpiSummaryScreen — başlık ve 4 KPI aggregate',
      (tester) async {
    await pumpStubWithL10n(
      tester,
      const AdminKpiSummaryScreen(),
      overrides: [
        adminKpiSummaryProvider.overrideWith(
          (ref) async => const AdminKpiSummary(
            orderCount: 12,
            invoiceCount: 8,
            collectionCount: 5,
            visitCount: 23,
          ),
        ),
      ],
    );
    // FutureProvider microtask + frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.admin_kpi');
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
  });
}
