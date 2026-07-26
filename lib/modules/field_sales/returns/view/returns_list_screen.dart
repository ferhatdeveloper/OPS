// Dosya Adı: returns_list_screen.dart
// Açıklama: İade listesi stub ekranı (route: /field-sales/returns-list)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

/// {@template returns_list_screen}
/// İade listesi için stub ekran.
/// Route: `/field-sales/returns-list`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ReturnsListScreen.routeName);
/// ```
/// {@endtemplate}
class ReturnsListScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/returns-list`
  static const String routeName = '/field-sales/returns-list';

  const ReturnsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.returns_list');

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
