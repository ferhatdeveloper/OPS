import 'package:shared_preferences/shared_preferences.dart';

class PrintSettingsService {
  static const String _keyDefaultPrinterName = 'default_printer_name';
  static const String _keyDefaultPrinterAddress = 'default_printer_address';
  static const String _keyLabelPrinterName = 'label_printer_name';
  static const String _keyLabelPrinterAddress = 'label_printer_address';
  static const String _keyShowPreview = 'show_print_preview';
  static const String _keyPaperWidth = 'print_paper_width'; // 58 or 80
  static const String _keyAutoPrint = 'print_auto_after_save';
  static const String _keyFooterMessage = 'print_footer_message';
  static const String _keyFeedbackUrl = 'print_feedback_url';
  static const String _keyDefaultSlipTemplateId = 'print_default_slip_template';
  static const String _keyDefaultLabelTemplateId = 'print_default_label_template';

  static final PrintSettingsService _instance = PrintSettingsService._internal();
  factory PrintSettingsService() => _instance;
  PrintSettingsService._internal();

  Future<void> setDefaultPrinter(String? name, String? address) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || address == null) {
      await prefs.remove(_keyDefaultPrinterName);
      await prefs.remove(_keyDefaultPrinterAddress);
    } else {
      await prefs.setString(_keyDefaultPrinterName, name);
      await prefs.setString(_keyDefaultPrinterAddress, address);
    }
  }

  Future<Map<String, String?>> getDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyDefaultPrinterName),
      'address': prefs.getString(_keyDefaultPrinterAddress),
    };
  }

  Future<void> setLabelPrinter(String? name, String? address) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || address == null) {
      await prefs.remove(_keyLabelPrinterName);
      await prefs.remove(_keyLabelPrinterAddress);
    } else {
      await prefs.setString(_keyLabelPrinterName, name);
      await prefs.setString(_keyLabelPrinterAddress, address);
    }
  }

  Future<Map<String, String?>> getLabelPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyLabelPrinterName),
      'address': prefs.getString(_keyLabelPrinterAddress),
    };
  }

  Future<void> setShowPreview(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPreview, show);
  }

  Future<bool> getShowPreview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowPreview) ?? true; // Default to true
  }

  Future<void> setPaperWidth(int width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPaperWidth, width);
  }

  Future<int> getPaperWidth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPaperWidth) ?? 58;
  }

  Future<void> setAutoPrint(bool auto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPrint, auto);
  }

  Future<bool> getAutoPrint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPrint) ?? false;
  }

  Future<void> setFooterMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFooterMessage, message);
  }

  Future<String> getFooterMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFooterMessage) ?? "Bizi tercih ettiğiniz için teşekkürler!";
  }

  Future<void> setFeedbackUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFeedbackUrl, url);
  }

  Future<String> getFeedbackUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFeedbackUrl) ?? "https://exfinerp.com/feedback";
  }

  Future<void> setDefaultSlipTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultSlipTemplateId, templateId);
  }

  Future<String> getDefaultSlipTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultSlipTemplateId) ?? "standard";
  }

  Future<void> setDefaultLabelTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultLabelTemplateId, templateId);
  }

  Future<String> getDefaultLabelTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultLabelTemplateId) ?? "product_small";
  }
}
