import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../modules/field_sales/invoices/model/invoice_model.dart';
import '../core/config/regional_config.dart';

enum PrintFormat { 
  thermal80mm, 
  a5, 
  a4 
}

class InvoicePrintService {
  static final InvoicePrintService _instance = InvoicePrintService._internal();
  factory InvoicePrintService() => _instance;
  InvoicePrintService._internal();

  Future<void> printInvoice(InvoiceModel invoice, List<InvoiceItemModel> items, {PrintFormat format = PrintFormat.thermal80mm}) async {
    final pdf = pw.Document();
    
    PdfPageFormat pageFormat;
    switch (format) {
      case PrintFormat.thermal80mm:
        pageFormat = const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);
        break;
      case PrintFormat.a5:
        pageFormat = PdfPageFormat.a5;
        break;
      case PrintFormat.a4:
        pageFormat = PdfPageFormat.a4;
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return [
            _buildHeader(invoice),
            pw.Divider(),
            _buildItemsTable(items),
            pw.Divider(),
            _buildFooter(invoice),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Fatura_${invoice.id}',
    );
  }

  pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('EXFINSOFT - SAHA SATIS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text('Tarih: ${invoice.invoiceDate.toString()}'),
        pw.Text('Fatura No: ${invoice.id}'),
        pw.Text('Tip: ${invoice.invoiceType ?? 'Satis'}'),
        pw.SizedBox(height: 10),
        pw.Text('MUSTERI BILGISI:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Musteri: ${invoice.customerId}'),
        pw.SizedBox(height: 5),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<InvoiceItemModel> items) {
    return pw.TableHelper.fromTextArray(
      headers: ['Urun', 'Adet', 'Fiyat', 'Toplam'],
      data: items.map((item) => [
        item.productName ?? '',
        item.quantity.toStringAsFixed(0),
        item.price.toStringAsFixed(2),
        item.totalAmount.toStringAsFixed(2),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildFooter(InvoiceModel invoice) {
    final currency = RegionalConfig.currencySymbol;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(height: 10),
        _buildSummaryRow('Ara Toplam:', '${invoice.totalAmount.toStringAsFixed(2)} $currency'),
        _buildSummaryRow('KDV:', '0.00 $currency'), // Mock VAT for now
        pw.Divider(),
        _buildSummaryRow('GENEL TOPLAM:', '${invoice.totalAmount.toStringAsFixed(2)} $currency', isBold: true),
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text('Tesekkur Ederiz', style: const pw.TextStyle(fontSize: 10))),
        if (RegionalConfig.isIraqRegion) 
          pw.Center(child: pw.Text('Iraq Region Sales Copy', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.SizedBox(width: 10),
        pw.Container(
          width: 80,
          child: pw.Text(value, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }
}
