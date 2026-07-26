// Dosya Adı: whms_route_map.dart
// Açıklama: OPS fs_stock stub route ↔ gelecekteki WHMS namespace hizası
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template whms_route_alignment}
/// Menü/route hizası — Faz 1: OPS stub kalır; WHMS ayrı namespace.
///
/// Kullanım örneği:
/// ```dart
/// final ops = WhmsRouteMap.opsMultiWarehouse;
/// final future = WhmsRouteMap.whmsMultiWarehouse;
/// ```
/// {@endtemplate}
class WhmsRouteMap {
  WhmsRouteMap._();

  // --- OPS (field_sales seed — plasiyer menüsü) ---

  /// [opsMultiWarehouse]: Çoklu ambar dens (OPS)
  static const String opsMultiWarehouse = '/field-sales/multi-warehouse';

  /// [opsWarehouseStockQuery]: Ambar stok sorgu stub
  static const String opsWarehouseStockQuery =
      '/field-sales/warehouse-stock-query';

  /// [opsWarehouseTransfer]: Ambar transfer stub
  static const String opsWarehouseTransfer =
      '/field-sales/warehouse-transfer';

  /// [opsStockWarehouse]: Ambar fişi (köprü)
  static const String opsStockWarehouse = '/field-sales/stock-warehouse';

  /// [opsStockMovement]: Stok hareket stub
  static const String opsStockMovement = '/field-sales/stock-movement';

  /// [opsBatchExpiry]: Parti / SKT
  static const String opsBatchExpiry = '/field-sales/batch-expiry';

  /// [opsConsignment]: Konsinye
  static const String opsConsignment = '/field-sales/consignment';

  /// [opsStockProduction]: Üretimden giriş
  static const String opsStockProduction = '/field-sales/stock-production';

  // --- WHMS (gelecek — field_sales menüsüne gömülmez) ---

  /// [whmsShell]: WHMS ana giriş (Faz 2+)
  static const String whmsShell = '/whms';

  /// [whmsMultiWarehouse]: Merkez çoklu depo
  static const String whmsMultiWarehouse = '/whms/warehouses';

  /// [whmsStockQuery]: Merkez stok sorgu
  static const String whmsStockQuery = '/whms/stock-query';

  /// [whmsTransfer]: Merkez depolar arası transfer
  static const String whmsTransfer = '/whms/transfer';

  /// [whmsCount]: Merkez sayım
  static const String whmsCount = '/whms/count';

  /// Legacy inventory — WHMS ile karıştırılmamalı
  static const String legacyInventoryWarehouses = '/inventory/warehouses';

  /// OPS stub → gelecekteki WHMS hedefi (Faz 1 yalnız sözleşme).
  static const Map<String, String> opsStubToWhmsTarget = {
    opsMultiWarehouse: whmsMultiWarehouse,
    opsWarehouseStockQuery: whmsStockQuery,
    opsWarehouseTransfer: whmsTransfer,
    opsStockMovement: whmsTransfer,
    opsStockProduction: whmsShell,
    opsBatchExpiry: whmsShell,
    opsConsignment: whmsShell,
  };

  /// Seed uuid → OPS route (fs_stock WHMS adayları).
  static const Map<String, String> fsStockWhmsCandidateSeed = {
    'sub_stk_multi_wh': opsMultiWarehouse,
    'sub_stk_wh_query': opsWarehouseStockQuery,
    'sub_stk_wh_transfer': opsWarehouseTransfer,
    'sub_stk_movement': opsStockMovement,
    'sub_stk_batch': opsBatchExpiry,
    'sub_stk_consign': opsConsignment,
    'sub_stk_production': opsStockProduction,
    'sub_stk_warehouse': opsStockWarehouse,
  };

  /// {@template whms_route_map_is_ops_stub}
  /// Route OPS stub mu?
  ///
  /// Parametreler:
  /// - [route]: Named route
  ///
  /// Dönüş değeri:
  /// - [bool]: true ise field_sales stub
  /// {@endtemplate}
  static bool isOpsStub(String route) =>
      opsStubToWhmsTarget.containsKey(route) || route == opsStockWarehouse;

  /// {@template whms_route_map_future_target}
  /// OPS stub için gelecekteki WHMS hedefi.
  ///
  /// Parametreler:
  /// - [opsRoute]: OPS named route
  ///
  /// Dönüş değeri:
  /// - [String]: WHMS route veya null
  /// {@endtemplate}
  static String? futureWhmsTarget(String opsRoute) =>
      opsStubToWhmsTarget[opsRoute];
}
