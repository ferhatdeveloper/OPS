// Dosya Adı: report_chart_kind.dart
// Açıklama: MBT rapor ailesine göre grafik türü (bar / line / pie)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'mbt_report_category.dart';

/// {@template report_chart_kind}
/// Rapor sonuç Grafik sekmesi türü.
///
/// Kullanım örneği:
/// ```dart
/// final kind = ReportChartKindX.forCategory(MbtReportCategory.cari);
/// // → ReportChartKind.bar
/// ```
/// {@endtemplate}
enum ReportChartKind {
  /// Çubuk (cari / stok tutar)
  bar,

  /// Çizgi (belge / dönem serisi)
  line,

  /// Pasta (yönetici / finans dağılım)
  pie,
}

/// {@template report_chart_kind_x}
/// Kategori → varsayılan grafik türü.
/// {@endtemplate}
extension ReportChartKindX on ReportChartKind {
  /// {@template report_chart_kind_for_category}
  /// Rapor ailesine göre makul varsayılan grafik.
  ///
  /// Parametreler:
  /// - [category]: MBT kategori
  ///
  /// Dönüş değeri:
  /// - [ReportChartKind]: bar / line / pie
  /// {@endtemplate}
  static ReportChartKind forCategory(MbtReportCategory category) {
    switch (category) {
      case MbtReportCategory.siparis:
      case MbtReportCategory.fatura:
      case MbtReportCategory.irsaliye:
      case MbtReportCategory.ops:
        return ReportChartKind.line;
      case MbtReportCategory.yonetici:
      case MbtReportCategory.finans:
        return ReportChartKind.pie;
      case MbtReportCategory.cari:
      case MbtReportCategory.stok:
      case MbtReportCategory.diger:
        return ReportChartKind.bar;
    }
  }
}
