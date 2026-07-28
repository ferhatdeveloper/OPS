// Dosya Adı: about_app_screen.dart
// Açıklama: Uygulama hakkında stub ekranı (MBT yardım / about)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template about_app_screen}
/// Uygulama hakkında bilgileri gösteren stub ekran.
/// Route: `/field-sales/about`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, AboutAppScreen.routeName);
/// ```
/// {@endtemplate}
class AboutAppScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/about`
  static const String routeName = '/field-sales/about';

  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.about_app');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
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
