// Dosya Adı: report_pdf_viewer_args.dart
// Açıklama: Uygulama içi rapor PDF görüntüleyici route argümanları
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:typed_data';

/// {@template report_pdf_viewer_args}
/// Named route ile PDF bayt + başlık taşır.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   ReportPdfViewerScreen.routeName,
///   arguments: ReportPdfViewerArgs(bytes: pdf, title: 'Cari Extre'),
/// );
/// ```
/// {@endtemplate}
class ReportPdfViewerArgs {
  /// [bytes]: Hazır PDF içeriği
  final Uint8List bytes;

  /// [title]: AppBar / dosya adı
  final String title;

  /// {@macro report_pdf_viewer_args}
  const ReportPdfViewerArgs({
    required this.bytes,
    required this.title,
  });
}
