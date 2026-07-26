// Dosya Adı: whms_shell_screen.dart
// Açıklama: WHMS /whms shell — dens stub iskelet (UI no-touch)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../contract/whms_route_map.dart';

/// {@template whms_shell_screen}
/// Merkez depo giriş kabuğu. Plasiyer `fs_stock` menüsüne gömülmez.
/// Görsel redesign yok — mevcut dens AppBar + gövde metin.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsShellScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsShellScreen extends StatelessWidget {
  /// [routeName]: `/whms`
  static const String routeName = WhmsRouteMap.whmsShell;

  /// {@macro whms_shell_screen}
  const WhmsShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('whms.module_name')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.translate('whms.phase2_shell'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
