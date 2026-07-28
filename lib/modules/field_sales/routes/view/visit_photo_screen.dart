// Dosya Adı: visit_photo_screen.dart
// Açıklama: Ziyaret fotoğrafı stub ekranı (MBT ziyaret foto parity)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template visit_photo_screen}
/// Ziyaret fotoğrafı için stub ekran.
/// Route: `/field-sales/visit-photo`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitPhotoScreen.routeName);
/// ```
/// {@endtemplate}
class VisitPhotoScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/visit-photo`
  static const String routeName = '/field-sales/visit-photo';

  const VisitPhotoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.visit_photo');

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
