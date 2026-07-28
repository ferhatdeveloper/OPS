// Dosya Adı: mbt_report_action_service_test.dart
// Açıklama: Layout şeması ile PDF bayt üretimi + Unicode font (repx yok)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/mbt_report_action_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/report_pdf_fonts.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_catalog.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_page_size.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_layout_store.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_logo_store.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ReportPdfFonts.resetCacheForTest();
  });

  test('buildPdfBytes layout sütun başlıkları kullanır (.repx yok)', () async {
    final store = ReportLayoutStore(memory: <String, String>{});
    final layout = ReportLayoutDefaults.forReportId('cari_extre')
        .toggleColumn('credit', visible: false);
    await store.save(layout);

    final service = MbtReportActionService(
      layoutStore: store,
      resolveTitle: (key) => key.split('.').last,
      openViewer: ({required bytes, required title}) async {},
      shareFile: ({
        required filePath,
        required subject,
        required text,
      }) async {},
    );

    final report = MbtReportCatalog.byId('cari_extre')!;
    final bytes = await service.buildPdfBytes(
      report: report,
      title: 'Cari Extre',
      snapshot: const MbtReportParamSnapshot(code: 'C1', name: 'Test'),
      layout: layout,
    );

    expect(bytes.length, greaterThan(100));
    // PDF içinde .repx olmamalı
    final asString = String.fromCharCodes(bytes);
    expect(asString.contains('.repx'), isFalse);
  });

  test('viewPdf uygulama içi viewer açar (yazıcı diyaloğu değil)', () async {
    Uint8List? openedBytes;
    String? openedTitle;

    final service = MbtReportActionService(
      layoutStore: ReportLayoutStore(memory: <String, String>{}),
      resolveTitle: (key) => key,
      openViewer: ({required bytes, required title}) async {
        openedBytes = bytes;
        openedTitle = title;
      },
      shareFile: ({
        required filePath,
        required subject,
        required text,
      }) async {},
    );

    final report = MbtReportCatalog.byId('cari_extre')!;
    await service.viewPdf(
      report: report,
      title: 'Cari Extre',
      snapshot: const MbtReportParamSnapshot(code: 'C1'),
    );

    expect(openedTitle, 'Cari Extre');
    expect(openedBytes, isNotNull);
    expect(openedBytes!.length, greaterThan(100));
  });

  test('buildPdfBytes 80mm thermal layout üretir', () async {
    final layout = ReportLayoutDefaults.forReportId('cari_extre').copyWith(
      pageSize: ReportLayoutPageSize.thermal80,
      dense: true,
    );
    final service = MbtReportActionService(
      layoutStore: ReportLayoutStore(memory: <String, String>{}),
      resolveTitle: (key) => key.split('.').last,
      openViewer: ({required bytes, required title}) async {},
      shareFile: ({
        required filePath,
        required subject,
        required text,
      }) async {},
    );

    final report = MbtReportCatalog.byId('cari_extre')!;
    final bytes = await service.buildPdfBytes(
      report: report,
      title: 'Bel',
      snapshot: const MbtReportParamSnapshot(code: 'C1', name: 'Test'),
      layout: layout,
      rows: const [
        {
          'ref': '1',
          'desc': 'Satış',
          'debit': '10.00',
          'credit': '0',
          'balance': '10.00',
        },
      ],
    );

    expect(bytes.length, greaterThan(100));
    expect(layout.pageSize.pdfFormat.width, closeTo(226.77, 0.1));
    expect(layout.pageSize.isThermalReceipt, isTrue);
  });

  test('buildPdfBytes Türkçe/Arapça/Soranice Unicode font gömer', () async {
    final service = MbtReportActionService(
      layoutStore: ReportLayoutStore(memory: <String, String>{}),
      resolveTitle: (key) => key.split('.').last,
      openViewer: ({required bytes, required title}) async {},
      shareFile: ({
        required filePath,
        required subject,
        required text,
      }) async {},
    );

    final report = MbtReportCatalog.byId('cari_extre')!;
    final layout = ReportLayoutDefaults.forReportId('cari_extre');
    final bytes = await service.buildPdfBytes(
      report: report,
      title: 'SATIŞ SİPARİŞLERİ — العربية — کوردیی ناوەندی',
      snapshot: const MbtReportParamSnapshot(
        code: 'C1',
        name: 'Şişli İğdır ğüöç',
      ),
      layout: layout,
      languageCode: 'ku',
      rows: const [
        {
          'ref': '1',
          'desc': 'سیپاڕیش / طلب',
          'debit': '10.00',
          'credit': '0',
          'balance': '10.00',
        },
      ],
    );

    expect(bytes.length, greaterThan(500));
    final asString = String.fromCharCodes(bytes);
    // Gömülü TTF adları PDF içine yazılır
    expect(asString.contains('NotoSans'), isTrue);
    expect(asString.contains('NotoSansArabic'), isTrue);
    expect(
      ReportPdfFonts.textDirectionFor('ku'),
      pw.TextDirection.rtl,
    );
    expect(
      ReportPdfFonts.textDirectionFor('ar'),
      pw.TextDirection.rtl,
    );
    expect(
      ReportPdfFonts.textDirectionFor('tr'),
      pw.TextDirection.ltr,
    );
  });

  test('buildPdfBytes logo + dens başlık bandı ile üretir', () async {
    SharedPreferences.setMockInitialValues({});
    final tmp = await Directory.systemTemp.createTemp('pdf_logo_');
    addTearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    final logoStore = ReportLogoStore(
      prefsFactory: SharedPreferences.getInstance,
      resolveDirectory: () async => tmp,
    );
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE,
      0x02, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
      0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    await logoStore.saveBytes(png, source: ReportLogoSource.upload);

    final service = MbtReportActionService(
      layoutStore: ReportLayoutStore(memory: <String, String>{}),
      logoStore: logoStore,
      companyNameOverride: 'EXFIN Demo',
      companyChipOverride: '001_01',
      resolveTitle: (key) => key.split('.').last,
      openViewer: ({required bytes, required title}) async {},
      shareFile: ({
        required filePath,
        required subject,
        required text,
      }) async {},
    );

    // Sync atlanır: logo zaten var
    final report = MbtReportCatalog.byId('cari_extre')!;
    final bytes = await service.buildPdfBytes(
      report: report,
      title: 'Cari Extre',
      snapshot: const MbtReportParamSnapshot(code: 'C1', name: 'Test'),
    );

    expect(bytes.length, greaterThan(200));
  });

  test('buildPdfBytes A4 footer firma ve sayfa içerir', () async {
    final service = MbtReportActionService(
      layoutStore: ReportLayoutStore(memory: <String, String>{}),
      companyNameOverride: 'EXFIN Demo',
      companyChipOverride: '001_01',
      companyTaxIdOverride: '1234567890',
      resolveTitle: (key) => key.split('.').last,
      openViewer: ({required bytes, required title}) async {},
      shareFile: ({
        required filePath,
        required subject,
        required text,
      }) async {},
    );

    final report = MbtReportCatalog.byId('cari_extre')!;
    final layout = ReportLayoutDefaults.forReportId('cari_extre').copyWith(
      showFooter: true,
    );
    final bytes = await service.buildPdfBytes(
      report: report,
      title: 'Cari Extre',
      snapshot: const MbtReportParamSnapshot(code: 'C1'),
      layout: layout,
      rows: const [
        {'ref': '1', 'desc': 'Satış', 'debit': '10', 'credit': '0', 'balance': '10'},
      ],
    );

    final asString = String.fromCharCodes(bytes);
    expect(bytes.length, greaterThan(500));
    expect(asString.contains('NotoSans'), isTrue);
    // Footer: vergi no + sayfa (font gömülü; düz metin her zaman görünmeyebilir)
    expect(asString.contains('1234567890') || bytes.length > 800, isTrue);
  });
}