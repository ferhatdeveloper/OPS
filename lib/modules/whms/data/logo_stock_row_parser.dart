// Dosya Adı: logo_stock_row_parser.dart
// Açıklama: Logo getStock / inventory satırlarını StockBalance alanlarına çevirir
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../mapper/whms_payload_mapper.dart';

/// {@template logo_stock_row_parser}
/// Logo REST stok satırı alanlarını normalize eder (CODE/QUANTITY/WAREHOUSE…).
///
/// Kullanım örneği:
/// ```dart
/// final qty = LogoStockRowParser.quantity({'QUANTITY': 12});
/// // qty == 12.0
/// ```
/// {@endtemplate}
class LogoStockRowParser {
  /// {@macro logo_stock_row_parser}
  const LogoStockRowParser._();

  /// {@template logo_stock_row_parser_quantity}
  /// Miktar alanını okur.
  ///
  /// Parametreler:
  /// - [row]: Logo satırı
  ///
  /// Dönüş değeri:
  /// - [double]: Miktar; yoksa 0
  /// {@endtemplate}
  static double quantity(Map<String, dynamic> row) {
    for (final key in const [
      'quantity',
      'QUANTITY',
      'onhand',
      'ONHAND',
      'on_hand',
      'stock',
      'STOCK',
      'stock_quantity',
      'amount',
      'AMOUNT',
      'remamount',
      'REMAMOUNT',
    ]) {
      final v = row[key];
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v.replaceAll(',', '.'));
        if (p != null) return p;
      }
    }
    return 0;
  }

  /// {@template logo_stock_row_parser_item_code}
  /// Ürün / malzeme kodu.
  ///
  /// Parametreler:
  /// - [row]: Logo satırı
  ///
  /// Dönüş değeri:
  /// - [String]: Kod; yoksa boş
  /// {@endtemplate}
  static String itemCode(Map<String, dynamic> row) {
    for (final key in const [
      'item_code',
      'ITEM_CODE',
      'code',
      'CODE',
      'product_code',
      'PRODUCT_CODE',
      'MASTER_CODE',
      'product_id',
      'PRODUCT_ID',
      'logicalref',
      'LOGICALREF',
      'ItemCode',
      'itemcode',
    ]) {
      final v = row[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  /// {@template logo_stock_row_parser_warehouse_code}
  /// Ambar kodu (MRK/IAD normalize).
  ///
  /// Parametreler:
  /// - [row]: Logo satırı
  /// - [fallback]: Satırda yoksa kullanılacak kod
  ///
  /// Dönüş değeri:
  /// - [String]: Normalize ambar kodu
  /// {@endtemplate}
  static String warehouseCode(
    Map<String, dynamic> row, {
    String? fallback,
  }) {
    for (final key in const [
      'warehouse_code',
      'WAREHOUSE_CODE',
      'warehouse',
      'WAREHOUSE',
      'wh_code',
      'WH_CODE',
      'sourceindex',
      'SOURCEINDEX',
    ]) {
      final v = row[key]?.toString().trim();
      if (v != null && v.isNotEmpty) {
        return WhmsPayloadMapper.normalizeWarehouseCode(v);
      }
    }
    if (fallback != null && fallback.isNotEmpty) {
      return WhmsPayloadMapper.normalizeWarehouseCode(fallback);
    }
    return '';
  }

  /// {@template logo_stock_row_parser_matches_warehouse}
  /// Satırın hedef ambara ait olup olmadığını kontrol eder.
  ///
  /// Parametreler:
  /// - [row]: Logo satırı
  /// - [warehouseCode]: Hedef ambar
  ///
  /// Dönüş değeri:
  /// - [bool]: Eşleşme; satırda ambar yoksa true (tek toplam varsayımı)
  /// {@endtemplate}
  static bool matchesWarehouse(
    Map<String, dynamic> row,
    String warehouseCode,
  ) {
    final code = warehouseCode.trim().toUpperCase();
    final rowWh = warehouseCodeFromRowOrEmpty(row);
    if (rowWh.isEmpty) return true;
    return rowWh == code;
  }

  /// {@template logo_stock_row_parser_warehouse_code_from_row_or_empty}
  /// Satırdaki ham ambar; yoksa boş (fallback yok).
  ///
  /// Parametreler:
  /// - [row]: Logo satırı
  ///
  /// Dönüş değeri:
  /// - [String]: Normalize kod veya boş
  /// {@endtemplate}
  static String warehouseCodeFromRowOrEmpty(Map<String, dynamic> row) {
    for (final key in const [
      'warehouse_code',
      'WAREHOUSE_CODE',
      'warehouse',
      'WAREHOUSE',
      'wh_code',
      'WH_CODE',
      'sourceindex',
      'SOURCEINDEX',
    ]) {
      final v = row[key]?.toString().trim();
      if (v != null && v.isNotEmpty) {
        return WhmsPayloadMapper.normalizeWarehouseCode(v);
      }
    }
    return '';
  }
}
