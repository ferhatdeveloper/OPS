// Dosya Adı: collection_report_screen.dart
// Açıklama: Tahsilat raporu dens ekranı (MBT RAPORLAR · SQLite satırlar)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../viewmodel/report_dens_query_service.dart';
import 'report_dens_host.dart';

/// {@template collection_report_screen}
/// Tahsilat raporu dens formu (collections → SQLite).
/// Route: `/field-sales/report-collection`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CollectionReportScreen.routeName);
/// ```
/// {@endtemplate}
class CollectionReportScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/report-collection`
  static const String routeName = '/field-sales/report-collection';

  const CollectionReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ReportDensHost(
      titleKey: 'field_sales.stubs.collection_report',
      kind: ReportDensKind.collection,
    );
  }
}
