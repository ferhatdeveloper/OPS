// Dosya Adı: report_pdf_viewer_screen.dart
// Açıklama: Dens uygulama içi rapor PDF görüntüleyici (yazıcı diyaloğu birincil değil)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:typed_data';
import '../../shared/view/field_sales_dens_theme.dart';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/report_pdf_viewer_args.dart';

/// {@template report_pdf_viewer_screen}
/// Rapor PDF’ini uygulama içinde gösterir.
/// Yazdır / paylaş yalnızca alt aksiyon çubuğunda (ikincil).
///
/// Route: `/field-sales/report-pdf` (arguments: [ReportPdfViewerArgs])
///
/// Kullanım örneği:
/// ```dart
/// ReportPdfViewerScreen.fromArgs(
///   ReportPdfViewerArgs(bytes: pdfBytes, title: 'Cari Extre'),
/// );
/// ```
/// {@endtemplate}
class ReportPdfViewerScreen extends StatelessWidget {
  /// Named route
  static const String routeName = '/field-sales/report-pdf';

  /// [title]: AppBar başlığı
  final String title;

  /// [bytes]: PDF içeriği
  final Uint8List bytes;

  /// {@macro report_pdf_viewer_screen}
  const ReportPdfViewerScreen({
    Key? key,
    required this.title,
    required this.bytes,
  }) : super(key: key);

  /// {@template report_pdf_viewer_screen_from_args}
  /// Route arguments → ekran (geçersizse boş PDF).
  ///
  /// Parametreler:
  /// - [args]: [ReportPdfViewerArgs] veya null
  ///
  /// Dönüş değeri:
  /// - [ReportPdfViewerScreen]: Viewer
  /// {@endtemplate}
  factory ReportPdfViewerScreen.fromArgs(Object? args) {
    if (args is ReportPdfViewerArgs) {
      return ReportPdfViewerScreen(title: args.title, bytes: args.bytes);
    }
    return ReportPdfViewerScreen(
      title: '',
      bytes: Uint8List(0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final resolvedTitle = title.trim().isEmpty
        ? l10n.translate('field_sales.mbt_reports.pdf_viewer_title')
        : title;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: resolvedTitle,
        backgroundColor: FieldSalesDensAppBar.primaryColor,
      ),
      body: bytes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.translate('field_sales.mbt_reports.pdf_viewer_empty'),
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : PdfPreview(
              build: (_) async => bytes,
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              dynamicLayout: false,
              useActions: true,
              pdfFileName: '$resolvedTitle.pdf',
              previewPageMargin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              maxPageWidth: 900,
              actionBarTheme: const PdfActionBarTheme(
                backgroundColor: Color(0xFF375A7F),
                iconColor: Colors.white,
                height: 40,
              ),
            ),
    );
  }
}
