// Dosya Adı: printer_settings_screen_test.dart
// Açıklama: Yazıcı ayarları dens ekranı prefs load/save widget testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/printing/view/printer_settings_screen.dart';
import 'package:exfin_ops/modules/field_sales/printing/viewmodel/printer_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      PrinterSettingsStore.prefsDefaultPrinterName: 'RP58',
      PrinterSettingsStore.prefsDefaultPrinterAddress: '00:11:22:33:44:55',
      PrinterSettingsStore.prefsPaperWidth: 80,
      PrinterSettingsStore.prefsShowPreview: false,
      PrinterSettingsStore.prefsAutoPrint: true,
    });
  });

  testWidgets('prefs yüklenince dens alanlar dolar', (tester) async {
    await pumpStubWithL10n(tester, const PrinterSettingsScreen());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Yazıcı Ayarları'), findsWidgets);
    expect(find.text('RP58'), findsOneWidget);
    expect(find.text('00:11:22:33:44:55'), findsOneWidget);
  });

  testWidgets('Kaydet prefs yazar', (tester) async {
    await pumpStubWithL10n(tester, const PrinterSettingsScreen());
    await tester.pump(const Duration(milliseconds: 50));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NewPrinter');
    await tester.enterText(fields.at(1), 'AA:BB:CC:DD:EE:FF');
    await tester.pump();

    final save = find.text('KAYDET');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PrinterSettingsStore.prefsDefaultPrinterName),
      'NewPrinter',
    );
    expect(
      prefs.getString(PrinterSettingsStore.prefsDefaultPrinterAddress),
      'AA:BB:CC:DD:EE:FF',
    );
  });
}
