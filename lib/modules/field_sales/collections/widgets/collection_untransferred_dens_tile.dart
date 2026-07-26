// Dosya Adı: collection_untransferred_dens_tile.dart
// Açıklama: Transfer edilmeyen tahsilat dens → MbtQueueRow
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/collection_untransferred_record.dart';
import '../model/finance_movement_type.dart';

/// {@template collection_untransferred_dens_tile}
/// [CollectionUntransferredRecord] → [MbtQueueRow] dens kuyruk bağlama.
///
/// Kullanım örneği:
/// ```dart
/// final row = CollectionUntransferredDensTile.toQueueRow(record, l10n);
/// ```
/// {@endtemplate}
class CollectionUntransferredDensTile {
  CollectionUntransferredDensTile._();

  /// {@template collection_untransferred_dens_tile_to_queue_row}
  /// Model → kuyruk dens satırı.
  ///
  /// Parametreler:
  /// - [record]: Transfer edilmeyen tahsilat dens kaydı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [MbtQueueRow]: Liste satırı
  /// {@endtemplate}
  static MbtQueueRow toQueueRow(
    CollectionUntransferredRecord record,
    AppLocalization l10n,
  ) {
    final side = record.docSide == CollectionUntransferredDocSide.purchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;
    final type = FinanceMovementType.fromStorage(record.paymentType);
    final typeLabel = l10n.translate(type.titleL10nKey);
    final amountText = record.amount.toStringAsFixed(2);
    final customer = [
      if (record.customerCode.trim().isNotEmpty) record.customerCode.trim(),
      if (record.customerName.trim().isNotEmpty) record.customerName.trim(),
    ].join(' · ');
    final subtitleParts = <String>[
      if (customer.isNotEmpty) customer,
      '$amountText ${record.currencyCode}',
      typeLabel,
    ];

    return MbtQueueRow(
      id: record.id,
      side: side,
      date: record.collectionDate,
      title: record.documentNo,
      subtitle: subtitleParts.join(' · '),
      searchBlob: '${record.documentNo} ${record.customerCode} '
          '${record.customerName} ${record.paymentType} '
          '${record.cashCode ?? ''} ${record.notes ?? ''} $amountText',
    );
  }

  /// {@template collection_untransferred_dens_tile_rows}
  /// Kayıt listesini dens kuyruk satırlarına çevirir.
  /// {@endtemplate}
  static List<MbtQueueRow> toQueueRows(
    List<CollectionUntransferredRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .where((r) => !r.isSynced)
        .map((r) => toQueueRow(r, l10n))
        .toList(growable: false);
  }
}
