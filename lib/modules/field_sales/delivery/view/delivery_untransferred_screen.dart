// Dosya Adı: delivery_untransferred_screen.dart
// Açıklama: Aktarılamayan teslimatlar dens kuyruk (1-SATIŞ / 2-ALIŞ)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template delivery_untransferred_screen}
/// Aktarılamayan teslimatlar dens kuyruk ekranı.
/// Route: `/field-sales/delivery-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   DeliveryUntransferredScreen.routeName,
/// );
/// ```
/// {@endtemplate}
class DeliveryUntransferredScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/delivery-untransferred`
  static const String routeName = '/field-sales/delivery-untransferred';

  const DeliveryUntransferredScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.delivery_untransferred');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: const MbtSalesPurchaseQueueBody(
        emptyMessageKey: 'field_sales.delivery_untransferred_empty',
      ),
    );
  }
}
