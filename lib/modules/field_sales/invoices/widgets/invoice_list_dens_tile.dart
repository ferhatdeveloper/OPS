// Dosya Adı: invoice_list_dens_tile.dart
// Açıklama: Fatura listesi dens satır — InvoiceListDensRecord → MbtQueueRow
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/invoice_list_dens_record.dart';

/// {@template invoice_list_dens_tile}
/// [InvoiceListDensRecord] → [MbtQueueRow] dens satırı.
///
/// Kullanım örneği:
/// ```dart
/// final row = InvoiceListDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class InvoiceListDensTile {
  InvoiceListDensTile._();

  /// {@template invoice_list_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı.
  ///
  /// Parametreler:
  /// - [record]: Fatura dens kaydı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    InvoiceListDensRecord record,
    AppLocalization l10n,
  ) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    final amount = record.totalAmount.toStringAsFixed(2);
    final customer = [
      if (record.customerCode.isNotEmpty) record.customerCode,
      if (record.customerName.isNotEmpty) record.customerName,
    ].join(' · ');
    final subtitle = l10n.translate(
      'field_sales.invoice_list_row_subtitle',
      args: {
        'customer': customer.isEmpty ? record.customerId : customer,
        'date': dateFmt.format(record.invoiceDate),
        'amount': amount,
        'status': record.status,
      },
    );

    return MbtQueueRow(
      id: record.id,
      side: record.docSide,
      date: record.invoiceDate,
      title: _displayDocNo(record),
      subtitle: subtitle,
      searchBlob: '${record.id} ${record.customerCode} '
          '${record.customerName} ${record.status} '
          '${record.invoiceType ?? ''} ${record.ettn ?? ''}',
      ettn: record.ettn,
      ettnLabel: record.ettn == null || record.ettn!.isEmpty
          ? null
          : l10n.translate('field_sales.ettn_label'),
      gibStatusLabel: record.gibStatus,
      gibStatusFieldLabel: record.gibStatus == null ||
              record.gibStatus!.isEmpty
          ? null
          : l10n.translate('field_sales.gib_status_label'),
    );
  }

  /// {@template invoice_list_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<InvoiceListDensRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }

  /// {@template invoice_list_dens_tile_display_doc_no}
  /// Fiş no gösterimi — not varsa not, yoksa id kısaltması.
  /// {@endtemplate}
  static String _displayDocNo(InvoiceListDensRecord record) {
    final note = (record.notes ?? '').trim();
    if (note.isNotEmpty && note.length <= 32) return note;
    if (record.id.length <= 12) return record.id;
    return record.id.substring(0, 8).toUpperCase();
  }
}
