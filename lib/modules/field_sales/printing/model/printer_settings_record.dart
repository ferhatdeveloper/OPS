// Dosya Adı: printer_settings_record.dart
// Açıklama: Yazıcı / fiş yazdırma SharedPreferences kayıt modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template printer_settings_record}
/// Varsayılan yazıcı, etiket yazıcısı ve yazdırma tercihleri.
///
/// Kullanım örneği:
/// ```dart
/// const record = PrinterSettingsRecord(
///   defaultPrinterName: 'RP58',
///   defaultPrinterAddress: '00:11:22:33:44:55',
///   paperWidth: 58,
///   showPreview: true,
/// );
/// ```
/// {@endtemplate}
class PrinterSettingsRecord {
  /// Varsayılan fiş altı mesajı
  static const String defaultFooter =
      'Bizi tercih ettiğiniz için teşekkürler!';

  /// Varsayılan feedback URL
  static const String defaultFeedbackUrl = 'https://exfinerp.com/feedback';

  /// Desteklenen kağıt genişlikleri (mm)
  static const List<int> allowedPaperWidths = [58, 80];

  /// [defaultPrinterName]: Varsayılan BT yazıcı adı
  final String defaultPrinterName;

  /// [defaultPrinterAddress]: Varsayılan BT yazıcı adresi
  final String defaultPrinterAddress;

  /// [labelPrinterName]: Etiket yazıcısı adı
  final String labelPrinterName;

  /// [labelPrinterAddress]: Etiket yazıcısı adresi
  final String labelPrinterAddress;

  /// [showPreview]: Yazdırma ön izleme
  final bool showPreview;

  /// [paperWidth]: Kağıt genişliği (58 veya 80)
  final int paperWidth;

  /// [autoPrint]: Kayıt sonrası otomatik yazdır
  final bool autoPrint;

  /// [footerMessage]: Fiş altı mesajı
  final String footerMessage;

  /// [feedbackUrl]: Değerlendirme URL / QR
  final String feedbackUrl;

  /// [defaultSlipTemplate]: Fiş şablonu (standard / minimal)
  final String defaultSlipTemplate;

  /// [defaultLabelTemplate]: Etiket şablonu
  final String defaultLabelTemplate;

  /// {@macro printer_settings_record}
  const PrinterSettingsRecord({
    this.defaultPrinterName = '',
    this.defaultPrinterAddress = '',
    this.labelPrinterName = '',
    this.labelPrinterAddress = '',
    this.showPreview = true,
    this.paperWidth = 58,
    this.autoPrint = false,
    this.footerMessage = defaultFooter,
    this.feedbackUrl = defaultFeedbackUrl,
    this.defaultSlipTemplate = 'standard',
    this.defaultLabelTemplate = 'product_small',
  });

  /// {@template printer_settings_record_normalize_paper_width}
  /// Desteklenmeyen genişliği 58 mm varsayılanına düşürür.
  ///
  /// Parametreler:
  /// - [width]: Ham kağıt genişliği
  ///
  /// Dönüş değeri:
  /// - [int]: 58 veya 80
  /// {@endtemplate}
  static int normalizePaperWidth(int? width) {
    if (width != null && allowedPaperWidths.contains(width)) {
      return width;
    }
    return 58;
  }

  /// {@template printer_settings_record_has_default_printer}
  /// Varsayılan yazıcı adresi dolu mu.
  /// {@endtemplate}
  bool get hasDefaultPrinter => defaultPrinterAddress.trim().isNotEmpty;

  /// {@template printer_settings_record_has_label_printer}
  /// Etiket yazıcısı adresi dolu mu.
  /// {@endtemplate}
  bool get hasLabelPrinter => labelPrinterAddress.trim().isNotEmpty;

  /// {@template printer_settings_record_copy_with}
  /// Kısmi güncelleme.
  /// {@endtemplate}
  PrinterSettingsRecord copyWith({
    String? defaultPrinterName,
    String? defaultPrinterAddress,
    String? labelPrinterName,
    String? labelPrinterAddress,
    bool? showPreview,
    int? paperWidth,
    bool? autoPrint,
    String? footerMessage,
    String? feedbackUrl,
    String? defaultSlipTemplate,
    String? defaultLabelTemplate,
  }) {
    return PrinterSettingsRecord(
      defaultPrinterName: defaultPrinterName ?? this.defaultPrinterName,
      defaultPrinterAddress:
          defaultPrinterAddress ?? this.defaultPrinterAddress,
      labelPrinterName: labelPrinterName ?? this.labelPrinterName,
      labelPrinterAddress: labelPrinterAddress ?? this.labelPrinterAddress,
      showPreview: showPreview ?? this.showPreview,
      paperWidth: paperWidth ?? this.paperWidth,
      autoPrint: autoPrint ?? this.autoPrint,
      footerMessage: footerMessage ?? this.footerMessage,
      feedbackUrl: feedbackUrl ?? this.feedbackUrl,
      defaultSlipTemplate: defaultSlipTemplate ?? this.defaultSlipTemplate,
      defaultLabelTemplate: defaultLabelTemplate ?? this.defaultLabelTemplate,
    );
  }
}
