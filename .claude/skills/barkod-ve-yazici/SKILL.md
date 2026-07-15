---
name: barkod-ve-yazici
description: Use when implementing barcode scanning, Bluetooth printer integration, PDF generation, or document sharing features (WhatsApp, email) for the field sales application
---

# Barkod ve Yazıcı Skill

## Flutter Paketleri

```yaml
# Barkod
mobile_scanner: ^6.0.0

# PDF ve Yazdırma
pdf: ^3.11.0
printing: ^5.13.0

# Paylaşım
share_plus: ^10.0.0

# Dosya işlemleri
path_provider: ^2.1.0
```

## Barkod Okuma (mobile_scanner)

### Kamera ile Barkod Okuma
```dart
class BarcodeScannerWidget extends StatelessWidget {
  final Function(String barcode) onBarcodeDetected;

  const BarcodeScannerWidget({required this.onBarcodeDetected});

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      ),
      onDetect: (capture) {
        final barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          final barcode = barcodes.first.rawValue;
          if (barcode != null) {
            onBarcodeDetected(barcode);
          }
        }
      },
    );
  }
}
```

### Barkod ile Ürün Arama
```dart
Future<Product?> findProductByBarcode(String barcode) async {
  // Önce yerel DB'de ara
  final product = await productRepo.findByBarcode(barcode);
  if (product != null) return product;

  // Bulunamazsa uyarı ver
  return null;
}
```

### Sipariş Ekranında Barkod Kullanımı
```dart
// FAB ile barkod ekranı aç, ürün bulunca sepete ekle
FloatingActionButton(
  onPressed: () async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => BarcodeScanScreen()),
    );
    if (barcode != null) {
      final product = await findProductByBarcode(barcode);
      if (product != null) {
        addToCart(product);
      }
    }
  },
  child: const Icon(Icons.qr_code_scanner),
)
```

## PDF Oluşturma

### Fatura PDF Şablonu
```dart
Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
  final pdf = pw.Document();

  // Logo yükle
  final logoImage = await rootBundle.load('assets/images/logo.jpg');
  final logo = pw.MemoryImage(logoImage.buffer.asUint8List());

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Başlık
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logo, width: 100),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('FATURA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('No: ${invoice.invoiceNumber}'),
                  pw.Text('Tarih: ${formatDate(invoice.date)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Müşteri bilgileri
          _buildCustomerSection(invoice.customer),
          pw.SizedBox(height: 20),

          // Fatura kalemleri tablosu
          _buildItemsTable(invoice.items),
          pw.SizedBox(height: 10),

          // Toplam
          _buildTotals(invoice),
        ],
      ),
    ),
  );

  return pdf.save();
}

pw.Widget _buildItemsTable(List<InvoiceItem> items) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: {
      0: const pw.FlexColumnWidth(3),  // Ürün adı
      1: const pw.FixedColumnWidth(60), // Miktar
      2: const pw.FixedColumnWidth(80), // Birim fiyat
      3: const pw.FixedColumnWidth(60), // İndirim
      4: const pw.FixedColumnWidth(80), // Toplam
    },
    children: [
      // Başlık satırı
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: ['Ürün', 'Miktar', 'Birim Fiyat', 'İndirim', 'Toplam']
          .map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          )).toList(),
      ),
      // Kalemler
      ...items.map((item) => pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.productName)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.quantity} ${item.unit}')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(formatMoney(item.unitPrice))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('%${item.discountRate}')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(formatMoney(item.total))),
        ],
      )),
    ],
  );
}
```

## Bluetooth Yazıcı

### Termal Yazıcı (printing paketi)
```dart
// printing paketi Bluetooth termal yazıcıları destekler
Future<void> printInvoice(Invoice invoice) async {
  final pdfBytes = await generateInvoicePdf(invoice);

  // Yazıcı seçimi ve yazdırma
  await Printing.layoutPdf(
    onLayout: (format) async => pdfBytes,
    name: 'Fatura_${invoice.invoiceNumber}',
  );

  // Veya direkt yazıcı seç
  final printers = await Printing.listPrinters();
  if (printers.isNotEmpty) {
    await Printing.directPrintPdf(
      printer: printers.first,
      onLayout: (format) async => pdfBytes,
    );
  }
}
```

### 80mm Termal Kağıt için Kompakt Format
```dart
Future<Uint8List> generateThermalInvoicePdf(Invoice invoice) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
      margin: const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
      build: (context) => pw.Column(
        children: [
          pw.Center(child: pw.Text(invoice.companyName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Divider(),
          // Kompakt kalem listesi
          ...invoice.items.map((item) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(formatMoney(item.total), style: const pw.TextStyle(fontSize: 8)),
            ],
          )),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOPLAM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(formatMoney(invoice.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}
```

## Belge Paylaşımı

### WhatsApp ile Paylaşım
```dart
Future<void> shareInvoiceViaWhatsApp(Invoice invoice) async {
  // PDF oluştur
  final pdfBytes = await generateInvoicePdf(invoice);

  // Geçici dosyaya kaydet
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/fatura_${invoice.invoiceNumber}.pdf');
  await file.writeAsBytes(pdfBytes);

  // Paylaş (WhatsApp, email, vb.)
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Fatura No: ${invoice.invoiceNumber} - ${invoice.customer.name}',
    subject: 'Fatura ${invoice.invoiceNumber}',
  );
}
```

### E-posta Gönderimi
```dart
Future<void> sendInvoiceByEmail(Invoice invoice) async {
  final pdfBytes = await generateInvoicePdf(invoice);
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/fatura_${invoice.invoiceNumber}.pdf');
  await file.writeAsBytes(pdfBytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'Fatura ${invoice.invoiceNumber} - ${invoice.companyName}',
  );
}
```

## Fatura No Formatı (Türkiye)
```dart
String formatMoney(double amount) {
  // Türk para formatı: 1.234,56 TL
  return NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  ).format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
}
```
