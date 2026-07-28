// Dosya Adı: cari_report_result_screen.dart
// Açıklama: CARİ rapor dens sonuç — ortak Liste/Grafik/Pivot kabuğu
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../engine/mbt_report_action_service.dart';
import '../model/mbt_report_category.dart';
import '../model/report_layout.dart';
import '../view/report_result_viewer_screen.dart';
import '../viewmodel/report_layout_store.dart';

/// {@template cari_report_result_screen}
/// CARİ rapor dens sonuç — [ReportResultViewerScreen] sarmalayıcı.
///
/// Kullanım örneği:
/// ```dart
/// CariReportResultScreen(
///   reportId: 'cari_extre',
///   title: 'Cari Extre',
///   snapshot: snapshot,
///   rows: rows,
/// );
/// ```
/// {@endtemplate}
class CariReportResultScreen extends StatelessWidget {
  /// Named route (orchestrator TODO)
  static const String routeName = '/field-sales/report-cari-result';

  /// [reportId]: Katalog id
  final String reportId;

  /// [title]: AppBar / PDF başlık
  final String title;

  /// [snapshot]: Parametre anlık görüntüsü
  final MbtReportParamSnapshot snapshot;

  /// [rows]: Layout sütun id → değer
  final List<Map<String, String>> rows;

  /// [layout]: Test inject
  final ReportLayout? layout;

  /// [actionService]: PDF inject
  final MbtReportActionService? actionService;

  /// [layoutStore]: SharedPreferences layout
  final ReportLayoutStore? layoutStore;

  /// {@macro cari_report_result_screen}
  const CariReportResultScreen({
    Key? key,
    required this.reportId,
    required this.title,
    required this.snapshot,
    required this.rows,
    this.layout,
    this.actionService,
    this.layoutStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReportResultViewerScreen(
      reportId: reportId,
      title: title,
      category: MbtReportCategory.cari,
      snapshot: snapshot,
      rows: rows,
      layout: layout,
      actionService: actionService,
      layoutStore: layoutStore,
    );
  }
}
