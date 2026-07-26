// Dosya Adı: printer_settings_store_test.dart
// Açıklama: Yazıcı ayarları SharedPreferences load/save testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/printing/model/printer_settings_record.dart';
import 'package:exfin_ops/modules/field_sales/printing/viewmodel/printer_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PrinterSettingsStore', () {
    test('boş prefs yüklenince varsayılan kayıt döner', () async {
      const store = PrinterSettingsStore();
      final record = await store.load();

      expect(record.defaultPrinterName, isEmpty);
      expect(record.defaultPrinterAddress, isEmpty);
      expect(record.labelPrinterName, isEmpty);
      expect(record.labelPrinterAddress, isEmpty);
      expect(record.showPreview, isTrue);
      expect(record.paperWidth, 58);
      expect(record.autoPrint, isFalse);
      expect(record.footerMessage, PrinterSettingsRecord.defaultFooter);
      expect(record.feedbackUrl, PrinterSettingsRecord.defaultFeedbackUrl);
      expect(record.defaultSlipTemplate, 'standard');
      expect(record.defaultLabelTemplate, 'product_small');
    });

    test('kaydet ve yükle tüm alanları korur', () async {
      const store = PrinterSettingsStore();
      await store.save(
        const PrinterSettingsRecord(
          defaultPrinterName: 'RP58',
          defaultPrinterAddress: '00:11:22:33:44:55',
          labelPrinterName: 'LabelX',
          labelPrinterAddress: 'AA:BB:CC:DD:EE:FF',
          showPreview: false,
          paperWidth: 80,
          autoPrint: true,
          footerMessage: 'Teşekkürler',
          feedbackUrl: 'https://exfinerp.com/fb',
          defaultSlipTemplate: 'minimal',
          defaultLabelTemplate: 'shelf_large',
        ),
      );

      final loaded = await store.load();
      expect(loaded.defaultPrinterName, 'RP58');
      expect(loaded.defaultPrinterAddress, '00:11:22:33:44:55');
      expect(loaded.labelPrinterName, 'LabelX');
      expect(loaded.labelPrinterAddress, 'AA:BB:CC:DD:EE:FF');
      expect(loaded.showPreview, isFalse);
      expect(loaded.paperWidth, 80);
      expect(loaded.autoPrint, isTrue);
      expect(loaded.footerMessage, 'Teşekkürler');
      expect(loaded.feedbackUrl, 'https://exfinerp.com/fb');
      expect(loaded.defaultSlipTemplate, 'minimal');
      expect(loaded.defaultLabelTemplate, 'shelf_large');
    });

    test('kaydetme trim uygular; boş yazıcı adresini temizler', () async {
      const store = PrinterSettingsStore();
      await store.save(
        const PrinterSettingsRecord(
          defaultPrinterName: '  RP58  ',
          defaultPrinterAddress: '  ',
          footerMessage: '  trim  ',
        ),
      );

      final loaded = await store.load();
      expect(loaded.defaultPrinterName, isEmpty);
      expect(loaded.defaultPrinterAddress, isEmpty);
      expect(loaded.footerMessage, 'trim');
    });

    test('PrintSettingsService ile aynı prefs anahtarlarından okur', () async {
      SharedPreferences.setMockInitialValues({
        PrinterSettingsStore.prefsDefaultPrinterName: 'Legacy',
        PrinterSettingsStore.prefsDefaultPrinterAddress: '11:22:33:44:55:66',
        PrinterSettingsStore.prefsShowPreview: false,
        PrinterSettingsStore.prefsPaperWidth: 80,
        PrinterSettingsStore.prefsAutoPrint: true,
        PrinterSettingsStore.prefsFooterMessage: 'Legacy footer',
        PrinterSettingsStore.prefsFeedbackUrl: 'https://legacy.example',
        PrinterSettingsStore.prefsDefaultSlipTemplate: 'minimal',
        PrinterSettingsStore.prefsDefaultLabelTemplate: 'shelf_large',
        PrinterSettingsStore.prefsLabelPrinterName: 'L1',
        PrinterSettingsStore.prefsLabelPrinterAddress: '99:88:77:66:55:44',
      });

      const store = PrinterSettingsStore();
      final loaded = await store.load();
      expect(loaded.defaultPrinterName, 'Legacy');
      expect(loaded.defaultPrinterAddress, '11:22:33:44:55:66');
      expect(loaded.showPreview, isFalse);
      expect(loaded.paperWidth, 80);
      expect(loaded.autoPrint, isTrue);
      expect(loaded.footerMessage, 'Legacy footer');
      expect(loaded.feedbackUrl, 'https://legacy.example');
      expect(loaded.defaultSlipTemplate, 'minimal');
      expect(loaded.defaultLabelTemplate, 'shelf_large');
      expect(loaded.labelPrinterName, 'L1');
      expect(loaded.labelPrinterAddress, '99:88:77:66:55:44');
    });

    test('geçersiz paperWidth varsayılana düşer', () {
      expect(PrinterSettingsRecord.normalizePaperWidth(40), 58);
      expect(PrinterSettingsRecord.normalizePaperWidth(58), 58);
      expect(PrinterSettingsRecord.normalizePaperWidth(80), 80);
    });
  });
}
