// Dosya Adı: report_layout_page_size.dart
// Açıklama: Rapor dizayn sayfa boyutu (A4/A5/Letter/80mm bel) — .repx yok
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:pdf/pdf.dart';

/// {@template report_layout_page_size}
/// PDF / önizleme sayfa boyutu.
///
/// Kullanım örneği:
/// ```dart
/// ReportLayoutPageSize.a4;
/// ReportLayoutPageSize.thermal80;
/// ```
/// {@endtemplate}
enum ReportLayoutPageSize {
  /// A4
  a4,

  /// A5
  a5,

  /// Letter
  letter,

  /// 80 mm termal / bel yazıcısı (genişlik ~226.8 pt)
  thermal80,
}

/// {@template report_layout_page_size_x}
/// Serileştirme ve PDF format yardımcıları.
/// {@endtemplate}
extension ReportLayoutPageSizeX on ReportLayoutPageSize {
  /// [storageKey]: JSON anahtarı
  String get storageKey {
    switch (this) {
      case ReportLayoutPageSize.a4:
        return 'a4';
      case ReportLayoutPageSize.a5:
        return 'a5';
      case ReportLayoutPageSize.letter:
        return 'letter';
      case ReportLayoutPageSize.thermal80:
        return 'thermal80';
    }
  }

  /// Bel / termal rulo (dar genişlik) mi?
  bool get isThermalReceipt => this == ReportLayoutPageSize.thermal80;

  /// 80 mm → pt (~226.77). Diğer boyutlar PdfPageFormat ile.
  static const double thermal80WidthPt = 80 * PdfPageFormat.mm;

  /// 80×297 mm rulo sayfa yüksekliği (pt).
  static const double thermal80HeightPt = 297 * PdfPageFormat.mm;

  /// {@template report_layout_page_size_pdf_format}
  /// pdf paketi sayfa formatı.
  ///
  /// Dönüş değeri:
  /// - [PdfPageFormat]: Sayfa boyutu
  /// {@endtemplate}
  PdfPageFormat get pdfFormat {
    switch (this) {
      case ReportLayoutPageSize.a5:
        return PdfPageFormat.a5;
      case ReportLayoutPageSize.letter:
        return PdfPageFormat.letter;
      case ReportLayoutPageSize.thermal80:
        return const PdfPageFormat(
          thermal80WidthPt,
          thermal80HeightPt,
          marginAll: 4 * PdfPageFormat.mm,
        );
      case ReportLayoutPageSize.a4:
        return PdfPageFormat.a4;
    }
  }

  /// {@template report_layout_page_size_parse}
  /// Anahtardan enum; bilinmeyen → A4.
  ///
  /// Parametreler:
  /// - [raw]: JSON string
  ///
  /// Dönüş değeri:
  /// - [ReportLayoutPageSize]: Sayfa boyutu
  /// {@endtemplate}
  static ReportLayoutPageSize parse(String? raw) {
    switch (raw) {
      case 'a5':
        return ReportLayoutPageSize.a5;
      case 'letter':
        return ReportLayoutPageSize.letter;
      case 'thermal80':
      case '80mm':
      case 'mm80':
        return ReportLayoutPageSize.thermal80;
      case 'a4':
      default:
        return ReportLayoutPageSize.a4;
    }
  }
}
