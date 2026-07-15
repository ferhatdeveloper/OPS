import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class LabelPrinterService {
  static final LabelPrinterService _instance = LabelPrinterService._internal();
  factory LabelPrinterService() => _instance;
  LabelPrinterService._internal();

  /// Prints a product label with barcode
  Future<void> printProductLabel(String productId, String productName, double price) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm), // Label size (50x30mm)
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Kod: $productId', style: const pw.TextStyle(fontSize: 8)),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: productId,
                    width: 80,
                    height: 15,
                  ),
                  pw.Text('${price.toStringAsFixed(2)} TL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Prints a shelf label (larger format)
  Future<void> printShelfLabel(String productId, String productName, double price, String unit) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 40 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(productName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: productId,
                  width: 150,
                  height: 30,
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Birim: $unit', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('${price.toStringAsFixed(2)} TL', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
