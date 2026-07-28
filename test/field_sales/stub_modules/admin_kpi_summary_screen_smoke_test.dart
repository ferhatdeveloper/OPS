// Dosya Adı: admin_kpi_summary_screen_smoke_test.dart
// Açıklama: Yönetici KPI özet ekranı smoke (l10n + dönem + aggregate)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/yonetici/model/admin_kpi_summary.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/view/admin_kpi_summary_screen.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/viewmodel/admin_kpi_provider.dart';

import 'stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('AdminKpiSummaryScreen — başlık, dönem ve KPI bölümleri',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

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
            waybillCount: 4,
            salesAmount: 1500,
            orderAmount: 1200,
            collectionAmount: 900,
            cashCollected: 400,
            checkCollected: 100,
            bankSnapshot: 500,
            openReceivables: 2500,
            debtorCount: 4,
            pendingOrderCount: 2,
            pendingInvoiceCount: 1,
            pendingWaybillCount: 3,
            targetAmount: 5000,
            targetAchieved: 1500,
            activeSalespersonCount: 2,
            sparklineSales: [10, 20, 15, 30, 25, 40, 35],
            sparklineCollections: [5, 8, 6, 12, 10, 15, 14],
            pivotRows: [
              AdminKpiPivotRow(
                salespersonKey: 'u1',
                salespersonName: 'Ali',
                visitCount: 10,
                collectionCount: 3,
                collectionAmount: 400,
                targetAmount: 2000,
                targetAchieved: 800,
              ),
            ],
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.admin_kpi');
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.textContaining('Bugün'), findsWidgets);
    expect(find.textContaining('Dönem aktivitesi'), findsOneWidget);
    expect(find.textContaining('Kasa'), findsWidgets);
    expect(find.textContaining('Transfer'), findsWidgets);
    expect(find.textContaining('Hedef'), findsWidgets);
    expect(find.textContaining('pivot'), findsWidgets);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('1.500,00'), findsWidgets);
  });
}
