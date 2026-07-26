// Dosya Adı: document_share_screen.dart
// Açıklama: Belge paylaşım stub ekranı (route: /field-sales/document-share)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template document_share_screen}
/// Belge paylaşım (mail / yazıcı / WhatsApp) için stub ekran.
///
/// Route: `/field-sales/document-share`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, DocumentShareScreen.routeName);
/// ```
/// {@endtemplate}
class DocumentShareScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/document-share`
  static const String routeName = '/field-sales/document-share';

  /// {@template document_share_screen_constructor}
  /// Belge paylaşım stub ekranını oluşturur.
  /// {@endtemplate}
  const DocumentShareScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.document_share');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.translate('mobile_dashboard.module_under_development'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
