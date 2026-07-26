// Dosya Adı: routes.dart
// Açıklama: App named route sabitleri ve generateRoute (menü seed ile hizalı)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../modules/field_sales/announcements/view/announcements_screen.dart';
import '../../../modules/field_sales/barcode/view/barcode_scan_screen.dart';
import '../../../modules/field_sales/campaigns/view/campaign_management_screen.dart';
import '../../../modules/field_sales/campaigns/view/campaigns_list_screen.dart';
import '../../../modules/field_sales/collections/view/bank_deposit_screen.dart';
import '../../../modules/field_sales/collections/view/cash_card_list_screen.dart';
import '../../../modules/field_sales/collections/view/cash_count_screen.dart';
import '../../../modules/field_sales/collections/view/check_list_screen.dart';
import '../../../modules/field_sales/collections/view/collection_customer_selection_screen.dart';
import '../../../modules/field_sales/collections/view/collection_entry_screen.dart';
import '../../../modules/field_sales/collections/view/collections_transferred_screen.dart';
import '../../../modules/field_sales/collections/view/collections_untransferred_screen.dart';
import '../../../modules/field_sales/collections/view/credit_card_collection_screen.dart';
import '../../../modules/field_sales/collections/view/payment_entry_screen.dart';
import '../../../modules/field_sales/collections/view/promissory_note_screen.dart';
import '../../../modules/field_sales/collections/view/virman_screen.dart';
import '../../../modules/field_sales/collections/view/wire_transfer_screen.dart';
import '../../../modules/field_sales/companies/view/company_list_screen.dart';
import '../../../modules/field_sales/currency/view/currency_rates_screen.dart';
import '../../../modules/field_sales/customers/view/customer_extract_screen.dart';
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
import '../../../modules/field_sales/maps/view/map_screen.dart';
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
import '../../../modules/field_sales/reports/view/sales_report_screen.dart';
import '../../../modules/field_sales/reports/view/visit_report_screen.dart';
import '../../../modules/field_sales/returns/view/return_entry_screen.dart';
import '../../../modules/field_sales/returns/view/returns_list_screen.dart';
import '../../../modules/field_sales/routes/view/route_plan_screen.dart';
import '../../../modules/field_sales/routes/view/visit_existing_customer_screen.dart';
import '../../../modules/field_sales/routes/view/visit_form_screen.dart';
import '../../../modules/field_sales/routes/view/visit_history_screen.dart';
import '../../../modules/field_sales/routes/view/visit_new_customer_screen.dart';
import '../../../modules/field_sales/routes/view/visit_photo_screen.dart';
import '../../../modules/field_sales/routes/view/visit_untransferred_screen.dart';
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
import '../../../modules/whms/view/whms_shell_screen.dart';
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
import '../../../modules/inventory/view/materials_screen.dart';
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
  static const String whmsWarehouses = '/whms/warehouses';
  static const String whmsStockQuery = '/whms/stock-query';
  static const String whmsTransfer = '/whms/transfer';
  static const String whmsCount = '/whms/count';
  static const String fieldSalesCurrencyRates = '/field-sales/currency-rates';
  static const String fieldSalesCompanies = '/field-sales/companies';
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
        } else if (args is Map) {
          customerId = args['customerId']?.toString();
          if (args['orderType'] != null) {
            resolvedType = OrderType.fromStorage(args['orderType']?.toString());
          }
        }
        if (customerId != null && customerId.trim().isNotEmpty) {
          return _page(
            settings,
            (_) => OrderEntryScreen(
              customerId: customerId!,
              orderType: resolvedType,
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
        return _page(settings, (_) => const CheckListScreen());
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
        return _page(settings, (_) => const BarcodeScanScreen());
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
        return _page(settings, (_) => const MaterialsScreen());
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
        return _page(settings, (_) => const CompanyListScreen());
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
        return _page(settings, (_) => const ProductDetailScreen());
      case ProfileSettingsScreen.routeName:
        return _page(settings, (_) => const ProfileSettingsScreen());
      case CollectionReportScreen.routeName:
        return _page(settings, (_) => const CollectionReportScreen());
      case ReportBackupScreen.routeName:
        return _page(settings, (_) => const ReportBackupScreen());
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
        return _page(settings, (_) => const VisitHistoryScreen());
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
        return _page(settings, (_) => const WarehouseStockQueryScreen());
      case WarehouseTransferScreen.routeName:
        return _page(settings, (_) => const WarehouseTransferScreen());
      case WhmsShellScreen.routeName:
      case AppRoutes.whmsWarehouses:
      case AppRoutes.whmsStockQuery:
      case AppRoutes.whmsTransfer:
      case AppRoutes.whmsCount:
        return _page(settings, (_) => const WhmsShellScreen());
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
