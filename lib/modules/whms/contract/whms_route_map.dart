// Dosya Adı: whms_route_map.dart
// Açıklama: OPS stub ↔ WHMS /whms/* route hizası (Depo Yönetimi menü)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_route_alignment}
/// Menü/route hizası — `fs_whms` alt seed yalnız `/whms/*`.
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

  // --- WHMS (Depo Yönetimi — field_sales menüsüne gömülmez) ---

  /// [whmsShell]: WHMS ana giriş
  static const String whmsShell = '/whms';

  /// [whmsOrdersHub]: Emirler kategorisi
  static const String whmsOrdersHub = '/whms/orders-hub';

  /// [whmsOrders]: Emir listesi dens
  static const String whmsOrders = '/whms/orders';

  /// [whmsOrderCreate]: Yeni emir dens
  static const String whmsOrderCreate = '/whms/orders/create';

  /// [whmsOrderDetail]: Emir detay dens
  static const String whmsOrderDetail = '/whms/orders/detail';

  /// [whmsOrderReceipt]: Mal kabul / putaway yürütme dens
  static const String whmsOrderReceipt = '/whms/orders/receipt';

  /// [whmsReceiptList]: Mal kabul emir listesi
  static const String whmsReceiptList = '/whms/receipt';

  /// [whmsPutaway]: Yerleştirme emir listesi
  static const String whmsPutaway = '/whms/putaway';

  /// [whmsPickList]: Toplama emir listesi
  static const String whmsPickList = '/whms/pick-list';

  /// [whmsPick]: Pick emir yürütme dens
  static const String whmsPick = '/whms/pick';

  /// [whmsShipping]: Sevk / son kontrol listesi
  static const String whmsShipping = '/whms/shipping';

  /// [whmsReturns]: İade dens
  static const String whmsReturns = '/whms/returns';

  /// [whmsDefs]: Tanımlamalar hub
  static const String whmsDefs = '/whms/defs';

  /// [whmsLocations]: Lokasyon master dens
  static const String whmsLocations = '/whms/locations';

  /// [whmsFifo]: FIFO/FEFO kural dens CRUD
  static const String whmsFifo = '/whms/fifo';

  /// [whmsMultiWarehouse]: Merkez ambar master dens
  static const String whmsMultiWarehouse = '/whms/warehouses';

  /// [whmsVehicleTypes]: Araç tipi dens
  static const String whmsVehicleTypes = '/whms/vehicle-types';

  /// [whmsVehicles]: Araç dens
  static const String whmsVehicles = '/whms/vehicles';

  /// [whmsStockHub]: Stok hub
  static const String whmsStockHub = '/whms/stock';

  /// [whmsStockQuery]: Merkez stok sorgu dens
  static const String whmsStockQuery = '/whms/stock-query';

  /// [whmsLot]: Lot / SKT dens
  static const String whmsLot = '/whms/lot';

  /// [whmsReservation]: Rezervasyon dens
  static const String whmsReservation = '/whms/reservation';

  /// [whmsTransfer]: Merkez transfer emir dens
  static const String whmsTransfer = '/whms/transfer';

  /// [whmsCount]: Merkez sayım
  static const String whmsCount = '/whms/count';

  /// [whmsCountExecute]: Sayım yürütme (satır / barkod)
  static const String whmsCountExecute = '/whms/count/execute';

  /// [whmsReportsHub]: Raporlar hub
  static const String whmsReportsHub = '/whms/reports-hub';

  /// [whmsReports]: Merkez depo KPI
  static const String whmsReports = '/whms/reports';

  /// [whmsReportsOrderPerf]: Emir performansı
  static const String whmsReportsOrderPerf = '/whms/reports/order-perf';

  /// [whmsReportsCountVar]: Sayım fark
  static const String whmsReportsCountVar = '/whms/reports/count-var';

  /// [whmsSystem]: Sistem / sync stub
  static const String whmsSystem = '/whms/system';

  /// [whmsLabels]: Etiket / cihaz hub
  static const String whmsLabels = '/whms/labels';

  /// [whmsDevices]: Cihaz / terminal dens
  static const String whmsDevices = '/whms/devices';

  /// [whmsPackageTypes]: Paket tipi dens
  static const String whmsPackageTypes = '/whms/labels/packages';

  /// [whmsTares]: Dara dens
  static const String whmsTares = '/whms/labels/tares';

  /// [whmsLabelTemplates]: Etiket şablon dens
  static const String whmsLabelTemplates = '/whms/labels/templates';

  /// Legacy inventory — WHMS ile karıştırılmamalı
  static const String legacyInventoryWarehouses = '/inventory/warehouses';

  /// OPS stub → WHMS hedefi.
  static const Map<String, String> opsStubToWhmsTarget = {
    opsMultiWarehouse: whmsMultiWarehouse,
    opsWarehouseStockQuery: whmsStockQuery,
    opsWarehouseTransfer: whmsTransfer,
    opsStockMovement: whmsTransfer,
    opsStockProduction: whmsShell,
    opsBatchExpiry: whmsLot,
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

  /// Depo Yönetimi (`fs_whms`) alt seed → WHMS-native route.
  static const Map<String, String> fsWhmsMenuSeed = {
    'sub_whms_orders': whmsOrdersHub,
    'sub_whms_orders_list': whmsOrders,
    'sub_whms_receipt': whmsReceiptList,
    'sub_whms_putaway': whmsPutaway,
    'sub_whms_pick': whmsPickList,
    'sub_whms_shipping': whmsShipping,
    'sub_whms_returns': whmsReturns,
    'sub_whms_defs': whmsDefs,
    'sub_whms_fifo': whmsFifo,
    'sub_whms_warehouses': whmsMultiWarehouse,
    'sub_whms_vehicle_types': whmsVehicleTypes,
    'sub_whms_vehicles': whmsVehicles,
    'sub_whms_stock': whmsStockHub,
    'sub_whms_count': whmsCount,
    'sub_whms_transfer': whmsTransfer,
    'sub_whms_query': whmsStockQuery,
    'sub_whms_lot': whmsLot,
    'sub_whms_reservation': whmsReservation,
    'sub_whms_reports': whmsReportsHub,
    'sub_whms_reports_kpi': whmsReports,
    'sub_whms_reports_perf': whmsReportsOrderPerf,
    'sub_whms_reports_count': whmsReportsCountVar,
    'sub_whms_system': whmsSystem,
    'sub_whms_devices': whmsDevices,
    'sub_whms_labels': whmsLabels,
    'whms_locations': whmsLocations,
    'sub_whms_locations': whmsLocations,
    'whms_fifo': whmsFifo,
  };

  /// Route OPS stub mu?
  static bool isOpsStub(String route) =>
      opsStubToWhmsTarget.containsKey(route) || route == opsStockWarehouse;

  /// OPS stub için WHMS hedefi.
  static String? futureWhmsTarget(String opsRoute) =>
      opsStubToWhmsTarget[opsRoute];
}
