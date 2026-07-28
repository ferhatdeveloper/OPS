// Dosya Adı: report_dens_host.dart
// Açıklama: Rapor dens — SQLite satırlar + Yedekle/İndir export
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../engine/report_dens_export_service.dart';
import '../viewmodel/report_dens_query_service.dart';
import 'report_dens_form.dart';

/// {@template report_dens_host}
/// Satış / tahsilat / ziyaret rapor dens host Scaffold’ı.
///
/// Kullanım örneği:
/// ```dart
/// const ReportDensHost(
///   titleKey: 'field_sales.stubs.sales_report',
///   kind: ReportDensKind.sales,
/// )
/// ```
/// {@endtemplate}
class ReportDensHost extends StatefulWidget {
  /// [titleKey]: AppBar l10n anahtarı
  final String titleKey;

  /// [kind]: SQLite rapor türü; null → üç tür birleşik
  final ReportDensKind? kind;

  /// [exportService]: Yedekle/İndir stub (test inject)
  final ReportDensExportService? exportService;

  const ReportDensHost({
    Key? key,
    required this.titleKey,
    this.kind,
    this.exportService,
  }) : super(key: key);

  @override
  State<ReportDensHost> createState() => _ReportDensHostState();
}

class _ReportDensHostState extends State<ReportDensHost> {
  /// [_dateFrom]: Başlangıç tarihi
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 7));

  /// [_dateTo]: Bitiş tarihi
  DateTime _dateTo = DateTime.now();

  /// [_rows]: Dens satırları (SQLite)
  List<ReportDensRowPlaceholder> _rows = [];

  /// [_isLoading]: Rapor getiriliyor
  bool _isLoading = false;

  /// [_isExporting]: Yedekle / İndir çalışıyor
  bool _isExporting = false;

  /// [_exportService]: Lazy stub export
  late final ReportDensExportService _exportService =
      widget.exportService ?? ReportDensExportService();

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _dateFrom = picked;
        if (_dateFrom.isAfter(_dateTo)) _dateTo = _dateFrom;
      } else {
        _dateTo = picked;
        if (_dateTo.isBefore(_dateFrom)) _dateFrom = _dateTo;
      }
    });
  }

  void _showSnack(String key, {Map<String, String>? params}) {
    final l10n = AppLocalization.of(context);
    final text = l10n.translate(key, args: params);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  /// {@template report_dens_host_fetch_kinds}
  /// Tek tür veya tüm türler için dens satırlarını yükler.
  /// {@endtemplate}
  Future<List<ReportDensRowPlaceholder>> _fetchForKinds(
    Database db,
  ) async {
    final kinds = widget.kind == null
        ? const <ReportDensKind>[
            ReportDensKind.sales,
            ReportDensKind.collection,
            ReportDensKind.visit,
          ]
        : <ReportDensKind>[widget.kind!];
    final all = <ReportDensRowPlaceholder>[];
    for (final kind in kinds) {
      final rows = await ReportDensQueryService.fetchRows(
        db: db,
        kind: kind,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      all.addAll(rows);
    }
    return all;
  }

  /// {@template report_dens_host_on_run}
  /// Tarih aralığına göre SQLite dens satırlarını yükler.
  /// {@endtemplate}
  Future<void> _onRun() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final rows = await _fetchForKinds(db);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
      _showSnack('field_sales.report_dens.run_done');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('field_sales.report_dens.run_error');
    }
  }

  /// {@template report_dens_host_on_export}
  /// Mevcut dens satırlarını Yedekle veya İndir dosyasına yazar.
  /// {@endtemplate}
  Future<void> _onExport(ReportDensExportKind exportKind) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final l10n = AppLocalization.of(context);
    try {
      final exportRows = _rows
          .map(
            (r) => ReportDensExportRow(
              title: r.title,
              subtitle: r.subtitle,
              value: r.value,
            ),
          )
          .toList();
      final isBackup = exportKind == ReportDensExportKind.backup;
      final result = await _exportService.export(
        kind: exportKind,
        reportKey: widget.titleKey,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        rows: exportRows,
        shareSubject: l10n.translate(
          isBackup
              ? 'field_sales.report_dens.share_subject_backup'
              : 'field_sales.report_dens.share_subject_download',
        ),
        shareText: l10n.translate(
          isBackup
              ? 'field_sales.report_dens.share_text_backup'
              : 'field_sales.report_dens.share_text_download',
        ),
      );
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnack(
        isBackup
            ? 'field_sales.report_dens.backup_done'
            : 'field_sales.report_dens.download_done',
        params: {'path': result.filePath},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnack('field_sales.report_dens.export_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate(widget.titleKey),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ReportDensForm(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        onDateFromTap: () => _pickDate(from: true),
        onDateToTap: () => _pickDate(from: false),
        rows: _rows,
        onRun: _isLoading ? null : _onRun,
        onBackup: _isExporting
            ? null
            : () => _onExport(ReportDensExportKind.backup),
        onDownload: _isExporting
            ? null
            : () => _onExport(ReportDensExportKind.download),
      ),
    );
  }
}
