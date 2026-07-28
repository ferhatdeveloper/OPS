// Dosya Adı: profile_settings_screen.dart
// Açıklama: Profil ayarları stub ekranı
//   (route: /field-sales/profile-settings)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template profile_settings_screen}
/// Profil ayarları için stub ekran.
/// Route: `/field-sales/profile-settings`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ProfileSettingsScreen.routeName);
/// ```
/// {@endtemplate}
class ProfileSettingsScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/profile-settings`
  static const String routeName = '/field-sales/profile-settings';

  /// {@template profile_settings_screen_constructor}
  /// Profil ayarları stub ekranını oluşturur.
  /// {@endtemplate}
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.profile_settings');

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
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
