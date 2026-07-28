// Dosya Adı: mbt_report_catalog_test.dart
// Açıklama: MBT rapor katalog sayıları ve dizayn dosya parity
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_catalog.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_category.dart';
import 'package:exfin_ops/modules/field_sales/reports/other/model/other_report_scope.dart';

void main() {
  group('MbtReportCatalog', () {
    test('kategori sayıları MBT + extras ile eşleşir', () {
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.cari),
        hasLength(15),
      );
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.stok).length,
        greaterThanOrEqualTo(9),
      );
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.siparis),
        hasLength(4),
      );
      expect(MbtReportCatalog.byCategory(MbtReportCategory.fatura), hasLength(3));
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.irsaliye),
        hasLength(4),
      );
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.diger),
        hasLength(10),
      );
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.yonetici),
        hasLength(12),
      );
      expect(
        MbtReportCatalog.byCategory(MbtReportCategory.finans),
        hasLength(7),
      );
      expect(MbtReportCatalog.byCategory(MbtReportCategory.ops), hasLength(8));
      expect(MbtReportCatalog.all.length, greaterThanOrEqualTo(72));
      expect(MbtReportCatalog.byId('cari_risk'), isNotNull);
    });

    test('bilinen .repx dizayn dosyaları doğru', () {
      expect(MbtReportCatalog.byId('cari_extre')?.designFile, 'CariExtre.repx');
      expect(
        MbtReportCatalog.byId('kasa_hareket')?.designFile,
        'KasaHareketRapor.repx',
      );
      expect(
        MbtReportCatalog.byId('plasiyer_rota')?.designFile,
        'SaticiRotaRapor.repx',
      );
      expect(
        MbtReportCatalog.byId('finans_portfoy_cek')?.designFile,
        'MusteriCekSenetListe.repx',
      );
      expect(
        MbtReportCatalog.byId('bekleyen_alis_siparis')?.designFile,
        'BekleyenAlisSiparisler.repx',
      );
    });

    test('yonetici / finans / ops menü route', () {
      expect(
        MbtReportCategory.yonetici.menuRoute,
        '/field-sales/report-yonetici',
      );
      expect(
        MbtReportCategory.finans.menuRoute,
        '/field-sales/report-finans',
      );
      expect(
        MbtReportCategoryX.fromRoute('/field-sales/report-finans'),
        MbtReportCategory.finans,
      );
      expect(
        MbtReportCategory.ops.menuRoute,
        '/field-sales/report-ops',
      );
    });

    test('menü route eşlemesi', () {
      expect(
        MbtReportCategoryX.fromRoute('/field-sales/report-cari'),
        MbtReportCategory.cari,
      );
      expect(
        MbtReportCategoryX.fromRoute('/field-sales/report-other'),
        MbtReportCategory.diger,
      );
      expect(MbtReportCategoryX.fromRoute('/field-sales/report-backup'), isNull);
    });
  });

  group('OtherReportScope', () {
    test('DİĞER core + extras sahipliği', () {
      expect(OtherReportScope.owns('plasiyer_gps'), isTrue);
      expect(OtherReportScope.owns('finans_kasa_bakiye'), isTrue);
      expect(OtherReportScope.owns('yonetici_firma_genel'), isTrue);
      expect(OtherReportScope.owns('cari_extre'), isFalse);
      expect(
        OtherReportScope.extrasBeyond40Owned,
        greaterThanOrEqualTo(23),
      );
    });
  });
}
