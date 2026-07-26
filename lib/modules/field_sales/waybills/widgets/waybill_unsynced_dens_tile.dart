// Dosya Adı: waybill_unsynced_dens_tile.dart
// Açıklama: Transfer edilmeyen irsaliye dens satır — is_synced=0
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/waybill_type.dart';
import '../viewmodel/waybill_repository.dart';

/// {@template waybill_unsynced_dens_tile}
/// [WaybillUnsyncedRow] → [MbtQueueRow] dens dönüştürücü.
///
/// Kullanım örneği:
/// ```dart
/// final rows = WaybillUnsyncedDensTile.toQueueRows(list, l10n);
/// ```
/// {@endtemplate}
class WaybillUnsyncedDensTile {
  WaybillUnsyncedDensTile._();

  /// {@template waybill_unsynced_dens_tile_to_queue_row}
  /// Tek unsynced satır → kuyruk dens.
  ///
  /// Parametreler:
  /// - [row]: `is_synced=0` irsaliye
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    WaybillUnsyncedRow row,
    AppLocalization l10n,
  ) {
    final type = WaybillType.fromLocalKey(row.waybillType);
    final side = type == WaybillType.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;

    final notes = (row.notes ?? '').trim();
    final title = notes.isNotEmpty ? notes : row.id;
    final amountFmt = NumberFormat('#,##0.00', 'tr_TR');
    final amount = amountFmt.format(row.totalAmount);
    final typeLabel = type == WaybillType.purchase
        ? l10n.translate('field_sales.stubs.waybill_purchase')
        : l10n.translate('field_sales.stubs.waybill_wholesale');

    final code = (row.customerCode ?? '').trim();
    final name = (row.customerName ?? '').trim();
    String customerLabel;
    if (code.isNotEmpty && name.isNotEmpty) {
      customerLabel = '$code · $name';
    } else if (name.isNotEmpty) {
      customerLabel = name;
    } else if (code.isNotEmpty) {
      customerLabel = code;
    } else {
      customerLabel = row.customerId;
    }

    final subtitle = l10n.translate(
      'field_sales.waybill_pending_row_subtitle',
      args: {
        'customer': customerLabel,
        'amount': amount,
        'type': typeLabel,
      },
    );

    return MbtQueueRow(
      id: row.id,
      side: side,
      date: row.waybillDate,
      title: title,
      subtitle: subtitle,
      searchBlob:
          '${row.customerId} $code $name ${row.status} ${row.notes ?? ''}',
    );
  }

  /// {@template waybill_unsynced_dens_tile_rows}
  /// Unsynced liste → dens kuyruk satırları.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<WaybillUnsyncedRow> rows,
    AppLocalization l10n,
  ) {
    return rows
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
