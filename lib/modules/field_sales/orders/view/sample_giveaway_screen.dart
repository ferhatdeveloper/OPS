// Dosya Adı: sample_giveaway_screen.dart
// Açıklama: Numune / hediye stub ekranı (MBT SİPARİŞ → Numune Hediye)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

/// {@template sample_giveaway_screen}
/// Numune / hediye için stub ekran.
/// Route: `/field-sales/sample-giveaway`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, SampleGiveawayScreen.routeName);
/// ```
/// {@endtemplate}
class SampleGiveawayScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/sample-giveaway`
  static const String routeName = '/field-sales/sample-giveaway';

  const SampleGiveawayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.sample_giveaway');

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
