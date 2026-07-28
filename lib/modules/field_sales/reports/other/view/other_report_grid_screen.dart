// Dosya Adı: other_report_grid_screen.dart
// Açıklama: DİĞER/yönetici/finans rapor dens — ortak Liste/Grafik/Pivot
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../engine/mbt_report_action_service.dart';
import '../../model/mbt_report_catalog.dart';
import '../../model/mbt_report_category.dart';
import '../../model/report_layout.dart';
import '../../view/report_result_viewer_screen.dart';

/// {@template other_report_grid_screen}
/// Parametreler → sarı Görüntüle — ortak sonuç kabuğu.
///
/// Kullanım örneği:
/// ```dart
/// OtherReportGridScreen(
///   title: 'Ziyaret Listesi',
///   reportId: 'ziyaret_listesi',
///   rows: const [],
/// );
/// ```
/// {@endtemplate}
class OtherReportGridScreen extends StatelessWidget {
  /// Named route (opsiyonel push)
  static const String routeName = '/field-sales/report-other-grid';

  /// [title]: AppBar başlığı
  final String title;

  /// [reportId]: Layout id
  final String reportId;

  /// [rows]: columnId → değer
  final List<Map<String, String>> rows;

  /// [layout]: Test inject
  final ReportLayout? layout;

  /// [snapshot]: PDF için parametre (opsiyonel)
  final MbtReportParamSnapshot snapshot;

  /// [category]: Grafik ailesi (null → katalog / diger)
  final MbtReportCategory? category;

  /// {@macro other_report_grid_screen}
  const OtherReportGridScreen({
    Key? key,
    required this.title,
    required this.reportId,
    required this.rows,
    this.layout,
    this.snapshot = const MbtReportParamSnapshot(),
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final def = MbtReportCatalog.byId(reportId);
    return ReportResultViewerScreen(
      reportId: reportId,
      title: title,
      category: category ?? def?.category ?? MbtReportCategory.diger,
      snapshot: snapshot,
      rows: rows,
      layout: layout,
    );
  }
}
