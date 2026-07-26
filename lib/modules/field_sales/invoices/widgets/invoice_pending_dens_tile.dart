// Dosya Adı: invoice_pending_dens_tile.dart
// Açıklama: Bekleyen fatura dens satır — fiş · cari · tutar
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/invoice_pending_record.dart';

/// {@template invoice_pending_dens_tile}
/// [InvoicePendingRecord] → [MbtQueueRow] dens alanları.
///
/// Kullanım örneği:
/// ```dart
/// final row = InvoicePendingDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class InvoicePendingDensTile {
  InvoicePendingDensTile._();

  /// [amountFmt]: TR tutar biçimi
  static final NumberFormat _amountFmt =
      NumberFormat('#,##0.00', 'tr_TR');

  /// {@template invoice_pending_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı.
  ///
  /// Parametreler:
  /// - [record]: Bekleyen fatura kaydı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    InvoicePendingRecord record,
    AppLocalization l10n,
  ) {
    final side = record.docSide == InvoicePendingDocSide.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;
    final amount = _amountFmt.format(record.totalAmount);
    final customer = record.customerLabel;
    final subtitle = l10n.translate(
      'field_sales.invoices_pending_row_subtitle',
      args: {
        'customer': customer.isEmpty ? record.customerId : customer,
        'amount': amount,
      },
    );
    final approvalLabel = l10n.translate(
      'field_sales.invoices_pending_approval',
    );

    return MbtQueueRow(
      id: record.id,
      side: side,
      date: record.invoiceDate,
      title: record.id,
      subtitle: subtitle,
      searchBlob: '${record.customerId} $customer '
          '${record.notes ?? ''} ${record.status} $approvalLabel',
      gibStatusLabel: approvalLabel,
      gibStatusFieldLabel: l10n.translate(
        'field_sales.invoice_status_pending',
      ),
    );
  }

  /// {@template invoice_pending_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<InvoicePendingRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
