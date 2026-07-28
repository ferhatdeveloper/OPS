// Dosya Adı: whms_orders_table.dart
// Açıklama: whms_orders / whms_order_lines tablo ve kolon sabitleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_orders_table}
/// Emir header tablosu adı / kolonları.
///
/// Kullanım örneği:
/// ```dart
/// print(WhmsOrdersTable.name); // whms_orders
/// ```
/// {@endtemplate}
class WhmsOrdersTable {
  WhmsOrdersTable._();

  /// [name]: SQLite tablo adı
  static const String name = 'whms_orders';

  /// [colId]: PK
  static const String colId = 'id';

  /// [colOrderType]: Emir tipi kodu
  static const String colOrderType = 'order_type';

  /// [colStatus]: Yaşam döngüsü
  static const String colStatus = 'status';

  /// [colWarehouseCode]: Ana ambar
  static const String colWarehouseCode = 'warehouse_code';

  /// [colOnay]: ONAY 0–4
  static const String colOnay = 'ONAY';

  /// [colIsSynced]: Sync
  static const String colIsSynced = 'is_synced';

  /// [colIsDeleted]: Soft delete
  static const String colIsDeleted = 'is_deleted';
}

/// {@template whms_order_lines_table}
/// Emir satır tablosu adı / kolonları.
/// {@endtemplate}
class WhmsOrderLinesTable {
  WhmsOrderLinesTable._();

  /// [name]: SQLite tablo adı
  static const String name = 'whms_order_lines';

  /// [colId]: PK
  static const String colId = 'id';

  /// [colOrderId]: Üst emir FK
  static const String colOrderId = 'order_id';

  /// [colProductCode]: Ürün kodu
  static const String colProductCode = 'product_code';

  /// [colLocationCode]: Lokasyon
  static const String colLocationCode = 'location_code';

  /// [colOnay]: ONAY
  static const String colOnay = 'ONAY';
}
