// Dosya Adı: visit_new_customer_screen.dart
// Açıklama: Ziyaret → Yeni Cari Hesap stub ekranı (MBT ZİYARET)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

/// {@template visit_new_customer_screen}
/// Ziyaret menüsünden yeni cari hesap için stub ekran.
/// Route: `/field-sales/visit-new`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitNewCustomerScreen.routeName);
/// ```
/// {@endtemplate}
class VisitNewCustomerScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/visit-new`
  static const String routeName = '/field-sales/visit-new';

  const VisitNewCustomerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.visit_new_customer');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
