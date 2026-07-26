// Dosya Adı: batch_expiry_dens_tile.dart
// Açıklama: Parti / SKT dens satır — stok · lot · SKT alanları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';
import '../model/batch_expiry_record.dart';
import '../model/batch_expiry_seed.dart';

/// {@template batch_expiry_dens_row}
/// Liste dens satırı (başlık + alt satırlar + arama blob).
///
/// Kullanım örneği:
/// ```dart
/// final row = BatchExpiryDensTile.toDensRow(record, l10n);
/// ```
/// {@endtemplate}
class BatchExpiryDensRow {
  /// [id]: Kayıt id
  final String id;

  /// [title]: Ürün kodu · ad
  final String title;

  /// [subtitle]: Lot · SKT · miktar
  final String subtitle;

  /// [statusLabel]: Durum etiketi
  final String statusLabel;

  /// [warehouseLabel]: Ambar satırı
  final String warehouseLabel;

  /// [searchBlob]: Arama metni
  final String searchBlob;

  /// [record]: Kaynak model
  final BatchExpiryRecord record;

  /// {@macro batch_expiry_dens_row}
  const BatchExpiryDensRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.warehouseLabel,
    required this.searchBlob,
    required this.record,
  });
}

/// {@template batch_expiry_dens_tile}
/// [BatchExpiryRecord] → dens liste satırı (lot + SKT).
///
/// Kullanım örneği:
/// ```dart
/// final rows = BatchExpiryDensTile.toDensRows(records, l10n);
/// ```
/// {@endtemplate}
class BatchExpiryDensTile {
  BatchExpiryDensTile._();

  /// {@template batch_expiry_dens_tile_to_dens_row}
  /// Model → dens liste satırı.
  ///
  /// Parametreler:
  /// - [record]: Parti / SKT kaydı
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [BatchExpiryDensRow]: Liste satırı
  /// {@endtemplate}
  static BatchExpiryDensRow toDensRow(
    BatchExpiryRecord record,
    AppLocalization l10n,
  ) {
    final lotLabel = l10n.translate('field_sales.batch_expiry_lot_label');
    final sktLabel = l10n.translate('field_sales.batch_expiry_skt_label');
    final qtyLabel = l10n.translate('field_sales.batch_expiry_qty_label');
    final sktText = BatchExpirySeed.formatDate(record.expiryDate);
    final qtyText =
        '${_formatQty(record.quantity)} ${record.unit}'.trim();
    final subtitle =
        '$lotLabel: ${record.lotNo} · $sktLabel: $sktText · '
        '$qtyLabel: $qtyText';
    final warehouse = [
      if ((record.warehouseCode ?? '').isNotEmpty) record.warehouseCode,
      if ((record.warehouseName ?? '').isNotEmpty) record.warehouseName,
    ].join(' · ');
    final title = [
      if (record.productCode.isNotEmpty) record.productCode,
      if (record.productName.isNotEmpty) record.productName,
    ].join(' · ');
    final status = record.resolvedStatus.label(l10n);

    return BatchExpiryDensRow(
      id: record.id,
      title: title.isEmpty ? record.lotNo : title,
      subtitle: subtitle,
      statusLabel: status,
      warehouseLabel: warehouse,
      searchBlob: '${record.productCode} ${record.productName} '
          '${record.lotNo} $sktText ${record.statusCode} $warehouse',
      record: record,
    );
  }

  /// {@template batch_expiry_dens_tile_rows}
  /// Kayıt listesini dens satırlarına çevirir.
  /// {@endtemplate}
  static List<BatchExpiryDensRow> toDensRows(
    List<BatchExpiryRecord> records,
    AppLocalization l10n,
  ) {
    return records
        .map((r) => toDensRow(r, l10n))
        .toList(growable: false);
  }

  /// {@template batch_expiry_dens_tile_format_qty}
  /// Miktar metni (gereksiz ondalık yok).
  /// {@endtemplate}
  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }
}
