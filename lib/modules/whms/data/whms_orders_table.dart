// Dosya Adı: whms_orders_table.dart
// Açıklama: whms_orders / whms_order_lines tablo adı sabitleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_orders_table}
/// WHMS emir tabloları — ad ve sütun sabitleri.
///
/// Kullanım örneği:
/// ```dart
/// print(WhmsOrdersTable.name); // whms_orders
/// print(WhmsOrdersTable.linesName); // whms_order_lines
/// ```
/// {@endtemplate}
class WhmsOrdersTable {
  WhmsOrdersTable._();

  /// [name]: Emir başlık tablosu
  static const String name = 'whms_orders';

  /// [linesName]: Emir satır tablosu
  static const String linesName = 'whms_order_lines';

  // --- whms_orders sütunları ---

  /// [colId]: PK
  static const String colId = 'id';

  /// [colOrderType]: Emir tipi wire
  static const String colOrderType = 'order_type';

  /// [colStatus]: Yaşam durumu
  static const String colStatus = 'status';

  /// [colWarehouseCode]: Ambar
  static const String colWarehouseCode = 'warehouse_code';

  /// [colToWarehouseCode]: Hedef ambar
  static const String colToWarehouseCode = 'to_warehouse_code';

  /// [colToVehicleId]: Hedef araç
  static const String colToVehicleId = 'to_vehicle_id';

  /// [colAssignedUserId]: Atanan kullanıcı
  static const String colAssignedUserId = 'assigned_user_id';

  /// [colDeviceId]: Cihaz
  static const String colDeviceId = 'device_id';

  /// [colNotes]: Not
  static const String colNotes = 'notes';

  /// [colRequireSerial]: Emir seri zorunlu flag
  static const String colRequireSerial = 'require_serial';

  /// [colOrderDate]: Emir tarihi
  static const String colOrderDate = 'order_date';

  /// [colOnay]: Sync onay 0–4
  static const String colOnay = 'ONAY';

  /// [colIsSynced]: Sync bayrağı
  static const String colIsSynced = 'is_synced';

  /// [colIsDeleted]: Soft delete
  static const String colIsDeleted = 'is_deleted';

  /// [colCreatedAt]: Oluşturma
  static const String colCreatedAt = 'created_at';

  /// [colUpdatedAt]: Güncelleme
  static const String colUpdatedAt = 'updated_at';

  // --- whms_order_lines sütunları ---

  /// [colLineOrderId]: Satır → emir FK
  static const String colLineOrderId = 'order_id';

  /// [colLineNo]: Satır no
  static const String colLineNo = 'line_no';

  /// [colProductId]: Ürün id
  static const String colProductId = 'product_id';

  /// [colProductCode]: Ürün kodu
  static const String colProductCode = 'product_code';

  /// [colProductName]: Ürün adı
  static const String colProductName = 'product_name';

  /// [colQuantity]: Miktar
  static const String colQuantity = 'quantity';

  /// [colUnitName]: Birim
  static const String colUnitName = 'unit_name';

  /// [colLocationCode]: Lokasyon
  static const String colLocationCode = 'location_code';

  /// [colLotNo]: Lot
  static const String colLotNo = 'lot_no';

  /// [colExpiryDate]: SKT
  static const String colExpiryDate = 'expiry_date';

  /// [colRouteSeq]: Rota sırası
  static const String colRouteSeq = 'route_seq';
}
