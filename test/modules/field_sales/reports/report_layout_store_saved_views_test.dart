// Dosya Adı: report_layout_store_saved_views_test.dart
// Açıklama: Adlı layout / pivot görünüm kalıcılığı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_saved_view.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_layout_store.dart';

void main() {
  test('upsertSavedView pivot görünümünü listeler', () async {
    final mem = <String, String>{};
    final store = ReportLayoutStore(memory: mem);
    const reportId = 'cari_extre';

    await store.upsertSavedView(
      reportId: reportId,
      view: ReportSavedView.pivot(
        id: 'p1',
        name: 'Kod × Tutar',
        rowFieldId: 'code',
        valueFieldId: 'amount',
      ),
    );

    final views = await store.listSavedViews(reportId);
    expect(views, hasLength(1));
    expect(views.first.name, 'Kod × Tutar');
    expect(views.first.rowFieldId, 'code');
  });

  test('layout şablonu kaydedilir', () async {
    final mem = <String, String>{};
    final store = ReportLayoutStore(memory: mem);
    const reportId = 'cari_extre';
    final layout = ReportLayoutDefaults.forReportId(reportId);

    await store.upsertSavedView(
      reportId: reportId,
      view: ReportSavedView.layout(
        id: 'l1',
        name: 'Sade',
        layout: layout,
      ),
    );

    final views = await store.listSavedViews(reportId);
    expect(views.first.kind, ReportSavedViewKind.layout);
    expect(views.first.layout?.reportId, reportId);
  });
}
