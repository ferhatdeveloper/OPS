// Dosya Adı: collections_untransferred_screen.dart
// Açıklama: Transfer edilmeyen tahsilatlar dens kuyruk (1-SATIŞ / 2-ALIŞ)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/collection_untransferred_record.dart';
import '../model/collection_untransferred_seed.dart';
import '../widgets/collection_untransferred_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template collections_untransferred_screen}
/// MBT "Transfer Edilmeyen Tahsilatlar" dens kuyruk ekranı.
/// Route: `/field-sales/finance-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CollectionsUntransferredScreen.routeName);
/// ```
/// {@endtemplate}
class CollectionsUntransferredScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/finance-untransferred`
  static const String routeName = '/field-sales/finance-untransferred';

  /// [records]: Opsiyonel kayıtlar (null → stub seed)
  final List<CollectionUntransferredRecord>? records;

  /// {@template collections_untransferred_screen_constructor}
  /// Transfer edilmeyen tahsilatlar dens kuyruk ekranını oluşturur.
  /// {@endtemplate}
  const CollectionsUntransferredScreen({
    Key? key,
    this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title =
        l10n.translate('field_sales.stubs.collections_untransferred');
    final source = records ?? CollectionUntransferredSeed.defaultRows;
    final rows = CollectionUntransferredDensTile.toQueueRows(source, l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: MbtSalesPurchaseQueueBody(
        emptyMessageKey: 'field_sales.collections_untransferred_empty',
        rows: rows,
      ),
    );
  }
}
