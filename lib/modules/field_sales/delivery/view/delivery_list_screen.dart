// Dosya Adı: delivery_list_screen.dart
// Açıklama: Teslimat kuyruk dens ekranı (1-SATIŞ / 2-ALIŞ · dönem)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

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
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: const MbtSalesPurchaseQueueBody(
        emptyMessageKey: 'field_sales.delivery_queue_empty',
      ),
    );
  }
}
