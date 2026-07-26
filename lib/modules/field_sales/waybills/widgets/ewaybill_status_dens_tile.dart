// Dosya Adı: ewaybill_status_dens_tile.dart
// Açıklama: e-İrsaliye durum dens satır — fiş · ETTN · GİB
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/ewaybill_status_record.dart';

/// {@template ewaybill_status_dens_tile}
/// [EwaybillStatusRecord] → [MbtQueueRow] dens ETTN/GİB alanları.
///
/// Kullanım örneği:
/// ```dart
/// final row = EwaybillStatusDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class EwaybillStatusDensTile {
  EwaybillStatusDensTile._();

  /// {@template ewaybill_status_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı (ETTN + GİB alanları dolu).
  ///
  /// Parametreler:
  /// - [record]: e-İrsaliye durum kaydı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    EwaybillStatusRecord record,
    AppLocalization l10n,
  ) {
    final side = record.docSide == EwaybillDocSide.purchase
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

  /// {@template ewaybill_status_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<EwaybillStatusRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
