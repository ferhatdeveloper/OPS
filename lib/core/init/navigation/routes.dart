// Dosya Adı: routes.dart
// Açıklama: App named route sabitleri ve generateRoute (menü seed ile hizalı)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../modules/field_sales/ai_insights/view/ai_insights_screen.dart';
import '../../../modules/field_sales/ai_insights/view/supplier_purchase_request_list_screen.dart';
import '../../../modules/field_sales/ai_invoice_scan/view/invoice_scan_screen.dart';
import '../../../modules/field_sales/ai_reports/view/ai_dynamic_report_screen.dart';
import '../../../modules/field_sales/ai_social/view/social_media_image_screen.dart';
import '../../../modules/field_sales/ai_vehicle_vision/view/vehicle_vision_screen.dart';
import '../../../modules/field_sales/ai_vision_competitor/view/competitor_shelf_vision_screen.dart';
import '../../../modules/field_sales/announcements/view/announcements_screen.dart';
import '../../../modules/field_sales/barcode/view/barcode_scan_screen.dart';
import '../../../modules/field_sales/campaigns/view/campaign_management_screen.dart';
import '../../../modules/field_sales/campaigns/view/campaigns_list_screen.dart';
import '../../../modules/field_sales/collections/view/bank_card_list_screen.dart';
import '../../../modules/field_sales/collections/view/bank_deposit_screen.dart';
import '../../../modules/field_sales/collections/view/cash_card_detail_screen.dart';
import '../../../modules/field_sales/collections/view/cash_card_list_screen.dart';
import '../../../modules/field_sales/collections/view/cash_count_screen.dart';
import '../../../modules/field_sales/collections/view/check_list_screen.dart';
import '../../../modules/field_sales/collections/view/collection_customer_selection_screen.dart';
import '../../../modules/field_sales/collections/view/collection_entry_screen.dart';
import '../../../modules/field_sales/collections/view/collections_transferred_screen.dart';
import '../../../modules/field_sales/collections/view/collections_untransferred_screen.dart';
import '../../../modules/field_sales/collections/view/credit_card_collection_screen.dart';
import '../../../modules/field_sales/collections/view/payment_entry_screen.dart';
import '../../../modules/field_sales/collections/view/promissory_note_list_screen.dart';
import '../../../modules/field_sales/collections/view/promissory_note_screen.dart';
import '../../../modules/field_sales/collections/view/virman_screen.dart';
import '../../../modules/field_sales/collections/view/wire_transfer_screen.dart';
import '../../../modules/field_sales/companies/view/company_list_screen.dart';
import '../../../modules/field_sales/currency/view/currency_rates_screen.dart';
import '../../../modules/field_sales/customers/view/customer_extract_screen.dart';
import '../../../modules/field_sales/customers/view/customer_reconciliation_screen.dart';
import '../../../modules/field_sales/customers/view/customer_form_screen.dart';
import '../../../modules/field_sales/customers/view/customer_list_screen.dart';
import '../../../modules/field_sales/customers/view/customer_risk_screen.dart';
import '../../../modules/field_sales/delivery/view/delivery_hold_screen.dart';
import '../../../modules/field_sales/delivery/view/delivery_list_screen.dart';
import '../../../modules/field_sales/delivery/view/delivery_untransferred_screen.dart';
import '../../../modules/field_sales/delivery/view/partial_delivery_screen.dart';
import '../../../modules/field_sales/documents/view/document_share_screen.dart';
import '../../../modules/field_sales/eod/view/day_close_screen.dart';
import '../../../modules/field_sales/eod/view/day_open_screen.dart';
import '../../../modules/field_sales/expenses/view/expense_entry_screen.dart';
import '../../../modules/field_sales/favorites/view/favorites_screen.dart';
import '../../../modules/field_sales/gps/view/geofence_settings_screen.dart';
import '../../../modules/field_sales/gps/view/gps_tracking_screen.dart';
import '../../../modules/field_sales/gps/view/vehicle_camera_broadcast_screen.dart';
import '../../../modules/field_sales/gps/view/vehicle_camera_monitor_screen.dart';
import '../../../modules/field_sales/gps/view/vehicle_camera_settings_screen.dart';
import '../../../modules/field_sales/gps/view/route_map_screen.dart'
    as gps_route_map;
