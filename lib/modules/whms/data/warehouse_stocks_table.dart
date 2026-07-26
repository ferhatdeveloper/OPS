// Dosya Adı: warehouse_stocks_table.dart
// Açıklama: warehouse_stocks tablo adı ve seed yardımcıları (WHMS Faz 1)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template warehouse_stocks_table}
/// Merkez ambar bakiyesi tablosu — araç stoğundan ayrı.
///
/// Kullanım örneği:
/// ```dart
/// print(WarehouseStocksTable.name); // warehouse_stocks
/// ```
/// {@endtemplate}
class WarehouseStocksTable {
  WarehouseStocksTable._();

  /// [name]: SQLite tablo adı
  static const String name = 'warehouse_stocks';

  /// PK bileşenleri
  static const String colWarehouseCode = 'warehouse_code';
  static const String colProductId = 'product_id';
  static const String colQuantity = 'quantity';
}
