// Dosya Adı: help_faq_screen.dart
// Açıklama: Yardım / SSS stub ekranı (route: /field-sales/help-faq)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template help_faq_screen}
/// Yardım / SSS için stub ekran.
/// Route: `/field-sales/help-faq`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, HelpFaqScreen.routeName);
/// ```
/// {@endtemplate}
class HelpFaqScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/help-faq`
  static const String routeName = '/field-sales/help-faq';

  /// {@template help_faq_screen_constructor}
  /// Yardım / SSS stub ekranını oluşturur.
  /// {@endtemplate}
  const HelpFaqScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.help_faq');

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
