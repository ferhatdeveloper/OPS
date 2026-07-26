// Dosya Adı: stock_balance.dart
// Açıklama: WHMS / OPS ortak stok bakiyesi DTO (R1 — tek okuma sözleşmesi)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template stock_balance_bucket}
/// Stok kovası: merkez ambar vs plasiyer araç (van).
///
/// Kullanım örneği:
/// ```dart
/// final bucket = StockBalanceBucket.warehouse;
/// ```
/// {@endtemplate}
enum StockBalanceBucket {
  /// [warehouse]: `warehouse_stocks` (MRK / IAD vb.)
  warehouse,

  /// [van]: `vehicle_stocks` (ARC / araç)
  van,
}

/// {@template stock_balance}
/// Tek ürün + ambar (veya araç) bakiyesi.
///
/// Kullanım örneği:
/// ```dart
/// const bal = StockBalance(
///   productId: 'prod_1',
///   warehouseCode: 'MRK',
///   quantity: 12,
///   bucket: StockBalanceBucket.warehouse,
///   source: 'local',
/// );
/// ```
/// {@endtemplate}
class StockBalance {
  /// [productId]: Ürün kimliği
  final String productId;

  /// [warehouseCode]: Ambar kodu (MRK/ARC/IAD) veya araç etiketi
  final String warehouseCode;

  /// [quantity]: Ana birim miktar
  final double quantity;

  /// [bucket]: Ambar veya van kovası
  final StockBalanceBucket bucket;

  /// [source]: `local` | `logo` | `whms` (şimdilik local)
  final String source;

  /// [vehicleId]: Van kovası için araç id (opsiyonel)
  final String? vehicleId;

  /// {@macro stock_balance}
  const StockBalance({
    required this.productId,
    required this.warehouseCode,
    required this.quantity,
    required this.bucket,
    required this.source,
    this.vehicleId,
  });
}
