// Dosya Adı: language_picker_screen.dart
// Açıklama: Dil seçici stub ekranı (route: /field-sales/language-picker)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template language_picker_screen}
/// Uygulama dili seçimi için stub ekran.
///
/// Route: `/field-sales/language-picker`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, LanguagePickerScreen.routeName);
/// ```
/// {@endtemplate}
class LanguagePickerScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/language-picker`
  static const String routeName = '/field-sales/language-picker';

  /// {@template language_picker_screen_constructor}
  /// Dil seçici stub ekranını oluşturur.
  /// {@endtemplate}
  const LanguagePickerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.language_picker'),
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
