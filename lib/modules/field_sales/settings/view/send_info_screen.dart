// Dosya Adı: send_info_screen.dart
// Açıklama: Bilgi gönderme stub ekranı (MBT DİĞER → Bilgi Gönderme)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template send_info_screen}
/// Bilgi gönderme için stub ekran.
/// Route: `/field-sales/send-info`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, SendInfoScreen.routeName);
/// ```
/// {@endtemplate}
class SendInfoScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/send-info`
  static const String routeName = '/field-sales/send-info';

  /// {@template send_info_screen_constructor}
  /// Bilgi gönderme stub ekranını oluşturur.
  /// {@endtemplate}
  const SendInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    // field_sales.stubs.send_info yok — mevcut submenu key
    final title = l10n.translate('submodules.bilgi_gonderme');

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
