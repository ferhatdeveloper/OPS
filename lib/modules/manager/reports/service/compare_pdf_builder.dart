// Dosya Adı: compare_pdf_builder.dart
// Açıklama: Esnek karşılaştırma matrisi PDF üretimi
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/compare_matrix_models.dart';
import '../model/period_comparison_models.dart';

/// {@template compare_pdf_builder}
/// Matris sonucundan PDF bayt üretir.
///
/// Kullanım örneği:
/// ```dart
/// final bytes = await ComparePdfBuilder().build(
///   result: result,
///   title: 'Dönem Karşılaştırma',
///   labels: labels,
/// );
/// ```
/// {@endtemplate}
class ComparePdfBuilder {
  /// {@macro compare_pdf_builder}
  const ComparePdfBuilder();

  /// {@template compare_pdf_builder_build}
  /// PDF oluştur.
  ///
  /// Parametreler:
  /// - [result]: Matris
  /// - [title]: Rapor başlığı
  /// - [labels]: UI etiketleri (l10n map)
  ///
  /// Dönüş değeri:
  /// - [Uint8List]: PDF
  /// {@endtemplate}
  Future<Uint8List> build({
    required CompareMatrixResult result,
    required String title,
    required ComparePdfLabels labels,
  }) async {
    final doc = pw.Document();
    final generated = DateTime.now().toIso8601String();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${labels.generatedAt}: $generated',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${labels.template}: ${labels.templateName}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '${labels.rowAxis}: ${labels.rowAxisName}  |  '
            '${labels.colAxis}: ${labels.colAxisName}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            labels.periods,
            style: const pw.TextStyle(fontSize: 9),
          ),
          for (final p in result.query.periods)
            pw.Text(
              '- ${p.label}: ${p.range.fromKey} - ${p.range.toKey}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 12),
          if (result.summaryMetrics.isNotEmpty) ...[
            pw.Text(
              labels.summary,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            _summaryTable(result.summaryMetrics, labels),
            pw.SizedBox(height: 14),
          ],
          pw.Text(
            labels.matrix,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          if (result.rowKeys.isEmpty)
            pw.Text(
              labels.empty,
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            _matrixTable(result),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _summaryTable(
    List<PeriodMetricRow> rows,
    ComparePdfLabels labels,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell(labels.metric, bold: true),
            _cell(labels.previous, bold: true, align: pw.TextAlign.right),
            _cell(labels.current, bold: true, align: pw.TextAlign.right),
            _cell(labels.diffPct, bold: true, align: pw.TextAlign.right),
          ],
        ),
        for (final r in rows)
          pw.TableRow(
            children: [
              _cell(r.kind.name),
              _cell(r.periodA.toStringAsFixed(1), align: pw.TextAlign.right),
              _cell(r.periodB.toStringAsFixed(1), align: pw.TextAlign.right),
              _cell(
                '${r.pctChange.toStringAsFixed(1)}%',
                align: pw.TextAlign.right,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _matrixTable(CompareMatrixResult result) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('#', bold: true),
            for (final c in result.colLabels)
              _cell(c, bold: true, align: pw.TextAlign.right),
          ],
        ),
        for (var i = 0; i < result.rowKeys.length; i++)
          pw.TableRow(
            children: [
              _cell(result.rowLabels[i]),
              for (final col in result.colKeys)
                _cell(
                  result
                      .valueAt(result.rowKeys[i], col)
                      .toStringAsFixed(0),
                  align: pw.TextAlign.right,
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

/// {@template compare_pdf_labels}
/// PDF metin etiketleri (l10n).
/// {@endtemplate}
class ComparePdfLabels {
  /// [generatedAt]: Oluşturma
  final String generatedAt;

  /// [template]: Şablon
  final String template;

  /// [templateName]: Şablon adı
  final String templateName;

  /// [rowAxis]: Satır
  final String rowAxis;

  /// [rowAxisName]: Satır adı
  final String rowAxisName;

  /// [colAxis]: Sütun
  final String colAxis;

  /// [colAxisName]: Sütun adı
  final String colAxisName;

  /// [periods]: Dönemler başlık
  final String periods;

  /// [summary]: Özet
  final String summary;

  /// [matrix]: Matris
  final String matrix;

  /// [empty]: Boş
  final String empty;

  /// [metric]: Metrik
  final String metric;

  /// [previous]: Önceki
  final String previous;

  /// [current]: Güncel
  final String current;

  /// [diffPct]: Fark %
  final String diffPct;

  /// {@macro compare_pdf_labels}
  const ComparePdfLabels({
    required this.generatedAt,
    required this.template,
    required this.templateName,
    required this.rowAxis,
    required this.rowAxisName,
    required this.colAxis,
    required this.colAxisName,
    required this.periods,
    required this.summary,
    required this.matrix,
    required this.empty,
    required this.metric,
    required this.previous,
    required this.current,
    required this.diffPct,
  });
}
