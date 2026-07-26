// Dosya Adı: order_pending_dens_tile.dart
// Açıklama: Bekleyen sipariş dens satır — fiş · ONAY durumu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';
import '../../../../core/sync/approval_status.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/order_model.dart';
import '../model/order_pending_record.dart';

/// {@template order_pending_dens_tile}
/// [OrderPendingRecord] → [MbtQueueRow] dens ONAY alanları.
///
/// Kullanım örneği:
/// ```dart
/// final row = OrderPendingDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class OrderPendingDensTile {
  OrderPendingDensTile._();

  /// {@template order_pending_dens_tile_onay_label}
  /// ONAY int → yerelleştirilmiş durum metni.
  /// {@endtemplate}
  static String onayStatusLabel(int onay, AppLocalization l10n) {
    final status = ApprovalStatus.fromValue(onay);
    switch (status) {
      case ApprovalStatus.pending:
        return l10n.translate('field_sales.onay_pending');
      case ApprovalStatus.approved:
        return l10n.translate('field_sales.onay_approved');
      case ApprovalStatus.synced:
        return l10n.translate('field_sales.onay_synced');
      case ApprovalStatus.rejected:
        return l10n.translate('field_sales.onay_rejected');
      case ApprovalStatus.error:
        return l10n.translate('field_sales.onay_error');
    }
  }

  /// {@template order_pending_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı (ONAY alanı dolu).
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    OrderPendingRecord record,
    AppLocalization l10n,
  ) {
    final side = record.orderType == OrderType.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;
    final customer = [
      if ((record.customerCode ?? '').isNotEmpty) record.customerCode,
      if ((record.customerName ?? '').isNotEmpty) record.customerName,
    ].join(' · ');
    final amount = record.totalAmount.toStringAsFixed(2);
    final subtitle = l10n.translate(
      'field_sales.orders_pending_row_subtitle',
      args: {
        'customer': customer.isEmpty ? record.customerId : customer,
        'amount': amount,
      },
    );

    return MbtQueueRow(
      id: record.id,
      side: side,
      date: record.orderDate,
      title: record.id,
      subtitle: subtitle,
      searchBlob: '${record.status} ${record.notes ?? ''} $customer',
      gibStatusFieldLabel: l10n.translate('field_sales.onay_label'),
      gibStatusLabel: onayStatusLabel(record.approvalStatus, l10n),
    );
  }

  /// {@template order_pending_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<OrderPendingRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
