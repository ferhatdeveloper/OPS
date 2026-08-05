// Dosya Adı: invoice_untransferred_dens_tile.dart
// Açıklama: Transfer edilmeyen fatura dens satır → MbtQueueRow + Logo durum
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../../sync/view/logo_queue_status_chip.dart';
import '../model/invoice_untransferred_record.dart';

/// {@template invoice_untransferred_dens_tile}
/// [InvoiceUntransferredRecord] → [MbtQueueRow] dens kuyruk.
/// Aktarım durumu: mevcut [LogoQueueStatus] l10n (gibStatus dens alanı).
///
/// Kullanım örneği:
/// ```dart
/// final row = InvoiceUntransferredDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class InvoiceUntransferredDensTile {
  InvoiceUntransferredDensTile._();

  /// {@template invoice_untransferred_dens_tile_queue_status}
  /// sync_queue hata / retry → [LogoQueueStatus] (chip dili).
  ///
  /// Parametreler:
  /// - [record]: Transfer edilmeyen fatura
  ///
  /// Dönüş değeri:
  /// - [LogoQueueStatus]: Dens durum etiketi kaynağı
  /// {@endtemplate}
  static LogoQueueStatus queueStatus(InvoiceUntransferredRecord record) {
    return LogoQueueStatus.fromJob({
      'retry_count': record.retryCount,
      'last_error': record.lastError,
    });
  }

  /// {@template invoice_untransferred_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı (cari + tutar + aktarım durumu).
  ///
  /// Parametreler:
  /// - [record]: Transfer edilmeyen fatura
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    InvoiceUntransferredRecord record,
    AppLocalization l10n,
  ) {
    final side = record.docSide == InvoiceUntransferredDocSide.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;
    final date = record.documentDate ??
        record.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final customer = [
      if ((record.customerCode ?? '').isNotEmpty) record.customerCode,
      if ((record.customerName ?? '').isNotEmpty) record.customerName,
    ].join(' · ');
    final amountLabel = record.amount.toStringAsFixed(2);
    final subtitle = customer.isEmpty
        ? l10n.translate(
            'field_sales.invoices_untransferred_amount',
            args: {'amount': amountLabel},
          )
        : l10n.translate(
            'field_sales.invoices_untransferred_row_subtitle',
            args: {
              'customer': customer,
              'amount': amountLabel,
            },
          );
    final status = queueStatus(record);
    final statusLabel = l10n.translate(status.l10nKey);
    final statusField = l10n.translate('field_sales.offline_queue.status');

    return MbtQueueRow(
      id: record.id,
      side: side,
      date: date,
      title: record.documentNo,
      subtitle: subtitle,
      searchBlob: '${record.customerCode ?? ''} '
          '${record.customerName ?? ''} '
          '${record.invoiceType ?? ''} '
          '${record.queueJobId ?? ''} '
          '${record.lastError ?? ''} '
          '$statusLabel',
      gibStatusFieldLabel: statusField,
      gibStatusLabel: statusLabel,
    );
  }

  /// {@template invoice_untransferred_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<InvoiceUntransferredRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
