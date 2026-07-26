// Dosya Adı: waybill_pending_dens_tile.dart
// Açıklama: Bekleyen irsaliye dens satır — belge · cari · tutar
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/waybill_model.dart';
import '../model/waybill_type.dart';

/// {@template waybill_pending_dens_tile}
/// SQLite `waybills` map / [WaybillModel] → [MbtQueueRow] dens.
///
/// Kullanım örneği:
/// ```dart
/// final row = WaybillPendingDensTile.toQueueRow(map, l10n);
/// ```
/// {@endtemplate}
class WaybillPendingDensTile {
  WaybillPendingDensTile._();

  /// {@template waybill_pending_dens_tile_to_queue_row}
  /// Map → kuyruk dens satırı.
  ///
  /// Parametreler:
  /// - [map]: `waybills` satırı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    Map<String, dynamic> map,
    AppLocalization l10n,
  ) {
    final model = WaybillModel.fromMap(map);
    final type = WaybillType.fromLocalKey(model.waybillType);
    final side = type == WaybillType.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;

    final notes = (model.notes ?? '').trim();
    final title = notes.isNotEmpty ? notes : model.id;
    final amountFmt = NumberFormat('#,##0.00', 'tr_TR');
    final amount = amountFmt.format(model.totalAmount);
    final typeLabel = type == WaybillType.purchase
        ? l10n.translate('field_sales.stubs.waybill_purchase')
        : l10n.translate('field_sales.stubs.waybill_wholesale');
    final subtitle = l10n.translate(
      'field_sales.waybill_pending_row_subtitle',
      args: {
        'customer': model.customerId,
        'amount': amount,
        'type': typeLabel,
      },
    );

    return MbtQueueRow(
      id: model.id,
      side: side,
      date: model.waybillDate,
      title: title,
      subtitle: subtitle,
      searchBlob: '${model.customerId} ${model.status} ${model.notes ?? ''}',
    );
  }

  /// {@template waybill_pending_dens_tile_rows}
  /// Map listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<Map<String, dynamic>> maps,
    AppLocalization l10n,
  ) {
    return maps
        .map((m) => toQueueRow(m, l10n))
        .toList(growable: false);
  }
}
