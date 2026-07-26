// Dosya Adı: order_tracking_screen.dart
// Açıklama: Sipariş Takibi dens listesi (MBT · SQLite dönem filtre)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/order_dens_scope.dart';
import 'order_dens_queue_body.dart';

/// {@template order_tracking_screen}
/// MBT SİPARİŞ → Sipariş Takibi dens listesi (SQLite).
/// Route: `/field-sales/orders-tracking`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, OrderTrackingScreen.routeName);
/// ```
/// {@endtemplate}
class OrderTrackingScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/orders-tracking`
  static const String routeName = '/field-sales/orders-tracking';

  const OrderTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.order_tracking');

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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const OrderDensQueueBody(
        scope: OrderDensScope.tracking,
        emptyMessageKey: 'field_sales.order_tracking_empty',
      ),
    );
  }
}
