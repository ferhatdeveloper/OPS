// Dosya Adı: mbt_report_category.dart
// Açıklama: MBT RAPORLAR hub kategori enum + menü route eşlemesi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template mbt_report_category}
/// MBT Raporlar sheet kategorileri (CARİ / STOK / …).
///
/// Kullanım örneği:
/// ```dart
/// MbtReportCategory.cari.menuRoute;
/// ```
/// {@endtemplate}
enum MbtReportCategory {
  /// Cari hesap raporları
  cari,

  /// Stok raporları
  stok,

  /// Sipariş raporları
  siparis,

  /// Fatura raporları
  fatura,

  /// İrsaliye raporları
  irsaliye,

  /// Diğer (plasiyer / ziyaret / kasa)
  diger,

  /// Yönetici özet / KPI raporları (OPS genişletme)
  yonetici,

  /// Finans (tahsilat transfer / çek / senet / kasa)
  finans,

  /// OPS saha operasyon raporları
  ops,
}

/// {@template mbt_report_category_x}
/// Kategori → menü route / l10n yardımcıları.
/// {@endtemplate}
extension MbtReportCategoryX on MbtReportCategory {
  /// [menuRoute]: database_service seed route
  String get menuRoute {
    switch (this) {
      case MbtReportCategory.cari:
        return '/field-sales/report-cari';
      case MbtReportCategory.stok:
        return '/field-sales/report-stock';
      case MbtReportCategory.siparis:
        return '/field-sales/report-siparis';
      case MbtReportCategory.fatura:
        return '/field-sales/report-invoice';
      case MbtReportCategory.irsaliye:
        return '/field-sales/report-waybill';
      case MbtReportCategory.diger:
        return '/field-sales/report-other';
      case MbtReportCategory.yonetici:
        return '/field-sales/report-yonetici';
      case MbtReportCategory.finans:
        return '/field-sales/report-finans';
      case MbtReportCategory.ops:
        return '/field-sales/report-ops';
    }
  }

  /// [titleKey]: Kategori başlık l10n anahtarı
  String get titleKey {
    switch (this) {
      case MbtReportCategory.cari:
        return 'field_sales.mbt_reports.cat_cari';
      case MbtReportCategory.stok:
        return 'field_sales.mbt_reports.cat_stok';
      case MbtReportCategory.siparis:
        return 'field_sales.mbt_reports.cat_siparis';
      case MbtReportCategory.fatura:
        return 'field_sales.mbt_reports.cat_fatura';
      case MbtReportCategory.irsaliye:
        return 'field_sales.mbt_reports.cat_irsaliye';
      case MbtReportCategory.diger:
        return 'field_sales.mbt_reports.cat_diger';
      case MbtReportCategory.yonetici:
        return 'field_sales.mbt_reports.cat_yonetici';
      case MbtReportCategory.finans:
        return 'field_sales.mbt_reports.cat_finans';
      case MbtReportCategory.ops:
        return 'field_sales.mbt_reports.cat_ops';
    }
  }

  /// {@template mbt_report_category_from_route}
  /// Menü route → kategori (bilinmeyen → null).
  ///
  /// Parametreler:
  /// - [route]: Named route
  ///
  /// Dönüş değeri:
  /// - [MbtReportCategory?]: Eşleşen kategori
  /// {@endtemplate}
  static MbtReportCategory? fromRoute(String? route) {
    if (route == null) return null;
    for (final c in MbtReportCategory.values) {
      if (c.menuRoute == route) return c;
    }
    return null;
  }
}
