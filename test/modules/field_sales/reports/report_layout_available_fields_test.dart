// Dosya Adı: report_layout_available_fields_test.dart
// Açıklama: Rapor dizayn availableFields ≥ varsayılan görünür sütunlar
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_catalog.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_available_fields.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_layout_store.dart';

void main() {
  group('ReportLayoutAvailableFields', () {
    test('her rapor: available ≥ varsayılan görünür', () {
      for (final r in MbtReportCatalog.all) {
        final available = ReportLayoutAvailableFields.forReportId(r.id);
        final seededVisible = ReportLayoutDefaults.seededVisibleIds(r.id);
        expect(
          available.length,
          greaterThanOrEqualTo(seededVisible.length),
          reason: r.id,
        );
        for (final id in seededVisible) {
          expect(
            available.map((c) => c.id),
            contains(id),
            reason: '${r.id} eksik: $id',
          );
        }
      }
    });

    test('cari_extre: code/title available, varsayılan gizli', () {
      final layout = ReportLayoutDefaults.forReportId('cari_extre');
      final ids = layout.columns.map((c) => c.id).toList();
      expect(ids, containsAll(['code', 'title']));
      expect(layout.visibleColumns.map((c) => c.id), isNot(contains('code')));
      expect(layout.visibleColumns.map((c) => c.id), isNot(contains('title')));
      expect(
        layout.visibleColumns.map((c) => c.id).toList(),
        ['ref_no_date', 'description', 'debit', 'credit', 'balance'],
      );
      expect(layout.columns.length, greaterThan(layout.visibleColumns.length));
    });

    test('stok_bakiye: ürün DB alanları available (≥ görünür 3)', () {
      final layout = ReportLayoutDefaults.forReportId('stok_bakiye');
      expect(layout.visibleColumns, hasLength(3));
      expect(layout.columns.length, greaterThanOrEqualTo(3));
      final ids = layout.columns.map((c) => c.id).toSet();
      expect(ids, containsAll(['barcode', 'unit', 'price', 'category']));
      expect(
        layout.columns.firstWhere((c) => c.id == 'barcode').visible,
        isFalse,
      );
    });

    test('merge: kayıtlı layout’a yeni available alan ekler', () async {
      final mem = <String, String>{};
      final store = ReportLayoutStore(memory: mem);
      mem['${ReportLayoutStore.prefsPrefix}cari_extre'] = _visibleOnlyJson();

      final loaded = await store.load('cari_extre');
      expect(loaded.columns.map((c) => c.id), containsAll(['code', 'title']));
      expect(loaded.visibleColumns.map((c) => c.id), isNot(contains('code')));
      expect(loaded.visibleColumns, hasLength(5));
    });
  });
}

String _visibleOnlyJson() {
  return '''
{
  "schemaVersion": 1,
  "reportId": "cari_extre",
  "titleKey": "field_sales.mbt_reports.cari_extre",
  "pageSize": "a4",
  "showHeader": true,
  "showFooter": true,
  "showTotals": true,
  "dense": true,
  "groupByColumnId": null,
  "columns": [
    {"id":"ref_no_date","titleKey":"field_sales.mbt_reports.col_ref_no_date","visible":true,"flex":2,"align":"left","includeInTotals":false},
    {"id":"description","titleKey":"field_sales.mbt_reports.col_description","visible":true,"flex":3,"align":"left","includeInTotals":false},
    {"id":"debit","titleKey":"field_sales.mbt_reports.col_debit","visible":true,"flex":1,"align":"right","includeInTotals":true},
    {"id":"credit","titleKey":"field_sales.mbt_reports.col_credit","visible":true,"flex":1,"align":"right","includeInTotals":true},
    {"id":"balance","titleKey":"field_sales.mbt_reports.col_balance","visible":true,"flex":1,"align":"right","includeInTotals":false}
  ]
}
''';
}
