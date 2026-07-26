// Dosya Adı: visit_report_screen.dart
// Açıklama: Ziyaret raporu dens ekranı (MBT RAPORLAR · SQLite satırlar)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../viewmodel/report_dens_query_service.dart';
import 'report_dens_host.dart';

/// {@template visit_report_screen}
/// Ziyaret raporu dens formu (visits → SQLite).
/// Route: `/field-sales/report-visit`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitReportScreen.routeName);
/// ```
/// {@endtemplate}
class VisitReportScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/report-visit`
  static const String routeName = '/field-sales/report-visit';

  const VisitReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ReportDensHost(
      titleKey: 'field_sales.stubs.visit_report',
      kind: ReportDensKind.visit,
    );
  }
}
