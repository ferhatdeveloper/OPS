// Dosya Adı: einvoice_status_dens_tile.dart
// Açıklama: e-Fatura durum dens satır — fiş · ETTN · GİB
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/einvoice_status_record.dart';

/// {@template einvoice_status_dens_tile}
/// [EinvoiceStatusRecord] → [MbtQueueRow] dens ETTN/GİB alanları.
///
/// Kullanım örneği:
/// ```dart
/// final row = EinvoiceStatusDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class EinvoiceStatusDensTile {
  EinvoiceStatusDensTile._();

  /// {@template einvoice_status_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı (ETTN + GİB alanları dolu).
  ///
  /// Parametreler:
  /// - [record]: e-Fatura durum kaydı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    EinvoiceStatusRecord record,
    AppLocalization l10n,
  ) {
    final side = record.docSide == EinvoiceDocSide.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;
    final date = record.documentDate ??
        record.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final customer = [
      if ((record.customerCode ?? '').isNotEmpty) record.customerCode,
      if ((record.customerName ?? '').isNotEmpty) record.customerName,
    ].join(' · ');

    return MbtQueueRow(
      id: record.id,
      side: side,
      date: date,
      title: record.documentNo,
      subtitle: customer,
      searchBlob: '${record.ettn} ${record.gibStatusCode} '
          '${record.statusMessage ?? ''}',
      ettn: record.ettn,
      ettnLabel: l10n.translate('field_sales.ettn_label'),
      gibStatusLabel: record.gibStatus.label(l10n),
      gibStatusFieldLabel: l10n.translate('field_sales.gib_status_label'),
    );
  }

  /// {@template einvoice_status_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<EinvoiceStatusRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
