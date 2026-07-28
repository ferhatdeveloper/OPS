// Dosya Adı: manager_reports_hub_smoke_test.dart
// Açıklama: Yönetici Raporları MBT hub kartları smoke
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/manager/reports/view/manager_reports_dashboard.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('hub dens: dönem + KASA/BANKA/ÇEK/SENET/FİRMA/FATURA/SİPARİŞ', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(tester, const ManagerReportsDashboard());

    expect(find.text('Yönetici Raporları'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('KASA'), findsOneWidget);
    expect(find.text('BANKA'), findsOneWidget);
    expect(find.text('ÇEK'), findsOneWidget);
    expect(find.text('SENET'), findsOneWidget);
    expect(find.text('FİRMA GENEL ANALİZ'), findsOneWidget);
    expect(find.text('FATURA'), findsOneWidget);
    expect(find.text('SİPARİŞ'), findsOneWidget);
    expect(find.textContaining('Girişler Toplamı'), findsWidgets);
    expect(find.textContaining('Portföydeki Çekler'), findsOneWidget);
  });

  testWidgets('FİRMA GENEL ANALİZ tap → Firma Genel Görünüm', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(tester, const ManagerReportsDashboard());
    await tester.tap(find.text('FİRMA GENEL ANALİZ'));
    await tester.pumpAndSettle();

    expect(find.text('Firma Genel Görünüm'), findsOneWidget);
    expect(find.text('Borç / Alacak'), findsOneWidget);
    expect(find.text('Satışlar (KDV Hariç)'), findsOneWidget);
    expect(find.text('Firma Aylık Görünüm'), findsOneWidget);
  });
}
