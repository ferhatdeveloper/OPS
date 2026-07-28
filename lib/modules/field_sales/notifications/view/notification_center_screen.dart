// Dosya Adı: notification_center_screen.dart
// Açıklama: Bildirim merkezi stub listesi (field sales)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template notification_center_screen}
/// Plasiyer bildirimlerini görür (stub liste).
///
/// Rota: `/field-sales/notifications`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, NotificationCenterScreen.routeName);
/// ```
/// {@endtemplate}
class NotificationCenterScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/notifications`
  static const String routeName = '/field-sales/notifications';

  const NotificationCenterScreen({Key? key}) : super(key: key);

  /// Stub örnek kayıtlar — gerçek veri bağlanana kadar sabit.
  static const List<Map<String, String>> _notifications = [
    {
      'titleKey': 'mobile_dashboard.notifications',
      'bodyKey': 'mobile_dashboard.notifications_coming_soon',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.notification_center');

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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Text(
                l10n.translate('mobile_dashboard.notifications_coming_soon'),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: FieldSalesDensTheme.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FieldSalesDensTheme.bodyBackground(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF375A7F),
                      ),
                    ),
                    title: Text(
                      l10n.translate(item['titleKey']!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        l10n.translate(item['bodyKey']!),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
    );
  }
}
