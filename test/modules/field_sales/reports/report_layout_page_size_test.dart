// Dosya Adı: report_layout_page_size_test.dart
// Açıklama: Sayfa boyutu enum parse + 80mm PDF format
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_page_size.dart';

void main() {
  group('ReportLayoutPageSize', () {
    test('storageKey ve parse round-trip', () {
      for (final size in ReportLayoutPageSize.values) {
        expect(
          ReportLayoutPageSizeX.parse(size.storageKey),
          size,
        );
      }
    });

    test('bilinmeyen anahtar → A4', () {
      expect(
        ReportLayoutPageSizeX.parse(null),
        ReportLayoutPageSize.a4,
      );
      expect(
        ReportLayoutPageSizeX.parse('xyz'),
        ReportLayoutPageSize.a4,
      );
    });

    test('80mm / thermal80 / mm80 alias', () {
      expect(
        ReportLayoutPageSizeX.parse('thermal80'),
        ReportLayoutPageSize.thermal80,
      );
      expect(
        ReportLayoutPageSizeX.parse('80mm'),
        ReportLayoutPageSize.thermal80,
      );
      expect(
        ReportLayoutPageSizeX.parse('mm80'),
        ReportLayoutPageSize.thermal80,
      );
    });

    test('thermal80 PDF genişliği ~226.8 pt (80 mm)', () {
      final format = ReportLayoutPageSize.thermal80.pdfFormat;
      expect(format.width, closeTo(226.77, 0.1));
      expect(
        format.width,
        closeTo(ReportLayoutPageSizeX.thermal80WidthPt, 0.001),
      );
      expect(
        format.height,
        closeTo(ReportLayoutPageSizeX.thermal80HeightPt, 0.001),
      );
      expect(format.width, closeTo(80 * PdfPageFormat.mm, 0.001));
      expect(ReportLayoutPageSize.thermal80.isThermalReceipt, isTrue);
      expect(ReportLayoutPageSize.a4.isThermalReceipt, isFalse);
    });

    test('varsayılan A4 / A5 / Letter formatları', () {
      expect(
        ReportLayoutPageSize.a4.pdfFormat.width,
        PdfPageFormat.a4.width,
      );
      expect(
        ReportLayoutPageSize.a5.pdfFormat.width,
        PdfPageFormat.a5.width,
      );
      expect(
        ReportLayoutPageSize.letter.pdfFormat.width,
        PdfPageFormat.letter.width,
      );
    });
  });
}
