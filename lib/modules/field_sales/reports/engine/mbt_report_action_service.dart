// Dosya Adı: mbt_report_action_service.dart
// Açıklama: Rapor aksiyonları — Unicode dens PDF (TR/AR/Soranice, repx yok)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../service/database_service.dart';
import '../../companies/viewmodel/active_company_store.dart';
import '../model/mbt_report_definition.dart';
import '../model/report_layout.dart';
import '../model/report_layout_column.dart';
import '../model/report_layout_defaults.dart';
import '../model/report_layout_page_size.dart';
import '../model/report_pdf_viewer_args.dart';
import '../view/report_pdf_viewer_screen.dart';
import '../viewmodel/report_layout_store.dart';
import '../viewmodel/report_logo_remote_sync.dart';
import '../viewmodel/report_logo_store.dart';
import 'report_pdf_brand.dart';
import 'report_pdf_fonts.dart';

/// {@template mbt_report_param_snapshot}
/// Parametre formunun anlık görüntüsü (PDF başlığı için).
/// {@endtemplate}
class MbtReportParamSnapshot {
  /// [dateFrom]: Başlangıç
  final DateTime? dateFrom;

  /// [dateTo]: Bitiş
  final DateTime? dateTo;

  /// [code]: Kod
  final String code;

  /// [name]: Ad
  final String name;

  /// [code2]: Kod 2 (stok aralık bitiş)
  final String code2;

  /// [name2]: Ad 2
  final String name2;

  /// [warehouse]: Ambar filtresi
  final String warehouse;

  /// [gtZero]: Bakiye > 0
  final bool gtZero;

  /// [ltZero]: Bakiye < 0
  final bool ltZero;

  /// [eqZero]: Bakiye = 0
  final bool eqZero;

  /// [extraLines]: Ek satırlar (etiket: değer)
  final Map<String, String> extraLines;

  const MbtReportParamSnapshot({
    this.dateFrom,
    this.dateTo,
    this.code = '',
    this.name = '',
    this.code2 = '',
    this.name2 = '',
    this.warehouse = '',
    this.gtZero = false,
    this.ltZero = false,
    this.eqZero = false,
    this.extraLines = const {},
  });
}

/// {@template mbt_report_share_fn}
/// Dosya paylaşım inject noktası (test).
/// {@endtemplate}
typedef MbtReportShareFn = Future<void> Function({
  required String filePath,
  required String subject,
  required String text,
});

/// {@template mbt_report_title_resolver}
/// l10n çözümleyici (PDF sütun başlıkları).
/// {@endtemplate}
typedef MbtReportTitleResolver = String Function(String key);

/// {@template mbt_report_open_viewer_fn}
/// Uygulama içi PDF viewer açma inject noktası (test).
/// {@endtemplate}
typedef MbtReportOpenViewerFn = Future<void> Function({
  required Uint8List bytes,
  required String title,
});

/// {@template mbt_report_action_service}
/// Layout şeması → dens PDF · görüntüle · paylaş · e-posta.
///
/// Kullanım örneği:
/// ```dart
/// await MbtReportActionService().viewPdf(
///   report: def,
///   title: 'Cari Extre',
///   snapshot: snapshot,
/// );
/// ```
/// {@endtemplate}
class MbtReportActionService {
  /// [_shareFile]: share_plus inject
  final MbtReportShareFn _shareFile;

  /// [_openViewer]: Uygulama içi PDF viewer inject
  final MbtReportOpenViewerFn _openViewer;

  /// [layoutStore]: Dizayn yükleme
  final ReportLayoutStore layoutStore;

  /// [logoStore]: Firma logo önbelleği
  final ReportLogoStore logoStore;

  /// [logoSync]: Merkez branding sync (opsiyonel inject)
  final ReportLogoRemoteSync? logoSync;

  /// [resolveTitle]: Sütun / metin l10n (null → key)
  final MbtReportTitleResolver? resolveTitle;

  /// [companyNameOverride]: Test için firma adı
  final String? companyNameOverride;

  /// [companyChipOverride]: Test için `001_01`
  final String? companyChipOverride;

  /// [companyTaxIdOverride]: Test / inject vergi no (VKN)
  final String? companyTaxIdOverride;

  /// [resolveCompanyTaxId]: Aktif firmadan vergi no (opsiyonel)
  final Future<String?> Function()? resolveCompanyTaxId;

  /// {@macro mbt_report_action_service}
  MbtReportActionService({
    MbtReportShareFn? shareFile,
    MbtReportOpenViewerFn? openViewer,
    ReportLayoutStore? layoutStore,
    ReportLogoStore? logoStore,
    this.logoSync,
    this.resolveTitle,
    this.companyNameOverride,
    this.companyChipOverride,
    this.companyTaxIdOverride,
    this.resolveCompanyTaxId,
  })  : _shareFile = shareFile ?? _defaultShare,
        _openViewer = openViewer ?? _defaultOpenViewer,
        layoutStore = layoutStore ?? ReportLayoutStore(),
        logoStore = logoStore ?? ReportLogoStore();

