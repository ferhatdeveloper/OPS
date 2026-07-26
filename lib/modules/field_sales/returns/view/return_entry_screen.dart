// Dosya Adı: return_entry_screen.dart
// Açıklama: İade girişi stub ekranı (route: /field-sales/return-entry)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

/// {@template return_entry_screen}
/// İade girişi için stub ekran.
///
/// Route: `/field-sales/return-entry`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ReturnEntryScreen.routeName);
/// ```
/// {@endtemplate}
class ReturnEntryScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/return-entry`
  static const String routeName = '/field-sales/return-entry';

  /// {@template return_entry_screen_constructor}
  /// İade girişi stub ekranını oluşturur.
  /// {@endtemplate}
  const ReturnEntryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

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
          l10n.translate('field_sales.stubs.return_entry'),
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
