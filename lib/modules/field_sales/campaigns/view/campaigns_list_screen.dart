// Dosya Adı: campaigns_list_screen.dart
// Açıklama: Eski /campaigns-list rotası — MBT DUYURULAR tek kaynağa alias
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../announcements/view/announcements_screen.dart';

/// {@template campaigns_list_screen}
/// **Alias / uyumluluk kabuğu** — MBT DUYURULAR UI tek kaynağı
/// [AnnouncementsScreen] (`/field-sales/announcements`).
///
/// Yeni menü / deep link: [AnnouncementsScreen.routeName] kullanın.
/// Bu rota yalnızca eski `/field-sales/campaigns-list` çağrıları için tutulur.
///
/// Kullanım örneği:
/// ```dart
/// // Tercih edilen:
/// Navigator.pushNamed(context, AnnouncementsScreen.routeName);
/// // Eski rota (aynı UI):
/// Navigator.pushNamed(context, CampaignsListScreen.routeName);
/// ```
/// {@endtemplate}
class CampaignsListScreen extends StatelessWidget {
  /// [routeName]: Eski named route — `/field-sales/campaigns-list`
  static const String routeName = '/field-sales/campaigns-list';

  const CampaignsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AnnouncementsScreen();
  }
}
