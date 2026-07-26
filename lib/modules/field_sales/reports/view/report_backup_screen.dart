// Dosya Adı: report_backup_screen.dart
// Açıklama: Rapor Yedekle/İndir dens ekranı (MBT RAPORLAR)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import 'report_dens_host.dart';

/// {@template report_backup_screen}
/// Rapor Yedekle/İndir dens formu (satış+tahsilat+ziyaret birleşik).
/// Route: `/field-sales/report-backup`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ReportBackupScreen.routeName);
/// ```
/// {@endtemplate}
class ReportBackupScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/report-backup`
  static const String routeName = '/field-sales/report-backup';

  const ReportBackupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // kind null → ReportDensHost üç türü birleştirir (Yedekle/İndir host)
    return const ReportDensHost(
      titleKey: 'field_sales.stubs.report_backup',
    );
  }
}
