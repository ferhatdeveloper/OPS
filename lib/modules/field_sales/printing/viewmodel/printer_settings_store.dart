// Dosya Adı: printer_settings_store.dart
// Açıklama: Yazıcı ayarları SharedPreferences kalıcılık katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:shared_preferences/shared_preferences.dart';

import '../model/printer_settings_record.dart';

/// {@template printer_settings_store}
/// Yazıcı / fiş yazdırma tercihlerini SharedPreferences ile okur / yazar.
/// Anahtarlar `PrintSettingsService` ile birebir aynıdır (geriye uyum).
///
/// Kullanım örneği:
/// ```dart
/// const store = PrinterSettingsStore();
/// final record = await store.load();
/// await store.save(record.copyWith(paperWidth: 80));
/// ```
/// {@endtemplate}
class PrinterSettingsStore {
  /// [prefsDefaultPrinterName]: Varsayılan yazıcı adı
  static const String prefsDefaultPrinterName = 'default_printer_name';

  /// [prefsDefaultPrinterAddress]: Varsayılan yazıcı adresi
  static const String prefsDefaultPrinterAddress = 'default_printer_address';

  /// [prefsLabelPrinterName]: Etiket yazıcısı adı
  static const String prefsLabelPrinterName = 'label_printer_name';

  /// [prefsLabelPrinterAddress]: Etiket yazıcısı adresi
  static const String prefsLabelPrinterAddress = 'label_printer_address';

  /// [prefsShowPreview]: Ön izleme
  static const String prefsShowPreview = 'show_print_preview';

  /// [prefsPaperWidth]: Kağıt genişliği
  static const String prefsPaperWidth = 'print_paper_width';

  /// [prefsAutoPrint]: Otomatik yazdır
  static const String prefsAutoPrint = 'print_auto_after_save';

  /// [prefsFooterMessage]: Fiş altı mesajı
  static const String prefsFooterMessage = 'print_footer_message';

  /// [prefsFeedbackUrl]: Feedback URL
  static const String prefsFeedbackUrl = 'print_feedback_url';

  /// [prefsDefaultSlipTemplate]: Fiş şablonu
  static const String prefsDefaultSlipTemplate = 'print_default_slip_template';

  /// [prefsDefaultLabelTemplate]: Etiket şablonu
  static const String prefsDefaultLabelTemplate =
      'print_default_label_template';

  /// {@macro printer_settings_store}
  const PrinterSettingsStore();

  /// {@template printer_settings_store_load}
  /// Yerel yazıcı ayarlarını yükler; yoksa varsayılan döner.
  ///
  /// Dönüş değeri:
  /// - [PrinterSettingsRecord]: Yüklenen kayıt
  /// {@endtemplate}
  Future<PrinterSettingsRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterSettingsRecord(
      defaultPrinterName: prefs.getString(prefsDefaultPrinterName) ?? '',
      defaultPrinterAddress: prefs.getString(prefsDefaultPrinterAddress) ?? '',
      labelPrinterName: prefs.getString(prefsLabelPrinterName) ?? '',
      labelPrinterAddress: prefs.getString(prefsLabelPrinterAddress) ?? '',
      showPreview: prefs.getBool(prefsShowPreview) ?? true,
      paperWidth: PrinterSettingsRecord.normalizePaperWidth(
        prefs.getInt(prefsPaperWidth),
      ),
      autoPrint: prefs.getBool(prefsAutoPrint) ?? false,
      footerMessage: prefs.getString(prefsFooterMessage) ??
          PrinterSettingsRecord.defaultFooter,
      feedbackUrl: prefs.getString(prefsFeedbackUrl) ??
          PrinterSettingsRecord.defaultFeedbackUrl,
      defaultSlipTemplate:
          prefs.getString(prefsDefaultSlipTemplate) ?? 'standard',
      defaultLabelTemplate:
          prefs.getString(prefsDefaultLabelTemplate) ?? 'product_small',
    );
  }

  /// {@template printer_settings_store_save}
  /// Yazıcı ayarlarını SharedPreferences'a yazar.
  /// Boş yazıcı adı/adresi ilgili anahtarları temizler.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek ayarlar
  /// {@endtemplate}
  Future<void> save(PrinterSettingsRecord record) async {
    final prefs = await SharedPreferences.getInstance();

    await _setOrRemovePrinter(
      prefs,
      nameKey: prefsDefaultPrinterName,
      addressKey: prefsDefaultPrinterAddress,
      name: record.defaultPrinterName,
      address: record.defaultPrinterAddress,
    );
    await _setOrRemovePrinter(
      prefs,
      nameKey: prefsLabelPrinterName,
      addressKey: prefsLabelPrinterAddress,
      name: record.labelPrinterName,
      address: record.labelPrinterAddress,
    );

    await prefs.setBool(prefsShowPreview, record.showPreview);
    await prefs.setInt(
      prefsPaperWidth,
      PrinterSettingsRecord.normalizePaperWidth(record.paperWidth),
    );
    await prefs.setBool(prefsAutoPrint, record.autoPrint);
    await prefs.setString(
      prefsFooterMessage,
      record.footerMessage.trim().isEmpty
          ? PrinterSettingsRecord.defaultFooter
          : record.footerMessage.trim(),
    );
    await prefs.setString(
      prefsFeedbackUrl,
      record.feedbackUrl.trim().isEmpty
          ? PrinterSettingsRecord.defaultFeedbackUrl
          : record.feedbackUrl.trim(),
    );
    await prefs.setString(
      prefsDefaultSlipTemplate,
      record.defaultSlipTemplate.trim().isEmpty
          ? 'standard'
          : record.defaultSlipTemplate.trim(),
    );
    await prefs.setString(
      prefsDefaultLabelTemplate,
      record.defaultLabelTemplate.trim().isEmpty
          ? 'product_small'
          : record.defaultLabelTemplate.trim(),
    );
  }

  /// {@template printer_settings_store_set_or_remove_printer}
  /// Adres boşsa yazıcı anahtarlarını siler; doluysa trim ile yazar.
  /// {@endtemplate}
  Future<void> _setOrRemovePrinter(
    SharedPreferences prefs, {
    required String nameKey,
    required String addressKey,
    required String name,
    required String address,
  }) async {
    final trimmedAddress = address.trim();
    final trimmedName = name.trim();
    if (trimmedAddress.isEmpty) {
      await prefs.remove(nameKey);
      await prefs.remove(addressKey);
      return;
    }
    await prefs.setString(nameKey, trimmedName);
    await prefs.setString(addressKey, trimmedAddress);
  }
}