  /// {@template mbt_report_action_service_default_open_viewer}
  /// AppNavigator ile dens PDF viewer route’unu açar.
  ///
  /// Parametreler:
  /// - [bytes]: PDF
  /// - [title]: Başlık
  /// {@endtemplate}
  static Future<void> _defaultOpenViewer({
    required Uint8List bytes,
    required String title,
  }) async {
    final nav = AppNavigator.state;
    if (nav == null) return;
    await nav.pushNamed(
      ReportPdfViewerScreen.routeName,
      arguments: ReportPdfViewerArgs(bytes: bytes, title: title),
    );
  }

  static Future<void> _defaultShare({
    required String filePath,
    required String subject,
    required String text,
  }) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
      text: text,
    );
  }

  String _t(String key) {
    final fn = resolveTitle;
    if (fn == null) return key;
    return fn(key);
  }

  PdfPageFormat _pageFormat(ReportLayoutPageSize size) => size.pdfFormat;

  /// {@template mbt_report_action_service_build_pdf}
  /// Layout şemasına göre dens PDF üretir (.repx yok).
  ///
  /// Parametreler:
  /// - [report]: Tanım
  /// - [title]: Başlık
  /// - [snapshot]: Parametreler
  /// - [layout]: Opsiyonel inject (yoksa store / default)
  /// - [rows]: Opsiyonel veri satırları (columnId → değer)
  /// - [languageCode]: ar/ku/ckb/fa → RTL; Unicode font (TR+AR+Soranice)
  ///
  /// Dönüş değeri:
  /// - [Uint8List]: PDF
  /// {@endtemplate}
  Future<Uint8List> buildPdfBytes({
    required MbtReportDefinition report,
    required String title,
    required MbtReportParamSnapshot snapshot,
    ReportLayout? layout,
    List<Map<String, String>> rows = const [],
    String? languageCode,
  }) async {
    late final ReportLayout resolved;
    if (layout != null) {
      resolved = layout;
    } else {
      try {
        resolved = await layoutStore.load(report.id);
      } catch (_) {
        resolved = ReportLayoutDefaults.forReportId(report.id);
      }
    }
    final df = DateFormat('dd.MM.yyyy');
    final range = [
      if (snapshot.dateFrom != null) df.format(snapshot.dateFrom!),
      if (snapshot.dateTo != null) df.format(snapshot.dateTo!),
    ].join(' - ');

    final visible = resolved.visibleColumns;
    final isThermal = resolved.pageSize.isThermalReceipt;
    // 80 mm bel: dar kenar boşluğu + kompakt punto
    final margin = isThermal
        ? 8.0
        : (resolved.dense ? 24.0 : 32.0);
    final headerSize = isThermal
        ? 11.0
        : (resolved.dense ? 14.0 : 16.0);
    final bodySize = isThermal
        ? 8.0
        : (resolved.dense ? 9.0 : 10.0);

    final theme = await ReportPdfFonts.loadTheme();
    final textDirection =
        ReportPdfFonts.textDirectionFor(languageCode);

    // Logo: yerelde yoksa merkezden bir kez dene (sessiz)
    Uint8List? logoBytes;
    try {
      final sync = logoSync ?? ReportLogoRemoteSync(store: logoStore);
      await sync.ensureCached();
      logoBytes = await logoStore.loadBytes();
    } catch (_) {
      logoBytes = null;
    }

    final session = ActiveCompanyStore.current;
    final companyName = (companyNameOverride ??
            session?.companyName ??
            '')
        .trim();
    final companyChip = (companyChipOverride ??
            session?.densChipLabel ??
            '')
        .trim();

    var companyTaxId = (companyTaxIdOverride ?? '').trim();
    if (companyTaxId.isEmpty) {
      try {
        final resolver = resolveCompanyTaxId ?? _defaultResolveCompanyTaxId;
        companyTaxId = ((await resolver()) ?? '').trim();
      } catch (_) {
        companyTaxId = '';
      }
    }

    final metaLines = <String>[];
    if (snapshot.code.isNotEmpty || snapshot.name.isNotEmpty) {
      metaLines.add('${snapshot.code}  ${snapshot.name}'.trim());
    }
    for (final e in snapshot.extraLines.entries) {
      metaLines.add('${e.key}: ${e.value}');
    }

    final printedAt = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat(resolved.pageSize),
        margin: pw.EdgeInsets.all(margin),
        theme: theme,
        textDirection: textDirection,
        build: (context) {
          final widgets = <pw.Widget>[];
          if (resolved.showHeader) {
            widgets.add(
              ReportPdfBrand.buildHeader(
                title: title,
                companyName: companyName,
                companyChip: companyChip,
                range: range,
                metaLines: metaLines,
                logoBytes: logoBytes,
                isThermal: isThermal,
                headerSize: headerSize,
                bodySize: bodySize,
              ),
            );
          }

          if (visible.isNotEmpty) {
            widgets.add(_buildTable(visible, rows, bodySize, resolved));
          } else {
            widgets.add(
              pw.Text(
                '—',
                style: pw.TextStyle(
                  fontSize: bodySize,
                  color: PdfColors.grey,
                ),
              ),
            );
          }

          return widgets;
        },
        footer: resolved.showFooter
            ? (context) => ReportPdfBrand.buildFooter(
                  companyName: companyName,
                  companyChip: companyChip,
                  companyTaxId: companyTaxId,
                  printedAt: printedAt,
                  pageNumber: context.pageNumber,
                  pagesCount: context.pagesCount,
                  bodySize: bodySize,
                  isThermal: isThermal,
                )
            : null,
      ),
    );
    return doc.save();
  }

  /// Aktif firma satırından vergi no (kolon varsa).
  static Future<String?> _defaultResolveCompanyTaxId() async {
    try {
      final session = ActiveCompanyStore.current;
      final companyId = session?.companyId.trim() ?? '';
      if (companyId.isEmpty) return null;
      final svc = await DatabaseService.getInstance();
      final db = await svc.getDatabase();
      final cols = await db.rawQuery('PRAGMA table_info(companies)');
      final names = cols
          .map((c) => (c['name'] ?? '').toString().toLowerCase())
          .toSet();
      const candidates = [
        'tax_number',
        'tax_id',
        'vergi_no',
        'vkn',
        'tax_no',
      ];
      String? col;
      for (final c in candidates) {
        if (names.contains(c)) {
          col = c;
          break;
        }
      }
      if (col == null) return null;
      final rows = await db.query(
        'companies',
        columns: [col],
        where: 'id = ?',
        whereArgs: [companyId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final v = rows.first[col]?.toString().trim() ?? '';
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildTable(
    List<ReportLayoutColumn> visible,
    List<Map<String, String>> rows,
    double bodySize,
    ReportLayout layout,
  ) {
    if (layout.pageSize.isThermalReceipt) {
      return _buildThermalStacked(visible, rows, bodySize, layout);
    }

    final headers = visible.map((c) => _t(c.titleKey)).toList();
    final dataRows = rows.isEmpty
        ? <List<String>>[]
        : rows
            .map(
              (row) => visible
                  .map((c) => row[c.id] ?? '')
                  .toList(growable: false),
            )
            .toList(growable: false);

    final table = pw.TableHelper.fromTextArray(
      headers: headers,
      data: dataRows,
      headerStyle: pw.TextStyle(
        fontSize: bodySize,
        fontWeight: pw.FontWeight.bold,
        color: ReportPdfBrand.primary,
      ),
      cellStyle: pw.TextStyle(fontSize: bodySize),
      headerDecoration: pw.BoxDecoration(color: ReportPdfBrand.tableHeaderBg),
      cellHeight: layout.dense ? 16 : 20,
      cellAlignments: {
        for (var i = 0; i < visible.length; i++)
          i: _pdfAlign(visible[i].align),
      },
      columnWidths: {
        for (var i = 0; i < visible.length; i++)
          i: pw.FlexColumnWidth(visible[i].flex.toDouble()),
      },
      border: pw.TableBorder.all(color: ReportPdfBrand.border, width: 0.4),
    );

    if (!layout.showTotals || rows.isEmpty) return table;

    final totalCells = _totalCells(visible, rows);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        table,
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(
            color: ReportPdfBrand.border,
            width: 0.4,
          ),
          columnWidths: {
            for (var i = 0; i < visible.length; i++)
              i: pw.FlexColumnWidth(visible[i].flex.toDouble()),
          },
          children: [
            pw.TableRow(
              children: [
                for (var i = 0; i < totalCells.length; i++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    child: pw.Text(
                      totalCells[i],
                      textAlign: visible[i].align ==
                              ReportLayoutColumnAlign.right
                          ? pw.TextAlign.right
                          : pw.TextAlign.left,
                      style: pw.TextStyle(
                        fontSize: bodySize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 80 mm bel: sütunları üst üste (label: değer) — dar sayfaya sığdırır.
  pw.Widget _buildThermalStacked(
    List<ReportLayoutColumn> visible,
    List<Map<String, String>> rows,
    double bodySize,
    ReportLayout layout,
  ) {
    final blocks = <pw.Widget>[];
    if (rows.isEmpty) {
      blocks.add(
        pw.Text('—', style: pw.TextStyle(fontSize: bodySize)),
      );
    } else {
      for (var r = 0; r < rows.length; r++) {
        final row = rows[r];
        final lines = <pw.Widget>[];
        for (final col in visible) {
          final label = _t(col.titleKey);
          final value = row[col.id] ?? '';
          lines.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: bodySize - 0.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      value,
                      textAlign: col.align == ReportLayoutColumnAlign.right
                          ? pw.TextAlign.right
                          : pw.TextAlign.left,
                      style: pw.TextStyle(fontSize: bodySize),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        blocks.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.4),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: lines,
            ),
          ),
        );
      }
    }

    if (layout.showTotals && rows.isNotEmpty) {
      final totals = _totalCells(visible, rows);
      blocks.add(pw.SizedBox(height: 2));
      blocks.add(
        pw.Text(
          'TOPLAM',
          style: pw.TextStyle(
            fontSize: bodySize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      for (var i = 0; i < visible.length; i++) {
        if (!visible[i].includeInTotals && totals[i].isEmpty) continue;
        if (totals[i].isEmpty || totals[i] == 'Σ') continue;
        blocks.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _t(visible[i].titleKey),
                    style: pw.TextStyle(fontSize: bodySize - 0.5),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    totals[i],
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: bodySize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  List<String> _totalCells(
    List<ReportLayoutColumn> visible,
    List<Map<String, String>> rows,
  ) {
    final totalCells = <String>[];
    for (var i = 0; i < visible.length; i++) {
      final col = visible[i];
      if (!col.includeInTotals) {
        totalCells.add(i == 0 ? 'Σ' : '');
        continue;
      }
      var sum = 0.0;
      for (final row in rows) {
        final raw = row[col.id] ?? '';
        sum += double.tryParse(raw.replaceAll(',', '.')) ?? 0;
      }
      totalCells.add(sum.toStringAsFixed(2));
    }
    return totalCells;
  }

  pw.Alignment _pdfAlign(ReportLayoutColumnAlign align) {
    switch (align) {
      case ReportLayoutColumnAlign.center:
        return pw.Alignment.center;
      case ReportLayoutColumnAlign.right:
        return pw.Alignment.centerRight;
      case ReportLayoutColumnAlign.left:
        return pw.Alignment.centerLeft;
    }
  }

  /// {@template mbt_report_action_service_view_pdf}
  /// PDF üretir ve uygulama içi dens viewer açar
  /// (sistem yazıcı diyaloğu birincil değil).
  /// {@endtemplate}
  Future<void> viewPdf({
    required MbtReportDefinition report,
    required String title,
    required MbtReportParamSnapshot snapshot,
    ReportLayout? layout,
    List<Map<String, String>> rows = const [],
    String? languageCode,
  }) async {
    final bytes = await buildPdfBytes(
      report: report,
      title: title,
      snapshot: snapshot,
      layout: layout,
      rows: rows,
      languageCode: languageCode,
    );
    await _openViewer(bytes: bytes, title: title);
  }

  /// {@template mbt_report_action_service_share}
  /// PDF dosyasını paylaşır.
  /// {@endtemplate}
  Future<String> sharePdf({
    required MbtReportDefinition report,
    required String title,
    required MbtReportParamSnapshot snapshot,
    required String subject,
    required String text,
    ReportLayout? layout,
    List<Map<String, String>> rows = const [],
    String? languageCode,
  }) async {
    final path = await writeTempPdf(
      report: report,
      title: title,
      snapshot: snapshot,
      layout: layout,
      rows: rows,
      languageCode: languageCode,
    );
    await _shareFile(filePath: path, subject: subject, text: text);
    return path;
  }

  /// {@template mbt_report_action_service_write_temp}
  /// Geçici PDF yazar.
  /// {@endtemplate}
  Future<String> writeTempPdf({
    required MbtReportDefinition report,
    required String title,
    required MbtReportParamSnapshot snapshot,
    ReportLayout? layout,
    List<Map<String, String>> rows = const [],
    String? languageCode,
  }) async {
    final bytes = await buildPdfBytes(
      report: report,
      title: title,
      snapshot: snapshot,
      layout: layout,
      rows: rows,
      languageCode: languageCode,
    );
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, '${report.id}.pdf');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  /// {@template mbt_report_action_service_email}
  /// E-posta paylaşımı — PDF dosyasını share sheet ile.
  /// {@endtemplate}
  Future<void> emailPdf({
    required MbtReportDefinition report,
    required String title,
    required MbtReportParamSnapshot snapshot,
    required String subject,
    required String body,
    ReportLayout? layout,
    List<Map<String, String>> rows = const [],
    String? languageCode,
  }) async {
    await sharePdf(
      report: report,
      title: title,
      snapshot: snapshot,
      subject: subject,
      text: body,
      layout: layout,
      rows: rows,
      languageCode: languageCode,
    );
  }
}
