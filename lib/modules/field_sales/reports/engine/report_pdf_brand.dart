// Dosya Adı: report_pdf_brand.dart
// Açıklama: Rapor PDF dens marka renkleri + başlık bandı yardımcıları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// {@template report_pdf_brand}
/// Dens field_sales paleti (375A7F / 00A8E8) — MBT chrome kopyası değil.
///
/// Kullanım örneği:
/// ```dart
/// final header = ReportPdfBrand.buildHeader(
///   title: 'Cari Extre',
///   companyName: 'MBT',
///   isThermal: false,
/// );
/// ```
/// {@endtemplate}
class ReportPdfBrand {
  /// Dens primary (#375A7F)
  static final PdfColor primary = PdfColor.fromHex('375A7F');

  /// Dens accent (#00A8E8)
  static final PdfColor accent = PdfColor.fromHex('00A8E8');

  /// Açık şerit arka plan
  static final PdfColor bandLight = PdfColor.fromHex('EEF2F6');

  /// Tablo başlık arka plan (hafif primary)
  static final PdfColor tableHeaderBg = PdfColor.fromHex('D9E2EC');

  /// Kenarlık
  static final PdfColor border = PdfColor.fromHex('9FB3C8');

  /// {@macro report_pdf_brand}
  const ReportPdfBrand._();

  /// {@template report_pdf_brand_build_header}
  /// A4 zengin / 80mm kompakt PDF üst bilgi bandı.
  ///
  /// Parametreler:
  /// - [title]: Rapor başlığı
  /// - [companyName]: Firma adı
  /// - [companyChip]: `001_01` vb.
  /// - [range]: Dönem metni
  /// - [metaLines]: Ek satırlar
  /// - [logoBytes]: Önbellek logo (opsiyonel)
  /// - [isThermal]: 80 mm bel
  /// - [headerSize] / [bodySize]: Punto
  ///
  /// Dönüş değeri:
  /// - [pw.Widget]: Başlık bloğu
  /// {@endtemplate}
  static pw.Widget buildHeader({
    required String title,
    required String companyName,
    required String companyChip,
    required String range,
    required List<String> metaLines,
    Uint8List? logoBytes,
    required bool isThermal,
    required double headerSize,
    required double bodySize,
  }) {
    if (isThermal) {
      return _thermalHeader(
        title: title,
        companyName: companyName,
        range: range,
        metaLines: metaLines,
        logoBytes: logoBytes,
        headerSize: headerSize,
        bodySize: bodySize,
      );
    }
    return _a4Header(
      title: title,
      companyName: companyName,
      companyChip: companyChip,
      range: range,
      metaLines: metaLines,
      logoBytes: logoBytes,
      headerSize: headerSize,
      bodySize: bodySize,
    );
  }

  static pw.Widget? _logoImage(Uint8List? bytes, {required double maxH}) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      return pw.Image(
        pw.MemoryImage(bytes),
        height: maxH,
        fit: pw.BoxFit.contain,
      );
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _a4Header({
    required String title,
    required String companyName,
    required String companyChip,
    required String range,
    required List<String> metaLines,
    Uint8List? logoBytes,
    required double headerSize,
    required double bodySize,
  }) {
    final logo = _logoImage(logoBytes, maxH: 42);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 48,
                  height: 42,
                  alignment: pw.Alignment.center,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  padding: const pw.EdgeInsets.all(3),
                  child: logo,
                ),
                pw.SizedBox(width: 10),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (companyName.trim().isNotEmpty)
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: bodySize,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: headerSize,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (companyChip.trim().isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  child: pw.Text(
                    companyChip,
                    style: pw.TextStyle(
                      fontSize: bodySize - 1,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (range.isNotEmpty || metaLines.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: bandLight,
              border: pw.Border(
                left: pw.BorderSide(color: accent, width: 2.5),
              ),
            ),
            padding: const pw.EdgeInsets.fromLTRB(8, 5, 8, 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (range.isNotEmpty)
                  pw.Text(
                    range,
                    style: pw.TextStyle(
                      fontSize: bodySize,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                for (final line in metaLines)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(
                        fontSize: bodySize - 1,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Container(height: 1.2, color: primary),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _thermalHeader({
    required String title,
    required String companyName,
    required String range,
    required List<String> metaLines,
    Uint8List? logoBytes,
    required double headerSize,
    required double bodySize,
  }) {
    final logo = _logoImage(logoBytes, maxH: 28);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (logo != null) ...[
          pw.Center(child: logo),
          pw.SizedBox(height: 3),
        ],
        if (companyName.trim().isNotEmpty)
          pw.Text(
            companyName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: bodySize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: headerSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (range.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            range,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: bodySize - 0.5),
          ),
        ],
        for (final line in metaLines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              line,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: bodySize - 1),
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.8, color: PdfColors.grey700),
        pw.SizedBox(height: 4),
      ],
    );
  }

  /// {@template report_pdf_brand_build_footer}
  /// A4 dens alt bilgi — firma · vergi no · yazdırma · sayfa X/Y.
  /// {@endtemplate}
  static pw.Widget buildFooter({
    required String companyName,
    required String companyChip,
    String companyTaxId = '',
    required String printedAt,
    required int pageNumber,
    required int pagesCount,
    required double bodySize,
    required bool isThermal,
  }) {
    if (isThermal) {
      return pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(
          '$pageNumber/$pagesCount',
          style: pw.TextStyle(fontSize: bodySize - 1, color: PdfColors.grey700),
        ),
      );
    }
    final leftParts = <String>[];
    if (companyName.trim().isNotEmpty) leftParts.add(companyName.trim());
    if (companyChip.trim().isNotEmpty) leftParts.add(companyChip.trim());
    if (companyTaxId.trim().isNotEmpty) {
      leftParts.add('VKN ${companyTaxId.trim()}');
    }
    if (printedAt.trim().isNotEmpty) leftParts.add(printedAt.trim());
    final left = leftParts.join(' · ');
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: border, width: 0.4),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              left,
              style: pw.TextStyle(
                fontSize: bodySize - 1,
                color: PdfColors.grey800,
              ),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            '$pageNumber/$pagesCount',
            style: pw.TextStyle(
              fontSize: bodySize - 1,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
