// Dosya Adı: sales_report_screen.dart
// Açıklama: Satış raporu dens ekranı (MBT RAPORLAR · SQLite satırlar)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../viewmodel/report_dens_query_service.dart';
import 'report_dens_host.dart';

/// {@template sales_report_screen}
/// Satış raporu dens formu (faturalar → SQLite).
/// Route: `/field-sales/report-sales`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, SalesReportScreen.routeName);
/// ```
/// {@endtemplate}
class SalesReportScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/report-sales`
  static const String routeName = '/field-sales/report-sales';

  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ReportDensHost(
      titleKey: 'field_sales.stubs.sales_report',
      kind: ReportDensKind.sales,
    );
  }
}
