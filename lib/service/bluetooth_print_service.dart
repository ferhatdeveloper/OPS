import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../modules/field_sales/invoices/model/invoice_model.dart';
import '../modules/field_sales/collections/model/collection_model.dart';
import '../core/config/regional_config.dart';
import 'print_settings_service.dart';

class BluetoothPrintService {
  static final BluetoothPrintService _instance = BluetoothPrintService._internal();
  factory BluetoothPrintService() => _instance;
  BluetoothPrintService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  Future<bool?> isConnected() async {
    return await _bluetooth.isConnected;
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      if (await _bluetooth.isConnected ?? false) {
        await _bluetooth.disconnect();
      }
      await _bluetooth.connect(device);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
  }

  Future<void> printInvoice(InvoiceModel invoice, List<InvoiceItemModel> items, {String? templateId}) async {
    if (!(await _bluetooth.isConnected ?? false)) return;

    final String finalTemplateId = templateId ?? await PrintSettingsService().getDefaultSlipTemplate();
    
    if (finalTemplateId == "minimal") {
      await _printMinimalSlip(invoice, items);
    } else {
      await _printStandardSlip(invoice, items);
    }
  }

  Future<void> _printStandardSlip(InvoiceModel invoice, List<InvoiceItemModel> items) async {
    final currency = RegionalConfig.currencySymbol;
    final printSettings = PrintSettingsService();
    
    final int paperWidth = await printSettings.getPaperWidth();
    final String footerMsg = await printSettings.getFooterMessage();
    final String feedbackUrl = await printSettings.getFeedbackUrl();

    // Calculations
    double subTotal = 0;
    double totalVat = 0;
    for (var item in items) {
      subTotal += item.quantity * item.price;
      totalVat += item.vatAmount;
    }
    double grandTotal = subTotal + totalVat;

    // Header
    _bluetooth.printNewLine();
    _bluetooth.printCustom("EXFINSOFT", 3, 1); // Large Center
    _bluetooth.printCustom("SAHA SATIS SISTEMI", 1, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printLeftRight("Tarih:", invoice.invoiceDate.toString().substring(0, 16), 1);
    _bluetooth.printLeftRight("Fatura No:", invoice.id, 1);
    _bluetooth.printLeftRight("Vezne/Depo:", "Merkez", 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printCustom("MUSTERI BILGISI:", 1, 0);
    _bluetooth.printCustom("${invoice.customerId}", 2, 0); // Bold/Medium customer ID
    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Table Header
    _bluetooth.printLeftRight("URUN", "TUTAR", 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Items
    for (var item in items) {
      _bluetooth.printCustom("${item.productName}", 1, 0);
      String qtyPrice = "${item.quantity.toStringAsFixed(0)} x ${item.price.toStringAsFixed(2)}";
      String lineTotal = "${item.totalAmount.toStringAsFixed(2)} $currency";
      _bluetooth.printLeftRight("  $qtyPrice", lineTotal, 1);
    }

    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Totals Section
    _bluetooth.printLeftRight("ARA TOPLAM:", "${subTotal.toStringAsFixed(2)} $currency", 1);
    _bluetooth.printLeftRight("KDV TOPLAM:", "${totalVat.toStringAsFixed(2)} $currency", 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Grand Total (Large)
    _bluetooth.printCustom("GENEL TOPLAM", 1, 1);
    _bluetooth.printCustom("${grandTotal.toStringAsFixed(2)} $currency", 2, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom(footerMsg, 1, 1);
    
    if (RegionalConfig.isIraqRegion) {
       _bluetooth.printCustom("Iraq Region Sales Support", 1, 1);
    }

    _bluetooth.printNewLine();
    _bluetooth.printCustom("Bizi Degerlendirin", 1, 1);
    try {
      _bluetooth.printQRcode(feedbackUrl, 200, 200, 1);
    } catch(e) {
      _bluetooth.printCustom(feedbackUrl, 1, 1);
    }
    _bluetooth.printNewLine();

    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    
    _bluetooth.paperCut(); 
  }

  Future<void> printTest() async {
    if (!(await _bluetooth.isConnected ?? false)) return;

    _bluetooth.printNewLine();
    _bluetooth.printCustom("EXFINSOFT", 3, 1); // Size 3 (Large)
    _bluetooth.printCustom("YAZICI TEST CIKTISI", 2, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom("Durum: OK", 1, 1);
    _bluetooth.printCustom("Tarih: ${DateTime.now().toString().substring(0, 16)}", 1, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> printLabel(String productName, String productCode, String price, {String? labelType}) async {
    if (!(await _bluetooth.isConnected ?? false)) return;
    
    final String type = labelType ?? await PrintSettingsService().getDefaultLabelTemplate();

    if (type == "shelf_large") {
      await _printShelfLabel(productName, productCode, price);
    } else {
      await _printProductLabel(productName, productCode, price);
    }
  }

  Future<void> _printProductLabel(String productName, String productCode, String price) async {
    _bluetooth.printNewLine();
    _bluetooth.printCustom(productName, 2, 1);
    _bluetooth.printCustom("Kod: $productCode", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("$price ${RegionalConfig.currencySymbol}", 3, 1);
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> _printShelfLabel(String productName, String productCode, String price) async {
    _bluetooth.printNewLine();
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom(productName, 3, 1);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("FIYAT: $price ${RegionalConfig.currencySymbol}", 2, 1);
    _bluetooth.printCustom("KOD: $productCode", 1, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> _printMinimalSlip(InvoiceModel invoice, List<InvoiceItemModel> items) async {
    final currency = RegionalConfig.currencySymbol;
    _bluetooth.printCustom("EXFINSOFT", 2, 1);
    _bluetooth.printCustom("ID: ${invoice.id}", 1, 1);
    _bluetooth.printCustom("-------------------", 1, 1);
    double grandTotal = 0;
    for (var item in items) {
      _bluetooth.printLeftRight("${item.productName} x${item.quantity.toStringAsFixed(0)}", item.totalAmount.toStringAsFixed(2), 1);
      grandTotal += item.totalAmount;
    }
    _bluetooth.printCustom("-------------------", 1, 1);
    _bluetooth.printLeftRight("TOPLAM:", "${grandTotal.toStringAsFixed(2)} $currency", 2);
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> printCollection(CollectionModel collection) async {
    if (!(await _bluetooth.isConnected ?? false)) return;

    final currency = RegionalConfig.currencySymbol;
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom("TAHSILAT MAKBUZU", 2, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printLeftRight("Tarih:", collection.collectionDate.toString().substring(0, 16), 1);
    _bluetooth.printLeftRight("Makbuz No:", collection.id, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printCustom("MUSTERI BILGISI:", 1, 0);
    _bluetooth.printCustom(collection.customerId, 2, 0);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printLeftRight("ODEME TIPI:", collection.paymentType, 1);
    if (collection.bankName != null) {
      _bluetooth.printLeftRight("BANKA:", collection.bankName!, 1);
    }
    if (collection.checkNumber != null) {
      _bluetooth.printLeftRight("CEK NO:", collection.checkNumber!, 1);
    }
    
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printLeftRight("TUTAR:", "${collection.amount.toStringAsFixed(2)} $currency", 2);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    if (collection.notes != null && collection.notes!.isNotEmpty) {
      _bluetooth.printCustom("NOT: ${collection.notes}", 1, 0);
      _bluetooth.printCustom("--------------------------------", 1, 1);
    }
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom("ODEME ALINMISTIR", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }
}