import '../../../modules/field_sales/help/view/about_app_screen.dart';
import '../../../modules/field_sales/help/view/help_faq_screen.dart';
import '../../../modules/field_sales/invoices/view/einvoice_status_screen.dart';
import '../../../modules/field_sales/invoices/view/invoice_approval_screen.dart';
import '../../../modules/field_sales/invoices/view/invoice_customer_selection_screen.dart';
import '../../../modules/field_sales/invoices/view/invoice_entry_screen.dart';
import '../../../modules/field_sales/invoices/view/invoice_list_mbt_screen.dart';
import '../../../modules/field_sales/invoices/view/invoices_pending_screen.dart';
import '../../../modules/field_sales/invoices/view/invoices_untransferred_screen.dart';
import '../../../modules/field_sales/maps/view/in_app_route_map_screen.dart';
import '../../../modules/field_sales/maps/view/map_screen.dart';
import '../../../modules/field_sales/maps/view/offline_map_download_screen.dart';
import '../../../modules/field_sales/merchandising/view/audit_form_screen.dart';
import '../../../modules/field_sales/notifications/view/notification_center_screen.dart';
import '../../../modules/field_sales/other/view/day_status_screen.dart';
import '../../../modules/field_sales/other/view/gallery_screen.dart';
import '../../../modules/field_sales/orders/view/discount_approval_screen.dart';
import '../../../modules/field_sales/orders/view/order_approval_screen.dart';
import '../../../modules/field_sales/orders/view/order_customer_selection_screen.dart';
import '../../../modules/field_sales/orders/view/order_entry_screen.dart';
import '../../../modules/field_sales/orders/view/order_list_screen.dart';
import '../../../modules/field_sales/orders/view/order_tracking_screen.dart';
import '../../../modules/field_sales/orders/view/orders_pending_screen.dart';
import '../../../modules/field_sales/orders/view/orders_untransferred_screen.dart';
import '../../../modules/field_sales/orders/view/sample_giveaway_screen.dart';
import '../../../modules/field_sales/orders/model/order_model.dart';
import '../../../modules/field_sales/pricing/view/price_list_screen.dart';
import '../../../modules/field_sales/printing/view/printer_settings_screen.dart';
import '../../../modules/field_sales/products/view/product_catalog_screen.dart';
import '../../../modules/field_sales/products/view/product_detail_screen.dart';
import '../../../modules/field_sales/reports/view/collection_report_screen.dart';
import '../../../modules/field_sales/reports/view/logo_reports_screen.dart';
import '../../../modules/field_sales/reports/view/report_backup_screen.dart';
import '../../../modules/field_sales/reports/view/report_category_list_screen.dart';
import '../../../modules/field_sales/reports/view/report_layout_designer_screen.dart';
import '../../../modules/field_sales/reports/view/report_parameters_screen.dart';
import '../../../modules/field_sales/reports/view/report_pdf_viewer_screen.dart';
import '../../../modules/field_sales/reports/view/sales_report_screen.dart';
import '../../../modules/field_sales/reports/view/visit_report_screen.dart';
import '../../../modules/field_sales/reports/model/mbt_report_category.dart';
import '../../../modules/field_sales/returns/view/return_entry_screen.dart';
import '../../../modules/field_sales/returns/view/returns_list_screen.dart';
import '../../../modules/field_sales/routes/view/route_plan_screen.dart';
import '../../../modules/field_sales/routes/view/visit_existing_customer_screen.dart';
import '../../../modules/field_sales/routes/view/visit_form_screen.dart';
import '../../../modules/field_sales/routes/view/visit_detail_screen.dart';
import '../../../modules/field_sales/routes/view/visit_history_screen.dart';
import '../../../modules/field_sales/routes/view/visit_new_customer_screen.dart';
import '../../../modules/field_sales/routes/view/visit_photo_screen.dart';
import '../../../modules/field_sales/routes/view/visit_untransferred_screen.dart';
import '../../../modules/field_sales/routes/view/weekly_route_plan_screen.dart';
import '../../../modules/field_sales/reports/view/report_logo_settings_screen.dart';
import '../../../modules/field_sales/ai/view/ai_settings_screen.dart';
import '../../../modules/field_sales/ai/view/ai_voice_chat_screen.dart';
import '../../../modules/field_sales/settings/view/appearance_settings_screen.dart';
import '../../../modules/field_sales/settings/view/language_picker_screen.dart';
import '../../../modules/field_sales/settings/view/profile_settings_screen.dart';
import '../../../modules/field_sales/settings/view/send_info_screen.dart';
import '../../../modules/field_sales/settings/view/voucher_defaults_settings_screen.dart';
import '../../../modules/field_sales/reports/view/dashboard_screen.dart';
import '../../../modules/field_sales/stock/view/batch_expiry_screen.dart';
import '../../../modules/field_sales/stock/view/consignment_screen.dart';
import '../../../modules/field_sales/stock/view/multi_warehouse_screen.dart';
import '../../../modules/field_sales/stock/view/price_check_screen.dart';
import '../../../modules/field_sales/stock/view/production_receipt_screen.dart';
import '../../../modules/field_sales/stock/view/stock_count_screen.dart';
import '../../../modules/field_sales/stock/view/stock_movement_screen.dart';
import '../../../modules/field_sales/stock/view/stock_transfer_list_screen.dart';
import '../../../modules/field_sales/stock/view/warehouse_receipt_screen.dart';
import '../../../modules/field_sales/stock/view/warehouse_stock_query_screen.dart';
import '../../../modules/field_sales/stock/view/warehouse_transfer_screen.dart';
import '../../../modules/whms/count/view/whms_count_execute_screen.dart';
import '../../../modules/whms/count/view/whms_count_screen.dart';
import '../../../modules/whms/count/model/whms_count_order.dart';
import '../../../modules/whms/devices/view/whms_device_list_screen.dart';
import '../../../modules/whms/fifo/view/whms_fifo_rule_list_screen.dart';
import '../../../modules/whms/labels/view/whms_label_template_list_screen.dart';
import '../../../modules/whms/labels/view/whms_labels_hub_screen.dart';
import '../../../modules/whms/labels/view/whms_package_type_list_screen.dart';
import '../../../modules/whms/labels/view/whms_tare_list_screen.dart';
import '../../../modules/whms/locations/view/whms_location_list_screen.dart';
import '../../../modules/whms/orders/view/whms_order_create_screen.dart';
import '../../../modules/whms/orders/view/whms_order_detail_screen.dart';
import '../../../modules/whms/orders/view/whms_order_list_screen.dart';
import '../../../modules/whms/orders/view/whms_receipt_execute_screen.dart';
import '../../../modules/whms/pick/view/whms_pick_order_screen.dart';
import '../../../modules/whms/view/whms_defs_hub_screen.dart';
import '../../../modules/whms/view/whms_master_screens.dart';
import '../../../modules/whms/view/whms_orders_hub_screen.dart';
import '../../../modules/whms/view/whms_report_stub_screen.dart';
import '../../../modules/whms/view/whms_reports_hub_screen.dart';
import '../../../modules/whms/view/whms_reports_screen.dart';
import '../../../modules/whms/view/whms_shell_screen.dart';
import '../../../modules/whms/view/whms_stock_hub_screen.dart';
import '../../../modules/whms/view/whms_stock_query_screen.dart';
import '../../../modules/whms/view/whms_system_screen.dart';
import '../../../modules/whms/view/whms_transfer_screen.dart';
import '../../../modules/whms/view/whms_typed_order_list_screen.dart';
import '../../../modules/whms/view/whms_warehouse_list_screen.dart';
import '../../../modules/whms/model/whms_order_dto.dart';
import '../../../modules/whms/contract/whms_route_map.dart';
import '../../../modules/field_sales/surveys/view/competitor_survey_screen.dart';
import '../../../modules/field_sales/surveys/view/shelf_audit_screen.dart';
import '../../../modules/field_sales/sync/view/data_transfer_screen.dart';
import '../../../modules/field_sales/sync/view/logo_job_status_screen.dart';
import '../../../modules/field_sales/sync/view/logo_rest_settings_screen.dart';
import '../../../modules/field_sales/sync/view/offline_queue_detail_screen.dart';
import '../../../modules/field_sales/sync/view/pending_transfers_screen.dart';
import '../../../modules/field_sales/sync/view/sync_queue_status_screen.dart';
import '../../../modules/field_sales/targets/view/sales_targets_screen.dart';
import '../../../modules/field_sales/vehicle/view/vehicle_inventory_screen.dart';
import '../../../modules/field_sales/vehicle/view/vehicle_load_screen.dart';
import '../../../modules/field_sales/vehicle/view/vehicle_unload_screen.dart';
import '../../../modules/field_sales/vehicles/view/vehicle_eod_screen.dart';
import '../../../modules/field_sales/vehicles/view/vehicle_loading_screen.dart';
import '../../../modules/field_sales/vehicles/view/vehicle_stock_screen.dart';
import '../../../modules/field_sales/waybills/view/ewaybill_status_screen.dart';
import '../../../modules/field_sales/waybills/view/waybill_customer_selection_screen.dart';
import '../../../modules/field_sales/waybills/view/waybill_entry_screen.dart';
import '../../../modules/field_sales/waybills/view/waybill_list_screen.dart';
import '../../../modules/field_sales/waybills/view/waybill_retail_entry_screen.dart';
import '../../../modules/field_sales/waybills/view/waybills_pending_screen.dart';
import '../../../modules/field_sales/waybills/view/waybills_untransferred_screen.dart';
import '../../../modules/field_sales/yonetici/view/admin_kpi_summary_screen.dart';
import '../../../modules/field_sales/yonetici/view/company_general_overview_screen.dart';
import '../../../modules/manager/reports/view/leaderboard_screen.dart';
import '../../../modules/manager/reports/view/manager_reports_dashboard.dart';
import '../../../modules/manager/reports/view/period_comparison_report.dart';
import '../../../modules/manager/reports/view/target_assignment_screen.dart';
import '../../../view/login_screen.dart';
import '../../../view/settings/sync_log_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  /// Logo REST (ExfinApi) bağlantı ayarları
  static const String logoRestSettings = '/field-sales/logo-rest-settings';

  // Finans modülü rotaları
  static const String financeMain = '/finance';
  static const String financeInvoices = '/finance/invoices';
  static const String financePayables = '/finance/payables';

  // Satış modülü rotaları
  static const String salesMain = '/sales';
  static const String salesOrders = '/sales/orders';
  static const String salesCustomers = '/sales/customers';

  // Satın alma modülü rotaları
  static const String purchasingMain = '/purchasing';
  static const String purchasingOrders = '/purchasing/orders';
  static const String purchasingVendors = '/purchasing/vendors';

  // Stok modülü rotaları
  static const String inventoryMain = '/inventory';
  static const String inventoryItems = '/inventory/items';
  static const String inventoryWarehouses = '/inventory/warehouses';

  // İK modülü rotaları
  static const String hrMain = '/hr';
  static const String hrEmployees = '/hr/employees';
  static const String hrAttendance = '/hr/attendance';

  // Üretim modülü rotaları
  static const String manufacturingMain = '/manufacturing';
  static const String manufacturingOrders = '/manufacturing/orders';
  static const String manufacturingPlanning = '/manufacturing/planning';

  // Raporlama modülü rotaları
  static const String reportingMain = '/reporting';
  static const String reportingFinance = '/reporting/finance';
  static const String reportingSales = '/reporting/sales';

  // Sistem modülü rotaları
  static const String systemLogs = '/system/logs';
  static const String systemUsers = '/system/users';
  static const String systemRoles = '/system/roles';
  static const String systemParameters = '/system/parameters';

  // Saha Satış — çekirdek
  static const String fieldSalesMain = '/field-sales';
  static const String fieldSalesCustomers = '/field-sales/customers';
  static const String fieldSalesOrders = '/field-sales/orders';
  static const String fieldSalesOrdersSales = '/field-sales/orders-sales';
  static const String fieldSalesOrdersPurchase = '/field-sales/orders-purchase';
  static const String fieldSalesCollections = '/field-sales/collections';
  static const String fieldSalesPaymentEntry = '/field-sales/payment-entry';
  static const String fieldSalesCcCollection = '/field-sales/cc-collection';
  static const String fieldSalesPromissory = '/field-sales/promissory';
  static const String fieldSalesVirman = '/field-sales/virman';
  static const String fieldSalesWireTransfer = '/field-sales/wire-transfer';
  static const String fieldSalesChecks = '/field-sales/checks';
  static const String fieldSalesVisits = '/field-sales/visits';
  static const String fieldSalesReports = '/field-sales/reports';

  /// MBT Raporlar hub — [MbtReportCategory.yonetici]
  static const String fieldSalesReportYonetici =
      '/field-sales/report-yonetici';

  /// MBT Raporlar hub — [MbtReportCategory.finans]
  static const String fieldSalesReportFinans = '/field-sales/report-finans';

  /// MBT Raporlar hub — [MbtReportCategory.ops]
  static const String fieldSalesReportOps = '/field-sales/report-ops';
  static const String fieldSalesAudit = '/field-sales/audit';
  static const String fieldSalesWaybills = '/field-sales/waybills';
  static const String fieldSalesDeliveryList = '/field-sales/delivery-list';
  static const String fieldSalesStockCount = '/field-sales/stock-count';
  static const String fieldSalesSalesTargets = '/field-sales/sales-targets';
  static const String fieldSalesAdmin = '/field-sales/admin';
  static const String fieldSalesBarcodeScan = '/field-sales/barcode-scan';

  /// Menü seed alias — [fieldSalesBarcodeScan]
  static const String fieldSalesStockBarcode = '/field-sales/stock-barcode';
  static const String fieldSalesCustomerNew = '/field-sales/customer-new';
  static const String fieldSalesCustomersMap = '/field-sales/customers-map';
  static const String fieldSalesWholesale = '/field-sales/wholesale';
  static const String fieldSalesWholesaleReturn =
      '/field-sales/wholesale-return';
  static const String fieldSalesInvoiceWholesale =
      '/field-sales/invoice-wholesale';
  static const String fieldSalesInvoiceReturn = '/field-sales/invoice-return';
  static const String fieldSalesInvoicePurchase =
      '/field-sales/invoice-purchase';
  static const String fieldSalesWaybillPurchase =
      '/field-sales/waybill-purchase';

  /// Menü seed — [WaybillEntryScreen.routeWholesale]
  static const String fieldSalesWaybillWholesale =
      '/field-sales/waybill-wholesale';
  static const String fieldSalesProducts = '/field-sales/products';
  static const String fieldSalesPrices = '/field-sales/prices';
  static const String fieldSalesStockWarehouse = '/field-sales/stock-warehouse';
  static const String fieldSalesStockTransferred =
      '/field-sales/stock-transferred';
  static const String fieldSalesStockUntransferred =
      '/field-sales/stock-untransferred';

  /// WHMS Faz 1: OPS stub kalır; hedef namespace `WhmsRouteMap` (`/whms/*`).
  static const String fieldSalesMultiWarehouse =
      '/field-sales/multi-warehouse';
  static const String fieldSalesWarehouseStockQuery =
      '/field-sales/warehouse-stock-query';
  static const String fieldSalesWarehouseTransfer =
      '/field-sales/warehouse-transfer';
  static const String fieldSalesStockMovement = '/field-sales/stock-movement';
  static const String fieldSalesBatchExpiry = '/field-sales/batch-expiry';
  static const String fieldSalesConsignment = '/field-sales/consignment';
  static const String fieldSalesStockProduction =
      '/field-sales/stock-production';

  /// WHMS shell (Faz 2.5) — plasiyer menüsüne gömülmez
  static const String whmsShell = '/whms';
  static const String whmsOrdersHub = '/whms/orders-hub';
  static const String whmsOrders = '/whms/orders';
  static const String whmsOrderCreate = '/whms/orders/create';
  static const String whmsOrderDetail = '/whms/orders/detail';
  static const String whmsOrderReceipt = '/whms/orders/receipt';
  static const String whmsReceiptList = '/whms/receipt';
  static const String whmsPutaway = '/whms/putaway';
  static const String whmsPickList = '/whms/pick-list';
  static const String whmsPick = '/whms/pick';
  static const String whmsShipping = '/whms/shipping';
  static const String whmsReturns = '/whms/returns';
  static const String whmsLocations = '/whms/locations';
  static const String whmsDefs = '/whms/defs';
  static const String whmsFifo = '/whms/fifo';
  static const String whmsWarehouses = '/whms/warehouses';
  static const String whmsVehicleTypes = '/whms/vehicle-types';
  static const String whmsVehicles = '/whms/vehicles';
  static const String whmsStockHub = '/whms/stock';
  static const String whmsStockQuery = '/whms/stock-query';
  static const String whmsLot = '/whms/lot';
  static const String whmsReservation = '/whms/reservation';
  static const String whmsTransfer = '/whms/transfer';
  static const String whmsCount = '/whms/count';

  /// WHMS sayım yürütme dens
  static const String whmsCountExecute = '/whms/count/execute';
  /// Merkez depo raporları dens
  static const String whmsReportsHub = '/whms/reports-hub';
  static const String whmsReports = '/whms/reports';
  static const String whmsReportsOrderPerf = '/whms/reports/order-perf';
  static const String whmsReportsCountVar = '/whms/reports/count-var';
  static const String whmsSystem = '/whms/system';
  /// Cihaz / terminal dens listesi
  static const String whmsDevices = '/whms/devices';
  /// Etiket hub (paket · dara · şablon)
  static const String whmsLabels = '/whms/labels';
  static const String whmsPackageTypes = '/whms/labels/packages';
  static const String whmsTares = '/whms/labels/tares';
  static const String whmsLabelTemplates = '/whms/labels/templates';
  static const String fieldSalesCurrencyRates = '/field-sales/currency-rates';
  static const String fieldSalesCompanies = '/field-sales/companies';
  static const String fieldSalesWarehouses = '/field-sales/warehouses';
  static const String fieldSalesDataTransfer = '/field-sales/data-transfer';
  static const String fieldSalesDataUpdate = '/field-sales/data-update';
  static const String fieldSalesUntransferredSlips =
      '/field-sales/untransferred-slips';
  static const String fieldSalesDayStatus = '/field-sales/day-status';
  static const String fieldSalesImageSettings = '/field-sales/image-settings';
  static const String fieldSalesManagerDashboard =
      '/field-sales/manager-dashboard';
  static const String fieldSalesPeriodComparison =
      '/field-sales/period-comparison';
  static const String fieldSalesTargetAssignment =
      '/field-sales/target-assignment';
  static const String fieldSalesTargetRanking = '/field-sales/target-ranking';
  static const String fieldSalesVehicleLoading = '/field-sales/vehicle-loading';
  static const String fieldSalesVehicleStock = '/field-sales/vehicle-stock';
  static const String fieldSalesVehicleEod = '/field-sales/vehicle-eod';
  static const String fieldSalesMap = '/field-sales/map';
  static const String fieldSalesDashboard = '/field-sales/dashboard';
  static const String fieldSalesRoutesPlan = '/field-sales/routes/plan';
  static const String fieldSalesWeeklyRoutePlan =
      WeeklyRoutePlanScreen.routeName;
  static const String fieldSalesInvoices = '/field-sales/invoices';
  static const String fieldSalesInvoicesNew = '/field-sales/invoices/new';

  /// Legacy seed alias (geri uyumluluk)
  static const String legacySalesOrder = '/sales-order';
  static const String legacySalesHistory = '/sales-history';
  static const String legacySalesReport = '/sales-report';
  static const String fieldSalesCollectionAlias = '/field-sales/collection';

  /// Cari-önce guard (sipariş / tahsilat / fatura / irsaliye) seed path’leri.
  /// Aktif ziyaret `customerId` [argumentsForSeedRoute] ile geçilir.
  static const Set<String> customerFirstRoutes = {
    fieldSalesOrders,
    fieldSalesOrdersSales,
    fieldSalesOrdersPurchase,
    legacySalesOrder,
    fieldSalesCollections,
    fieldSalesCollectionAlias,
    fieldSalesPaymentEntry,
    fieldSalesCcCollection,
    fieldSalesPromissory,
    fieldSalesInvoicesNew,
    fieldSalesWholesale,
    fieldSalesWholesaleReturn,
    fieldSalesInvoiceWholesale,
    fieldSalesInvoiceReturn,
    fieldSalesInvoicePurchase,
    fieldSalesWaybillWholesale,
    fieldSalesWaybillPurchase,
  };

  /// {@template argumentsForSeedRoute}
  /// Seed named route için pushNamed `arguments`.
  /// Cari-önce path’lerde geçerli ziyaret customerId; aksi halde null.
  ///
  /// Parametreler:
  /// - [route]: Menü seed route
  /// - [visitCustomerId]: Aktif ziyaret cari id (opsiyonel)
  ///
  /// Dönüş değeri:
  /// - [Object?]: pushNamed arguments veya null
  /// {@endtemplate}
  static Object? argumentsForSeedRoute(
    String route, {
    String? visitCustomerId,
  }) {
    if (!customerFirstRoutes.contains(route)) return null;
    final id = visitCustomerId?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  /// Menü seed rapor yolu → [MbtReportCategory] ([fromRoute] + bilinen yeni hub).
  static MbtReportCategory? _mbtReportCategoryForSeedRoute(String route) {
    final fromEnum = MbtReportCategoryX.fromRoute(route);
    if (fromEnum != null) return fromEnum;
    switch (route) {
      case fieldSalesReportYonetici:
        return MbtReportCategory.yonetici;
      case fieldSalesReportFinans:
        return MbtReportCategory.finans;
      case fieldSalesReportOps:
        return MbtReportCategory.ops;
      default:
        return null;
    }
  }

  /// Named route settings taşır; [ModalRoute.settings.name] null olmaz.
  static MaterialPageRoute<dynamic> _page(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: builder,
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
      case login:
      case home:
        return _page(settings, (_) => const LoginScreen());
      case systemLogs:
        return _page(settings, (_) => const SyncLogScreen());
      case fieldSalesCustomers:
        return _page(settings, (_) => const CustomerListScreen());
      case fieldSalesCustomerNew:
        return _page(settings, (_) => const CustomerFormScreen());
      case fieldSalesCustomersMap:
      case fieldSalesMap:
        return _page(settings, (_) => const MapScreen());
      case fieldSalesReports:
        return _page(settings, (_) => const LogoReportsScreen());
      case fieldSalesVisits:
      case fieldSalesRoutesPlan:
        return _page(settings, (_) => const RoutePlanScreen());
      case fieldSalesWeeklyRoutePlan:
      case WeeklyRoutePlanScreen.routeName:
        return _page(settings, (_) => const WeeklyRoutePlanScreen());
      case VisitFormScreen.routeName:
        final visitCariId = settings.arguments as String?;
        if (visitCariId != null && visitCariId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => VisitFormScreen(customerId: visitCariId.trim()),
          );
        }
        return _page(
          settings,
          (_) => const VisitExistingCustomerScreen(),
        );
      case fieldSalesOrders:
      case fieldSalesOrdersSales:
      case fieldSalesOrdersPurchase:
      case legacySalesOrder:
        final orderType = settings.name == fieldSalesOrdersPurchase
            ? OrderType.purchase
            : OrderType.sales;
        String? customerId;
        OrderType resolvedType = orderType;
        final args = settings.arguments;
        if (args is String) {
          customerId = args;
        } else         if (args is Map) {
          customerId = args['customerId']?.toString();
          if (args['orderType'] != null) {
            resolvedType = OrderType.fromStorage(args['orderType']?.toString());
          }
        }
        if (customerId != null && customerId.trim().isNotEmpty) {
          final existingOrderId = args is Map
              ? args['orderId']?.toString() ?? args['existingOrderId']?.toString()
              : null;
          return _page(
            settings,
            (_) => OrderEntryScreen(
              customerId: customerId!,
              orderType: resolvedType,
              existingOrderId: existingOrderId,
            ),
          );
        }
        return _page(
          settings,
          (_) => OrderCustomerSelectionScreen(orderType: resolvedType),
        );
      case legacySalesHistory:
        return _page(settings, (_) => const OrderListScreen());
      case fieldSalesCollections:
      case fieldSalesCollectionAlias:
        final customerId = settings.arguments as String?;
        if (customerId != null && customerId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => CollectionEntryScreen(customerId: customerId),
          );
        }
        return _page(
          settings,
          (_) => const CollectionCustomerSelectionScreen(),
        );
      case fieldSalesPaymentEntry:
      case PaymentEntryScreen.routeName:
        final payCustomerId = settings.arguments as String?;
        if (payCustomerId != null && payCustomerId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => PaymentEntryScreen(customerId: payCustomerId),
          );
        }
        return _page(
          settings,
          (_) => const CollectionCustomerSelectionScreen(
            purpose: CollectionSelectionPurpose.payment,
          ),
        );
      case fieldSalesVirman:
      case VirmanScreen.routeName:
        return _page(settings, (_) => const VirmanScreen());
      case fieldSalesChecks:
      case CheckListScreen.routeName:
        return _page(settings, (_) => const CheckListScreen());
      case BankCardListScreen.routeName:
        return _page(settings, (_) => const BankCardListScreen());
      case CashCardDetailScreen.routeName:
        final detailArgs = settings.arguments;
        String? cashCode;
        if (detailArgs is Map) {
          final raw = detailArgs['code'];
          if (raw is String && raw.trim().isNotEmpty) {
            cashCode = raw.trim();
          }
        } else if (detailArgs is String && detailArgs.trim().isNotEmpty) {
          cashCode = detailArgs.trim();
        }
        return _page(
          settings,
          (_) => CashCardDetailScreen(cashCode: cashCode),
        );
      case PromissoryNoteListScreen.routeName:
        return _page(settings, (_) => const PromissoryNoteListScreen());
      case CompanyGeneralOverviewScreen.routeName:
        return _page(
          settings,
          (_) => const CompanyGeneralOverviewScreen(),
        );
      case fieldSalesAudit:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _page(
          settings,
          (_) => AuditFormScreen(
            formId: args['formId'] as String? ?? '',
            visitId: args['visitId'] as String? ?? '',
          ),
        );
      case fieldSalesMain:
        return _page(
          settings,
          (_) => const CampaignManagementScreen(),
        );
      case logoRestSettings:
        return _page(
          settings,
          (_) => const LogoRestSettingsScreen(),
        );
      case fieldSalesWaybills:
        final customerId = settings.arguments as String?;
        return _page(
          settings,
          (_) => WaybillListScreen(customerId: customerId),
        );
      case fieldSalesDeliveryList:
        return _page(
          settings,
          (_) => const DeliveryListScreen(),
        );
      case fieldSalesStockCount:
      case StockCountScreen.routeName:
        return _page(settings, (_) => const StockCountScreen());
      case fieldSalesSalesTargets:
        return _page(settings, (_) => const SalesTargetsScreen());
      case fieldSalesAdmin:
        return _page(settings, (_) => const AdminKpiSummaryScreen());
      case fieldSalesBarcodeScan:
      case fieldSalesStockBarcode:
        // P0–P3 merge: yalnızca barkod case; args opsiyonel Map.
        final barcodeArgs = settings.arguments;
        var selectionMode = true;
        var autoScan = false;
        if (barcodeArgs is Map) {
          final map = Map<String, dynamic>.from(barcodeArgs);
          selectionMode = map['selectionMode'] as bool? ?? true;
          autoScan = map['autoScan'] as bool? ?? false;
        } else if (settings.name == fieldSalesStockBarcode) {
          // Menü Stok → Barkod Ekle: browse + kamera
          selectionMode = false;
          autoScan = true;
        }
        return _page(
          settings,
          (_) => BarcodeScanScreen(
            selectionMode: selectionMode,
            autoScanOnOpen: autoScan,
          ),
        );
      case fieldSalesWholesale:
      case fieldSalesInvoiceWholesale:
        final wholesaleCustId = settings.arguments as String?;
        if (wholesaleCustId != null && wholesaleCustId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => InvoiceEntryScreen(
              customerId: wholesaleCustId,
              title: 'Toptan Satış Faturası',
              invoiceType: 'Toptan Satış Faturası (8)',
            ),
          );
        }
        return _page(
          settings,
          (_) => const InvoiceCustomerSelectionScreen(
            title: 'Toptan Satış Faturası',
            invoiceType: 'Toptan Satış Faturası (8)',
          ),
        );
      case fieldSalesWholesaleReturn:
      case fieldSalesInvoiceReturn:
        final returnCustId = settings.arguments as String?;
        if (returnCustId != null && returnCustId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => InvoiceEntryScreen(
              customerId: returnCustId,
              title: 'Toptan Satış İade Faturası',
              invoiceType: 'Satış İade Faturası (3)',
            ),
          );
        }
        return _page(
          settings,
          (_) => const InvoiceCustomerSelectionScreen(
            title: 'Toptan Satış İade Faturası',
            invoiceType: 'Satış İade Faturası (3)',
          ),
        );
      case fieldSalesInvoicePurchase:
        final purchaseCustId = settings.arguments as String?;
        if (purchaseCustId != null && purchaseCustId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => InvoiceEntryScreen(
              customerId: purchaseCustId,
              title: 'Satın Alma',
              invoiceType: 'field_sales.purchase_invoice',
            ),
          );
        }
        return _page(
          settings,
          (_) => const InvoiceCustomerSelectionScreen(
            title: 'Satın Alma',
            invoiceType: 'field_sales.purchase_invoice',
          ),
        );
      case fieldSalesWaybillWholesale: // == WaybillEntryScreen.routeWholesale
        final cariId = settings.arguments as String?;
        if (WaybillCustomerSelectionScreen.isValidCustomerId(cariId)) {
          return _page(
            settings,
            (_) => WaybillEntryScreen(
              cariId: cariId!.trim(),
              waybillType: WaybillType.wholesale,
            ),
          );
        }
        return _page(
          settings,
          (_) => const WaybillCustomerSelectionScreen(
            waybillType: WaybillType.wholesale,
          ),
        );
      case fieldSalesWaybillPurchase: // == WaybillEntryScreen.routePurchase
        final cariId = settings.arguments as String?;
        if (WaybillCustomerSelectionScreen.isValidCustomerId(cariId)) {
          return _page(
            settings,
            (_) => WaybillEntryScreen(
              cariId: cariId!.trim(),
              waybillType: WaybillType.purchase,
            ),
          );
        }
        return _page(
          settings,
          (_) => const WaybillCustomerSelectionScreen(
            waybillType: WaybillType.purchase,
          ),
        );
      case fieldSalesProducts:
        // MBT STOK → Detay: ürün katalogu (toolbar + dens arama)
        return _page(settings, (_) => const ProductCatalogScreen());
      case fieldSalesPrices:
        return _page(settings, (_) => const PriceCheckScreen());
      case fieldSalesStockWarehouse:
        return _page(
          settings,
          (_) => const WarehouseReceiptScreen(),
        );
      case fieldSalesStockTransferred:
      case StockTransferListScreen.routeTransferred:
        return _page(
          settings,
          (_) => const StockTransferListScreen(
            mode: StockTransferListMode.transferred,
          ),
        );
      case fieldSalesStockUntransferred:
      case StockTransferListScreen.routeUntransferred:
        return _page(
          settings,
          (_) => const StockTransferListScreen(
            mode: StockTransferListMode.untransferred,
          ),
        );
      case fieldSalesUntransferredSlips:
        return _page(
          settings,
          (_) => const PendingTransfersScreen(),
        );
      case fieldSalesCurrencyRates:
        return _page(
          settings,
          (_) => const CurrencyRatesScreen(),
        );
      case fieldSalesCompanies:
        return _page(
          settings,
          (_) => CompanyListScreen(
            initialTab: CompanyListScreen.resolveTab(settings.arguments),
          ),
        );
      case fieldSalesWarehouses:
        return _page(
          settings,
          (_) => const CompanyListScreen(
            initialTab: CompanyContextTab.warehouses,
          ),
        );
      case fieldSalesDataTransfer:
      case fieldSalesDataUpdate:
        return _page(settings, (_) => const DataTransferScreen());
      case fieldSalesDayStatus:
        return _page(settings, (_) => const DayStatusScreen());
      case fieldSalesImageSettings:
        return _page(settings, (_) => const GalleryScreen());
      case fieldSalesManagerDashboard:
        return _page(
          settings,
          (_) => const ManagerReportsDashboard(),
        );
      case fieldSalesPeriodComparison:
        return _page(
          settings,
          (_) => const PeriodComparisonReportScreen(),
        );
      case fieldSalesTargetAssignment:
        return _page(
          settings,
          (_) => const TargetAssignmentScreen(),
        );
      case fieldSalesTargetRanking:
        return _page(settings, (_) => const LeaderboardScreen());
      case fieldSalesVehicleLoading:
        return _page(
          settings,
          (_) => const VehicleLoadingScreen(),
        );
      case fieldSalesVehicleStock:
        return _page(
          settings,
          (_) => const VehicleStockSummaryScreen(),
        );
      case fieldSalesVehicleEod:
        return _page(settings, (_) => const EndOfDayScreen());
      case fieldSalesDashboard:
        return _page(settings, (_) => const DashboardScreen());
      case fieldSalesInvoices:
        return _page(
          settings,
          (_) => const InvoiceListMbtScreen(),
        );
      case fieldSalesInvoicesNew:
        final invNewCustId = settings.arguments as String?;
        if (invNewCustId != null && invNewCustId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => InvoiceEntryScreen(customerId: invNewCustId),
          );
        }
        return _page(
          settings,
          (_) => const InvoiceCustomerSelectionScreen(),
        );
      case legacySalesReport:
        return _page(settings, (_) => const SalesReportScreen());
      case AboutAppScreen.routeName:
        return _page(settings, (_) => const AboutAppScreen());
      case AiInsightsScreen.routeName:
        return _page(settings, (_) => const AiInsightsScreen());
      case AiDynamicReportScreen.routeName:
        return _page(settings, (_) => const AiDynamicReportScreen());
      case CompetitorShelfVisionScreen.routeName:
        return _page(settings, (_) => const CompetitorShelfVisionScreen());
      case InvoiceScanScreen.routeName:
        return _page(settings, (_) => const InvoiceScanScreen());
      case VehicleVisionScreen.routeName:
        return _page(settings, (_) => const VehicleVisionScreen());
      case SocialMediaImageScreen.routeName:
        final socialProduct =
            SocialMediaImageScreen.rowFromArgs(settings.arguments);
        return _page(
          settings,
          (_) => SocialMediaImageScreen(product: socialProduct),
        );
      case AnnouncementsScreen.routeName:
        return _page(settings, (_) => const AnnouncementsScreen());
      case BankDepositScreen.routeName:
        return _page(settings, (_) => const BankDepositScreen());
      case BatchExpiryScreen.routeName:
        return _page(settings, (_) => const BatchExpiryScreen());
      case CampaignsListScreen.routeName:
        // Alias → AnnouncementsScreen (MBT DUYURULAR tek kaynak)
        return _page(settings, (_) => const CampaignsListScreen());
      case CashCardListScreen.routeName:
        final cashArgs = settings.arguments;
        var cashSelection = false;
        String? cashInitial;
        if (cashArgs is Map) {
          cashSelection = cashArgs['selectionMode'] == true;
          final raw = cashArgs['initialCode'];
          if (raw is String && raw.trim().isNotEmpty) {
            cashInitial = raw.trim();
          }
        }
        return _page(
          settings,
          (_) => CashCardListScreen(
            selectionMode: cashSelection,
            initialCode: cashInitial,
          ),
        );
      case CashCountScreen.routeName:
        return _page(settings, (_) => const CashCountScreen());
      case fieldSalesCcCollection:
      case CreditCardCollectionScreen.routeName:
        final ccCustomerId = settings.arguments as String?;
        if (ccCustomerId != null && ccCustomerId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => CreditCardCollectionScreen(customerId: ccCustomerId),
          );
        }
        return _page(
          settings,
          (_) => const CollectionCustomerSelectionScreen(
            purpose: CollectionSelectionPurpose.creditCard,
          ),
        );
      case fieldSalesPromissory:
      case PromissoryNoteScreen.routeName:
        final noteCustomerId = settings.arguments as String?;
        if (noteCustomerId != null && noteCustomerId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => PromissoryNoteScreen(customerId: noteCustomerId),
          );
        }
        return _page(
          settings,
          (_) => const CollectionCustomerSelectionScreen(
            purpose: CollectionSelectionPurpose.promissory,
          ),
        );
      case CompetitorSurveyScreen.routeName:
        return _page(settings, (_) => const CompetitorSurveyScreen());
      case ConsignmentScreen.routeName:
        return _page(settings, (_) => const ConsignmentScreen());
      case CustomerExtractScreen.routeName:
        final extractArgs = settings.arguments;
        String? extractCustomerId;
        if (extractArgs is String) {
          extractCustomerId = extractArgs;
        } else if (extractArgs is Map) {
          extractCustomerId = extractArgs['customerId']?.toString() ??
              extractArgs['cariId']?.toString();
        }
        return _page(
          settings,
          (_) => CustomerExtractScreen(customerId: extractCustomerId),
        );
      case CustomerReconciliationScreen.routeName:
        final reconArgs = settings.arguments;
        String reconCustomerId = '';
        String? reconCode;
        String? reconName;
        if (reconArgs is String) {
          reconCustomerId = reconArgs.trim();
        } else if (reconArgs is Map) {
          reconCustomerId = (reconArgs['customerId'] ??
                  reconArgs['cariId'] ??
                  '')
              .toString()
              .trim();
          reconCode = reconArgs['customerCode']?.toString() ??
              reconArgs['code']?.toString();
          reconName = reconArgs['customerName']?.toString() ??
              reconArgs['name']?.toString();
        }
        return _page(
          settings,
          (_) => CustomerReconciliationScreen(
            customerId: reconCustomerId,
            customerCode: reconCode,
            customerName: reconName,
          ),
        );
      case CustomerRiskScreen.routeName:
        final riskArgs = settings.arguments;
        String? riskCustomerId;
        String? riskCode;
        String? riskName;
        double riskBalance = 0;
        double riskLimit = 0;
        double riskAging = 0;
        if (riskArgs is String) {
          riskCustomerId = riskArgs;
        } else if (riskArgs is Map) {
          riskCustomerId = riskArgs['customerId']?.toString();
          riskCode = riskArgs['customerCode']?.toString() ??
              riskArgs['code']?.toString();
          riskName = riskArgs['customerName']?.toString() ??
              riskArgs['name']?.toString();
          riskBalance =
              double.tryParse('${riskArgs['balance'] ?? 0}') ?? 0;
          riskLimit = double.tryParse(
                '${riskArgs['riskLimit'] ?? riskArgs['creditLimit'] ?? 0}',
              ) ??
              0;
          riskAging = double.tryParse(
                '${riskArgs['agingDebt'] ?? riskArgs['aging'] ?? 0}',
              ) ??
              0;
        }
        return _page(
          settings,
          (_) => CustomerRiskScreen(
            customerId: riskCustomerId,
            customerCode: riskCode,
            customerName: riskName,
            balance: riskBalance,
            riskLimit: riskLimit,
            agingDebt: riskAging,
          ),
        );
      case DayCloseScreen.routeName:
        return _page(settings, (_) => const DayCloseScreen());
      case DayOpenScreen.routeName:
        return _page(settings, (_) => const DayOpenScreen());
      case DeliveryHoldScreen.routeName:
        return _page(settings, (_) => const DeliveryHoldScreen());
      case DeliveryUntransferredScreen.routeName:
        return _page(settings, (_) => const DeliveryUntransferredScreen());
      case DiscountApprovalScreen.routeName:
        return _page(settings, (_) => const DiscountApprovalScreen());
      case DocumentShareScreen.routeName:
        return _page(settings, (_) => const DocumentShareScreen());
      case EinvoiceStatusScreen.routeName:
        return _page(settings, (_) => const EinvoiceStatusScreen());
      case EwaybillStatusScreen.routeName:
        return _page(settings, (_) => const EwaybillStatusScreen());
      case ExpenseEntryScreen.routeName:
        return _page(settings, (_) => const ExpenseEntryScreen());
      case FavoritesScreen.routeName:
        return _page(settings, (_) => const FavoritesScreen());
      case CollectionsTransferredScreen.routeName:
        return _page(settings, (_) => const CollectionsTransferredScreen());
      case CollectionsUntransferredScreen.routeName:
        return _page(settings, (_) => const CollectionsUntransferredScreen());
      case GeofenceSettingsScreen.routeName:
        return _page(settings, (_) => const GeofenceSettingsScreen());
      case GpsTrackingScreen.routeName:
        return _page(settings, (_) => const GpsTrackingScreen());
      case InAppRouteMapScreen.routeName:
        return _page(settings, (_) => const InAppRouteMapScreen());
      case OfflineMapDownloadScreen.routeName:
        return _page(settings, (_) => const OfflineMapDownloadScreen());
      case SupplierPurchaseRequestListScreen.routeName:
        return _page(
          settings,
          (_) => const SupplierPurchaseRequestListScreen(),
        );
      case SupplierPurchaseRequestFormScreen.routeName:
        return _page(
          settings,
          (_) => const SupplierPurchaseRequestFormScreen(),
        );
      case VehicleCameraSettingsScreen.routeName:
        return _page(
          settings,
          (_) => const VehicleCameraSettingsScreen(),
        );
      case VehicleCameraBroadcastScreen.routeName:
        return _page(
          settings,
          (_) => const VehicleCameraBroadcastScreen(),
        );
      case VehicleCameraMonitorScreen.routeName:
        final args = settings.arguments;
        String? userId;
        if (args is Map) {
          userId = args['userId']?.toString();
        }
        return _page(
          settings,
          (_) => VehicleCameraMonitorScreen(filterUserId: userId),
        );
      case HelpFaqScreen.routeName:
        return _page(settings, (_) => const HelpFaqScreen());
      case InvoiceApprovalScreen.routeName:
        return _page(settings, (_) => const InvoiceApprovalScreen());
      case InvoiceListMbtScreen.routeName:
        return _page(settings, (_) => const InvoiceListMbtScreen());
      case InvoicesPendingScreen.routeName:
        return _page(settings, (_) => const InvoicesPendingScreen());
      case InvoicesUntransferredScreen.routeName:
        return _page(settings, (_) => const InvoicesUntransferredScreen());
      case LanguagePickerScreen.routeName:
        return _page(settings, (_) => const LanguagePickerScreen());
      case LogoJobStatusScreen.routeName:
        return _page(settings, (_) => const LogoJobStatusScreen());
      case MultiWarehouseScreen.routeName:
        return _page(settings, (_) => const MultiWarehouseScreen());
      case WhmsWarehouseListScreen.routeName:
      case AppRoutes.whmsWarehouses:
        return _page(settings, (_) => const WhmsWarehouseListScreen());
      case NotificationCenterScreen.routeName:
        return _page(settings, (_) => const NotificationCenterScreen());
      case OfflineQueueDetailScreen.routeName:
        return _page(settings, (_) {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return OfflineQueueDetailScreen(job: args);
          }
          if (args is Map) {
            return OfflineQueueDetailScreen(
              job: Map<String, dynamic>.from(args),
            );
          }
          return const OfflineQueueDetailScreen();
        });
      case OrderApprovalScreen.routeName:
        return _page(settings, (_) => const OrderApprovalScreen());
      case OrderListScreen.routeName:
        return _page(settings, (_) => const OrderListScreen());
      case OrderTrackingScreen.routeName:
        return _page(settings, (_) => const OrderTrackingScreen());
      case OrdersPendingScreen.routeName:
        return _page(settings, (_) => const OrdersPendingScreen());
      case OrdersUntransferredScreen.routeName:
        return _page(settings, (_) => const OrdersUntransferredScreen());
      case PartialDeliveryScreen.routeName:
        return _page(settings, (_) => const PartialDeliveryScreen());
      case PriceListScreen.routeName:
        return _page(settings, (_) => const PriceListScreen());
      case PrinterSettingsScreen.routeName:
        return _page(settings, (_) => const PrinterSettingsScreen());
      case ProductCatalogScreen.routeName:
        return _page(settings, (_) => const ProductCatalogScreen());
      case ProductDetailScreen.routeName:
        final productRow = ProductDetailScreen.rowFromArgs(settings.arguments);
        return _page(
          settings,
          (_) => ProductDetailScreen(initial: productRow),
        );
      case ProfileSettingsScreen.routeName:
        return _page(settings, (_) => const ProfileSettingsScreen());
      case AppearanceSettingsScreen.routeName:
        return _page(settings, (_) => const AppearanceSettingsScreen());
      case AiSettingsScreen.routeName:
        return _page(settings, (_) => const AiSettingsScreen());
      case AiVoiceChatScreen.routeName:
        final displayName = settings.arguments is String
            ? settings.arguments as String
            : null;
        return _page(
          settings,
          (_) => AiVoiceChatScreen(displayName: displayName),
        );
      case ReportLogoSettingsScreen.routeName:
        return _page(settings, (_) => const ReportLogoSettingsScreen());
      case CollectionReportScreen.routeName:
        return _page(settings, (_) => const CollectionReportScreen());
      case ReportBackupScreen.routeName:
        return _page(settings, (_) => const ReportBackupScreen());
      case ReportParametersScreen.routeName:
        final reportId = settings.arguments as String?;
        return _page(
          settings,
          (_) => ReportParametersScreen(reportId: reportId),
        );
      case ReportLayoutDesignerScreen.routeName:
        final layoutReportId = settings.arguments as String?;
        return _page(
          settings,
          (_) => ReportLayoutDesignerScreen(reportId: layoutReportId),
        );
      case ReportPdfViewerScreen.routeName:
        return _page(
          settings,
          (_) => ReportPdfViewerScreen.fromArgs(settings.arguments),
        );
      case SalesReportScreen.routeName:
        return _page(settings, (_) => const SalesReportScreen());
      case VisitReportScreen.routeName:
        return _page(settings, (_) => const VisitReportScreen());
      case ReturnEntryScreen.routeName:
        return _page(settings, (_) => const ReturnEntryScreen());
      case ReturnsListScreen.routeName:
        return _page(settings, (_) => const ReturnsListScreen());
      case gps_route_map.RouteMapScreen.routeName:
        return _page(
          settings,
          (_) => const gps_route_map.RouteMapScreen(),
        );
      case SampleGiveawayScreen.routeName:
        return _page(settings, (_) => const SampleGiveawayScreen());
      case SendInfoScreen.routeName:
        return _page(settings, (_) => const SendInfoScreen());
      case ShelfAuditScreen.routeName:
        return _page(settings, (_) => const ShelfAuditScreen());
      case StockMovementScreen.routeName:
        return _page(settings, (_) => const StockMovementScreen());
      case ProductionReceiptScreen.routeName:
        return _page(settings, (_) => const ProductionReceiptScreen());
      case SyncQueueStatusScreen.routeName:
        return _page(settings, (_) => const SyncQueueStatusScreen());
      case VehicleInventoryScreen.routeName:
        return _page(settings, (_) => const VehicleInventoryScreen());
      case VehicleLoadScreen.routeName:
        return _page(settings, (_) => const VehicleLoadScreen());
      case VehicleUnloadScreen.routeName:
        return _page(settings, (_) => const VehicleUnloadScreen());
      case VisitExistingCustomerScreen.routeName:
        return _page(settings, (_) => const VisitExistingCustomerScreen());
      case VisitHistoryScreen.routeName:
        final historyCariId =
            VisitHistoryScreen.parseCustomerId(settings.arguments);
        return _page(
          settings,
          (_) => VisitHistoryScreen(customerId: historyCariId),
        );
      case VisitDetailScreen.routeName:
      case VisitDetailScreen.routeNameAlias:
        final visitId =
            VisitDetailScreen.parseVisitId(settings.arguments) ?? '';
        return _page(
          settings,
          (_) => VisitDetailScreen(visitId: visitId),
        );
      case VisitNewCustomerScreen.routeName:
        return _page(settings, (_) => const VisitNewCustomerScreen());
      case VisitPhotoScreen.routeName:
        return _page(settings, (_) => const VisitPhotoScreen());
      case VisitUntransferredScreen.routeName:
        return _page(settings, (_) => const VisitUntransferredScreen());
      case VoucherDefaultsSettingsScreen.routeName:
      // Menü seed: /field-sales/invoice-defaults → aynı ekran
      case '/field-sales/invoice-defaults':
        return _page(settings, (_) => const VoucherDefaultsSettingsScreen());
      case WarehouseStockQueryScreen.routeName:
      case AppRoutes.fieldSalesWarehouseStockQuery:
        return _page(settings, (_) => const WarehouseStockQueryScreen());
      case WarehouseTransferScreen.routeName:
      case AppRoutes.fieldSalesWarehouseTransfer:
        return _page(settings, (_) => const WarehouseTransferScreen());
      case WhmsStockQueryScreen.routeName:
      case AppRoutes.whmsStockQuery:
        return _page(settings, (_) => const WhmsStockQueryScreen());
      case WhmsTransferScreen.routeName:
      case AppRoutes.whmsTransfer:
        return _page(settings, (_) => const WhmsTransferScreen());
      case WhmsDefsHubScreen.routeName:
      case AppRoutes.whmsDefs:
        return _page(settings, (_) => const WhmsDefsHubScreen());
      case WhmsLocationListScreen.routeName:
      case AppRoutes.whmsLocations:
        return _page(settings, (_) => const WhmsLocationListScreen());
      case WhmsFifoRuleListScreen.routeName:
      case AppRoutes.whmsFifo:
        return _page(settings, (_) => const WhmsFifoRuleListScreen());
      case WhmsCountScreen.routeName:
      case AppRoutes.whmsCount:
        return _page(settings, (_) => const WhmsCountScreen());
      case WhmsCountExecuteScreen.routeName:
      case AppRoutes.whmsCountExecute:
        final countArg = settings.arguments;
        if (countArg is WhmsCountOrder) {
          return _page(
            settings,
            (_) => WhmsCountExecuteScreen(initialOrder: countArg),
          );
        }
        final countId = countArg is String
            ? countArg.trim()
            : (countArg is Map
                ? (countArg['orderId'] ?? countArg['id'] ?? '')
                    .toString()
                    .trim()
                : '');
        return _page(
          settings,
          (_) => WhmsCountExecuteScreen(
            orderId: countId.isEmpty ? null : countId,
          ),
        );
      case WhmsOrderListScreen.routeName:
      case AppRoutes.whmsOrders:
        return _page(settings, (_) => const WhmsOrderListScreen());
      case WhmsOrderCreateScreen.routeName:
      case AppRoutes.whmsOrderCreate:
        return _page(settings, (_) => const WhmsOrderCreateScreen());
      case WhmsOrderDetailScreen.routeName:
      case AppRoutes.whmsOrderDetail:
        final orderArg = settings.arguments;
        if (orderArg is WhmsOrderDto) {
          return _page(
            settings,
            (_) => WhmsOrderDetailScreen(initialOrder: orderArg),
          );
        }
        final orderId = orderArg is String ? orderArg.trim() : null;
        return _page(
          settings,
          (_) => WhmsOrderDetailScreen(
            orderId: (orderId != null && orderId.isNotEmpty) ? orderId : null,
          ),
        );
      case WhmsReceiptExecuteScreen.routeName:
      case AppRoutes.whmsOrderReceipt:
        final receiptArg = settings.arguments;
        if (receiptArg is WhmsOrderDto) {
          return _page(
            settings,
            (_) => WhmsReceiptExecuteScreen(initialOrder: receiptArg),
          );
        }
        final receiptId =
            receiptArg is String ? receiptArg.trim() : null;
        return _page(
          settings,
          (_) => WhmsReceiptExecuteScreen(
            orderId: (receiptId != null && receiptId.isNotEmpty)
                ? receiptId
                : null,
          ),
        );
      case WhmsPickOrderScreen.routeName:
      case AppRoutes.whmsPick:
        final pickArg = settings.arguments;
        if (pickArg is WhmsOrderDto) {
          return _page(
            settings,
            (_) => WhmsPickOrderScreen(initialOrder: pickArg),
          );
        }
        final pickId = pickArg is String ? pickArg.trim() : null;
        return _page(
          settings,
          (_) => WhmsPickOrderScreen(
            orderId: (pickId != null && pickId.isNotEmpty) ? pickId : null,
          ),
        );
      case WhmsShellScreen.routeName:
      case AppRoutes.whmsShell:
        return _page(settings, (_) => const WhmsShellScreen());
      case WhmsOrdersHubScreen.routeName:
      case AppRoutes.whmsOrdersHub:
        return _page(settings, (_) => const WhmsOrdersHubScreen());
      case WhmsRouteMap.whmsReceiptList:
      case AppRoutes.whmsReceiptList:
        return _page(settings, (_) => WhmsTypedOrderListScreen.receipt());
      case WhmsRouteMap.whmsPutaway:
      case AppRoutes.whmsPutaway:
        return _page(settings, (_) => WhmsTypedOrderListScreen.putaway());
      case WhmsRouteMap.whmsPickList:
      case AppRoutes.whmsPickList:
        return _page(settings, (_) => WhmsTypedOrderListScreen.pick());
      case WhmsRouteMap.whmsShipping:
      case AppRoutes.whmsShipping:
        return _page(settings, (_) => WhmsTypedOrderListScreen.shipping());
      case WhmsVehicleTypeListScreen.routeName:
      case AppRoutes.whmsVehicleTypes:
        return _page(settings, (_) => const WhmsVehicleTypeListScreen());
      case WhmsVehicleListScreen.routeName:
      case AppRoutes.whmsVehicles:
        return _page(settings, (_) => const WhmsVehicleListScreen());
      case WhmsLotListScreen.routeName:
      case AppRoutes.whmsLot:
        return _page(settings, (_) => const WhmsLotListScreen());
      case WhmsReservationListScreen.routeName:
      case AppRoutes.whmsReservation:
        return _page(settings, (_) => const WhmsReservationListScreen());
      case WhmsReturnListScreen.routeName:
      case AppRoutes.whmsReturns:
        return _page(settings, (_) => const WhmsReturnListScreen());
      case WhmsStockHubScreen.routeName:
      case AppRoutes.whmsStockHub:
        return _page(settings, (_) => const WhmsStockHubScreen());
      case WhmsReportsHubScreen.routeName:
      case AppRoutes.whmsReportsHub:
        return _page(settings, (_) => const WhmsReportsHubScreen());
      case AppRoutes.whmsReportsOrderPerf:
        return _page(
          settings,
          (_) => const WhmsReportStubScreen(
            routeName: AppRoutes.whmsReportsOrderPerf,
            titleKey: 'whms.hub.reports_order_perf',
            hintKey: 'whms.reports.order_perf_hint',
            kind: 'order_perf',
          ),
        );
      case AppRoutes.whmsReportsCountVar:
        return _page(
          settings,
          (_) => const WhmsReportStubScreen(
            routeName: AppRoutes.whmsReportsCountVar,
            titleKey: 'whms.hub.reports_count_var',
            hintKey: 'whms.reports.count_var_hint',
            kind: 'count_var',
          ),
        );
      case WhmsSystemScreen.routeName:
      case AppRoutes.whmsSystem:
        return _page(settings, (_) => const WhmsSystemScreen());
      case WhmsReportsScreen.routeName:
      case AppRoutes.whmsReports:
        return _page(settings, (_) => const WhmsReportsScreen());
      case WhmsLabelsHubScreen.routeName:
      case AppRoutes.whmsLabels:
        return _page(settings, (_) => const WhmsLabelsHubScreen());
      case WhmsDeviceListScreen.routeName:
      case AppRoutes.whmsDevices:
        return _page(settings, (_) => const WhmsDeviceListScreen());
      case WhmsPackageTypeListScreen.routeName:
      case AppRoutes.whmsPackageTypes:
        return _page(settings, (_) => const WhmsPackageTypeListScreen());
      case WhmsTareListScreen.routeName:
      case AppRoutes.whmsTares:
        return _page(settings, (_) => const WhmsTareListScreen());
      case WhmsLabelTemplateListScreen.routeName:
      case AppRoutes.whmsLabelTemplates:
        return _page(settings, (_) => const WhmsLabelTemplateListScreen());
      case WaybillRetailEntryScreen.routeName:
        final customerId = settings.arguments as String?;
        if (WaybillCustomerSelectionScreen.isValidCustomerId(customerId)) {
          return _page(
            settings,
            (_) => WaybillRetailEntryScreen(
              customerId: customerId!.trim(),
            ),
          );
        }
        return _page(
          settings,
          (_) => const WaybillCustomerSelectionScreen(isRetail: true),
        );
      case WaybillsPendingScreen.routeName:
        return _page(settings, (_) => const WaybillsPendingScreen());
      case WaybillsUntransferredScreen.routeName:
        return _page(settings, (_) => const WaybillsUntransferredScreen());
      case fieldSalesWireTransfer:
      case WireTransferScreen.routeName:
        final wireCustomerId = settings.arguments as String?;
        if (wireCustomerId != null && wireCustomerId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => WireTransferScreen(customerId: wireCustomerId),
          );
        }
        return _page(
          settings,
          (_) => const CollectionCustomerSelectionScreen(
            purpose: CollectionSelectionPurpose.wireTransfer,
          ),
        );
      default:
        // Menü seed rapor alt yolları (cari/stok/fatura/…)
        if (settings.name != null &&
            settings.name!.startsWith('/field-sales/report-')) {
          final category = _mbtReportCategoryForSeedRoute(settings.name!);
          if (category != null) {
            return _page(
              settings,
              (_) => ReportCategoryListScreen(category: category),
            );
          }
          return _page(
            settings,
            (_) => const LogoReportsScreen(),
          );
        }
        return _page(
          settings,
          (_) => Scaffold(
            body: Center(
              child: Text('${settings.name} için rota bulunamadı'),
            ),
          ),
        );
    }
  }
}
