// Dosya Adı: delivery_list_screen.dart
// Açıklama: Teslimat kuyruk dens ekranı (1-SATIŞ / 2-ALIŞ · dönem)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';

/// {@template delivery_list_screen}
/// Teslimat listesi / kuyruk dens ekranı (MBT Teslimat parity).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, DeliveryListScreen.routeName);
/// ```
/// {@endtemplate}
class DeliveryListScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/delivery-list`
  static const String routeName = '/field-sales/delivery-list';

  const DeliveryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.delivery_list');

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
      body: const MbtSalesPurchaseQueueBody(
        emptyMessageKey: 'field_sales.delivery_queue_empty',
      ),
    );
  }
}
