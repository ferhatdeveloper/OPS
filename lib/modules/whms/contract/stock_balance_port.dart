// Dosya Adı: stock_balance_port.dart
// Açıklama: Tek stok bakiyesi okuma portu (WHMS prep R1)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'stock_balance.dart';

/// {@template stock_balance_port}
/// Logo / WHMS / yerel SQLite için tek bakiye sözleşmesi.
///
/// Araç stoğu her zaman [StockBalanceBucket.van] olarak ayrı kalır.
///
/// Kullanım örneği:
/// ```dart
/// final port = LocalWarehouseStockBalancePort(db);
/// final bal = await port.getBalance(
///   productId: 'prod_1',
///   warehouseCode: 'MRK',
/// );
/// ```
/// {@endtemplate}
abstract class StockBalancePort {
  /// {@template stock_balance_port_get_balance}
  /// Ürün + ambar kodu için bakiye okur.
  ///
  /// Parametreler:
  /// - [productId]: Ürün id
  /// - [warehouseCode]: Ambar kodu (MRK/ARC/IAD)
  /// - [vehicleId]: ARC / van için zorunlu olabilir
  ///
  /// Dönüş değeri:
  /// - [StockBalance]: Bakiye; yoksa quantity = 0
  /// {@endtemplate}
  Future<StockBalance> getBalance({
    required String productId,
    required String warehouseCode,
    String? vehicleId,
  });

  /// {@template stock_balance_port_list_by_warehouse}
  /// Ambar kodundaki tüm bakiyeler.
  ///
  /// Parametreler:
  /// - [warehouseCode]: Ambar kodu
  /// - [vehicleId]: Van kovası için
  ///
  /// Dönüş değeri:
  /// - [List]: [StockBalance] listesi
  /// {@endtemplate}
  Future<List<StockBalance>> listByWarehouse({
    required String warehouseCode,
    String? vehicleId,
  });
}
