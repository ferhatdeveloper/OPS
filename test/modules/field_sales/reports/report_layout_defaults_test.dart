// Dosya Adı: report_layout_defaults_test.dart
// Açıklama: Rapor layout varsayılanları + sütun toggle / JSON roundtrip
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_catalog.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_layout_store.dart';

void main() {
  group('ReportLayoutDefaults', () {
    test('katalog kadar varsayılan layout üretir', () {
      final all = ReportLayoutDefaults.all();
      expect(all.keys, hasLength(MbtReportCatalog.all.length));
      for (final r in MbtReportCatalog.all) {
        final layout = all[r.id]!;
        expect(layout.reportId, r.id);
        expect(layout.columns, isNotEmpty, reason: r.id);
        expect(layout.visibleColumns, isNotEmpty, reason: r.id);
      }
    });

    test('Cari Extre bilinen sütunlar', () {
      final layout = ReportLayoutDefaults.forReportId('cari_extre');
      expect(
        layout.visibleColumns.map((c) => c.id).toList(),
        ['ref_no_date', 'description', 'debit', 'credit', 'balance'],
      );
      expect(layout.showTotals, isTrue);
    });

    test('Tahsilat bilinen sütunlar', () {
      final layout = ReportLayoutDefaults.forReportId('tahsilat_listesi');
      expect(
        layout.visibleColumns.map((c) => c.id).toList(),
        [
          'code',
          'title',
          'txn_date',
          'due_date',
          'txn_type',
          'amount',
          'remaining',
          'day_diff',
        ],
      );
    });

    test('Stok Bakiye bilinen sütunlar', () {
      final layout = ReportLayoutDefaults.forReportId('stok_bakiye');
      expect(
        layout.visibleColumns.map((c) => c.id).toList(),
        ['stock_code', 'stock_name', 'balance'],
      );
      expect(layout.showTotals, isTrue);
    });
  });

  group('ReportLayout column toggle', () {
    test('toggleColumn gizler / gösterir', () {
      final base = ReportLayoutDefaults.forReportId('cari_extre');
      expect(base.visibleColumns, hasLength(5));

      final hidden = base.toggleColumn('debit', visible: false);
      expect(hidden.visibleColumns.map((c) => c.id), isNot(contains('debit')));
      expect(hidden.visibleColumns, hasLength(4));

      final shown = hidden.toggleColumn('debit', visible: true);
      expect(shown.visibleColumns.map((c) => c.id), contains('debit'));
      expect(shown.visibleColumns, hasLength(5));
    });

    test('reorderColumns sırayı değiştirir', () {
      final base = ReportLayoutDefaults.forReportId('stok_bakiye');
      final reordered = base.reorderColumns(0, 2);
      expect(reordered.columns.first.id, 'stock_name');
      expect(reordered.columns[1].id, 'stock_code');
    });

    test('JSON roundtrip görünürlük korur', () {
      final base = ReportLayoutDefaults.forReportId('tahsilat_listesi')
          .toggleColumn('day_diff', visible: false);
      final restored = ReportLayout.fromJson(base.toJson());
      expect(restored, base);
      expect(
        restored.visibleColumns.map((c) => c.id),
        isNot(contains('day_diff')),
      );
    });
  });

  group('ReportLayoutStore', () {
    test('save/load toggle kalıcı (memory)', () async {
      final mem = <String, String>{};
      final store = ReportLayoutStore(memory: mem);
      final edited = ReportLayoutDefaults.forReportId('cari_extre')
          .toggleColumn('credit', visible: false);
      await store.save(edited);
      final loaded = await store.load('cari_extre');
      expect(loaded.visibleColumns.map((c) => c.id), isNot(contains('credit')));
      expect(loaded.visibleColumns, hasLength(4));
    });

    test('reset varsayılana döner', () async {
      final mem = <String, String>{};
      final store = ReportLayoutStore(memory: mem);
      await store.save(
        ReportLayoutDefaults.forReportId('stok_bakiye')
            .toggleColumn('balance', visible: false),
      );
      final reset = await store.reset('stok_bakiye');
      expect(reset.visibleColumns.map((c) => c.id), contains('balance'));
    });
  });
}
