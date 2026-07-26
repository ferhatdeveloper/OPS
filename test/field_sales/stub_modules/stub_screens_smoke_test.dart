// Dosya Adı: stub_screens_smoke_test.dart
// Açıklama: Yeni stub ekranlar için minimal widget/smoke (compile + AppLocalization)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/announcements/view/announcements_screen.dart';
import 'package:exfin_ops/modules/field_sales/barcode/view/barcode_scan_screen.dart';
import 'package:exfin_ops/modules/field_sales/campaigns/view/campaigns_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/cash_card_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/cash_count_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/check_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collections_transferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/collections_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/credit_card_collection_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/promissory_note_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/virman_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/wire_transfer_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/payment_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_extract_movement.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_extract_screen.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_risk_screen.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_provider.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_store.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_hold_screen.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/partial_delivery_screen.dart';
import 'package:exfin_ops/modules/field_sales/documents/view/document_share_screen.dart';
import 'package:exfin_ops/modules/field_sales/eod/view/day_open_screen.dart';
import 'package:exfin_ops/modules/field_sales/expenses/view/expense_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/favorites/view/favorites_screen.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/gps_last_location_seed.dart';
import 'package:exfin_ops/modules/field_sales/gps/view/geofence_settings_screen.dart';
import 'package:exfin_ops/modules/field_sales/gps/view/gps_tracking_screen.dart';
import 'package:exfin_ops/modules/field_sales/gps/view/route_map_screen.dart';
import 'package:exfin_ops/modules/field_sales/help/view/about_app_screen.dart';
import 'package:exfin_ops/modules/field_sales/help/view/help_faq_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/einvoice_status_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoice_approval_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoice_list_mbt_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoices_pending_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoices_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/notifications/view/notification_center_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/discount_approval_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_approval_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/order_tracking_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/orders_pending_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/orders_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/sample_giveaway_screen.dart';
import 'package:exfin_ops/modules/field_sales/pricing/model/price_list_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/pricing/view/price_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/printing/view/printer_settings_screen.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_seed.dart';
import 'package:exfin_ops/modules/field_sales/products/view/product_catalog_screen.dart';
import 'package:exfin_ops/modules/field_sales/products/view/product_detail_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/collection_report_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/report_backup_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/sales_report_screen.dart';
import 'package:exfin_ops/modules/field_sales/reports/view/visit_report_screen.dart';
import 'package:exfin_ops/modules/field_sales/returns/view/return_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/returns/view/returns_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_history_screen.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_new_customer_screen.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_photo_screen.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/settings/view/language_picker_screen.dart';
import 'package:exfin_ops/modules/field_sales/settings/view/profile_settings_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/batch_expiry_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/consignment_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/multi_warehouse_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/production_receipt_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_count_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_movement_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_transfer_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/warehouse_stock_query_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/warehouse_transfer_screen.dart';
import 'package:exfin_ops/modules/field_sales/surveys/view/competitor_survey_screen.dart';
import 'package:exfin_ops/modules/field_sales/surveys/view/shelf_audit_screen.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/logo_job_status_screen.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/offline_queue_detail_screen.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/sync_queue_status_screen.dart';
import 'package:exfin_ops/modules/field_sales/targets/view/sales_targets_screen.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_inventory_screen.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_load_screen.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_unload_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/ewaybill_status_seed.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/ewaybill_status_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybill_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybill_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybill_retail_entry_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybills_pending_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybills_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/model/admin_kpi_summary.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/view/admin_kpi_summary_screen.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/viewmodel/admin_kpi_provider.dart';

import 'stub_l10n_harness.dart';

/// {@template _StubCase}
/// Tek bir stub ekranın smoke senaryosu.
/// {@endtemplate}
class _StubCase {
  /// [name]: Ekran sınıf adı
  final String name;

  /// [titleKey]: Birincil l10n anahtarı
  final String titleKey;

  /// [builder]: Widget üretici
  final Widget Function() builder;

  /// [overrides]: Harness ProviderScope override listesi
  final List<Override> overrides;

  const _StubCase({
    required this.name,
    required this.titleKey,
    required this.builder,
    this.overrides = const [],
  });
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  final cases = <_StubCase>[
    _StubCase(
      name: 'AboutAppScreen',
      titleKey: 'field_sales.stubs.about_app',
      builder: () => const AboutAppScreen(),
    ),
    _StubCase(
      name: 'AdminKpiSummaryScreen',
      titleKey: 'field_sales.stubs.admin_kpi',
      overrides: [
        adminKpiSummaryProvider.overrideWith(
          (ref) async => AdminKpiSummary.zero,
        ),
      ],
      builder: () => const AdminKpiSummaryScreen(),
    ),
    _StubCase(
      name: 'AnnouncementsScreen',
      titleKey: 'field_sales.stubs.announcements',
      builder: () => const AnnouncementsScreen(),
    ),
    _StubCase(
      name: 'BarcodeScanScreen',
      titleKey: 'field_sales.stubs.barcode_scan',
      // Smoke: DB yok — seed dens enjeksiyonu
      builder: () => BarcodeScanScreen(
        products: ProductCatalogSeed.defaultRows,
      ),
    ),
    _StubCase(
      name: 'BatchExpiryScreen',
      titleKey: 'field_sales.stubs.batch_expiry',
      builder: () => const BatchExpiryScreen(),
    ),
    // Alias: /campaigns-list → AnnouncementsScreen (tek kaynak DUYURULAR)
    _StubCase(
      name: 'CampaignsListScreen',
      titleKey: 'field_sales.stubs.announcements',
      builder: () => const CampaignsListScreen(),
    ),
    _StubCase(
      name: 'CashCardListScreen',
      titleKey: 'field_sales.stubs.cash_card_list',
      builder: () => const CashCardListScreen(),
    ),
    _StubCase(
      name: 'CashCountScreen',
      titleKey: 'field_sales.stubs.cash_count',
      builder: () => const CashCountScreen(),
    ),
    _StubCase(
      name: 'CheckListScreen',
      titleKey: 'field_sales.stubs.check_list',
      builder: () => const CheckListScreen(),
    ),
    _StubCase(
      name: 'CollectionReportScreen',
      titleKey: 'field_sales.stubs.collection_report',
      builder: () => const CollectionReportScreen(),
    ),
    _StubCase(
      name: 'ReportBackupScreen',
      titleKey: 'field_sales.stubs.report_backup',
      builder: () => const ReportBackupScreen(),
    ),
    _StubCase(
      name: 'CollectionsTransferredScreen',
      titleKey: 'field_sales.stubs.collections_transferred',
      builder: () => const CollectionsTransferredScreen(),
    ),
    _StubCase(
      name: 'CollectionsUntransferredScreen',
      titleKey: 'field_sales.stubs.collections_untransferred',
      builder: () => const CollectionsUntransferredScreen(),
    ),
    _StubCase(
      name: 'CompetitorSurveyScreen',
      titleKey: 'field_sales.stubs.competitor_survey',
      builder: () => const CompetitorSurveyScreen(),
    ),
    _StubCase(
      name: 'ConsignmentScreen',
      titleKey: 'field_sales.stubs.consignment',
      builder: () => const ConsignmentScreen(),
    ),
    _StubCase(
      name: 'CreditCardCollectionScreen',
      titleKey: 'field_sales.stubs.credit_card_collection',
      builder: () => const CreditCardCollectionScreen(customerId: 'TEST-CARI'),
    ),
    _StubCase(
      name: 'VirmanScreen',
      titleKey: 'field_sales.virman_entry_title',
      builder: () => const VirmanScreen(),
    ),
    _StubCase(
      name: 'PaymentEntryScreen',
      titleKey: 'field_sales.payment_entry_title',
      builder: () => const PaymentEntryScreen(customerId: 'TEST-CARI'),
    ),
    _StubCase(
      name: 'CustomerExtractScreen',
      titleKey: 'field_sales.stubs.customer_extract',
      overrides: [
        customerExtractStoreProvider.overrideWithValue(
          const _StubEmptyExtractStore(),
        ),
      ],
      builder: () => const CustomerExtractScreen(),
    ),
    _StubCase(
      name: 'CustomerRiskScreen',
      titleKey: 'field_sales.stubs.customer_risk',
      builder: () => const CustomerRiskScreen(),
    ),
    _StubCase(
      name: 'DayOpenScreen',
      titleKey: 'field_sales.stubs.day_open',
      builder: () => const DayOpenScreen(),
    ),
    _StubCase(
      name: 'DeliveryHoldScreen',
      titleKey: 'field_sales.stubs.delivery_hold',
      builder: () => const DeliveryHoldScreen(),
    ),
    _StubCase(
      name: 'DeliveryListScreen',
      titleKey: 'field_sales.stubs.delivery_list',
      builder: () => const DeliveryListScreen(),
    ),
    _StubCase(
      name: 'DeliveryUntransferredScreen',
      titleKey: 'field_sales.stubs.delivery_untransferred',
      builder: () => const DeliveryUntransferredScreen(),
    ),
    _StubCase(
      name: 'DiscountApprovalScreen',
      titleKey: 'field_sales.stubs.discount_approval',
      builder: () => const DiscountApprovalScreen(),
    ),
    _StubCase(
      name: 'DocumentShareScreen',
      titleKey: 'field_sales.stubs.document_share',
      builder: () => const DocumentShareScreen(),
    ),
    _StubCase(
      name: 'EinvoiceStatusScreen',
      titleKey: 'field_sales.stubs.einvoice_status',
      builder: () => const EinvoiceStatusScreen(records: []),
    ),
    _StubCase(
      name: 'EwaybillStatusScreen',
      titleKey: 'field_sales.stubs.ewaybill_status',
      builder: () => EwaybillStatusScreen(
        records: EwaybillStatusSeed.defaultRows,
      ),
    ),
    _StubCase(
      name: 'ExpenseEntryScreen',
      titleKey: 'field_sales.stubs.expense_entry',
      builder: () => const ExpenseEntryScreen(),
    ),
    _StubCase(
      name: 'FavoritesScreen',
      titleKey: 'field_sales.stubs.favorites',
      builder: () => const FavoritesScreen(),
    ),
    _StubCase(
      name: 'GeofenceSettingsScreen',
      titleKey: 'field_sales.stubs.geofence_settings',
      builder: () => const GeofenceSettingsScreen(),
    ),
    _StubCase(
      name: 'GpsTrackingScreen',
      titleKey: 'field_sales.stubs.gps_tracking',
      builder: () => GpsTrackingScreen(
        records: GpsLastLocationSeed.defaultRows,
      ),
    ),
    _StubCase(
      name: 'HelpFaqScreen',
      titleKey: 'field_sales.stubs.help_faq',
      builder: () => const HelpFaqScreen(),
    ),
    _StubCase(
      name: 'InvoiceApprovalScreen',
      titleKey: 'field_sales.stubs.invoice_approval',
      builder: () => const InvoiceApprovalScreen(),
    ),
    _StubCase(
      name: 'InvoiceListMbtScreen',
      titleKey: 'field_sales.stubs.invoice_list',
      builder: () => const InvoiceListMbtScreen(),
    ),
    _StubCase(
      name: 'InvoicesPendingScreen',
      titleKey: 'field_sales.stubs.invoices_pending',
      builder: () => const InvoicesPendingScreen(),
    ),
    _StubCase(
      name: 'InvoicesUntransferredScreen',
      titleKey: 'field_sales.stubs.invoices_untransferred',
      builder: () => const InvoicesUntransferredScreen(),
    ),
    _StubCase(
      name: 'LanguagePickerScreen',
      titleKey: 'field_sales.stubs.language_picker',
      builder: () => const LanguagePickerScreen(),
    ),
    _StubCase(
      name: 'LogoJobStatusScreen',
      titleKey: 'field_sales.stubs.logo_job_status',
      // Smoke: DB yok — boş enjeksiyon; üretim SQLite sync_queue kullanır
      builder: () => const LogoJobStatusScreen(jobs: []),
    ),
    _StubCase(
      name: 'MultiWarehouseScreen',
      titleKey: 'field_sales.stubs.multi_warehouse',
      // Smoke: DB yok — seed dens enjeksiyonu
      builder: () => MultiWarehouseScreen(
        rows: WarehouseDensRow.fromSeed(),
      ),
    ),
    _StubCase(
      name: 'NotificationCenterScreen',
      titleKey: 'field_sales.stubs.notification_center',
      builder: () => const NotificationCenterScreen(),
    ),
    _StubCase(
      name: 'OfflineQueueDetailScreen',
      titleKey: 'field_sales.stubs.offline_queue_detail',
      builder: () => const OfflineQueueDetailScreen(),
    ),
    _StubCase(
      name: 'OrderApprovalScreen',
      titleKey: 'field_sales.stubs.order_approval',
      builder: () => const OrderApprovalScreen(),
    ),
    _StubCase(
      name: 'OrderListScreen',
      titleKey: 'field_sales.stubs.order_list',
      builder: () => const OrderListScreen(),
    ),
    _StubCase(
      name: 'OrderTrackingScreen',
      titleKey: 'field_sales.stubs.order_tracking',
      builder: () => const OrderTrackingScreen(),
    ),
    _StubCase(
      name: 'OrdersPendingScreen',
      titleKey: 'field_sales.stubs.orders_pending',
      builder: () => const OrdersPendingScreen(),
    ),
    _StubCase(
      name: 'OrdersUntransferredScreen',
      titleKey: 'field_sales.stubs.orders_untransferred',
      builder: () => const OrdersUntransferredScreen(),
    ),
    _StubCase(
      name: 'PartialDeliveryScreen',
      titleKey: 'field_sales.stubs.partial_delivery',
      builder: () => const PartialDeliveryScreen(),
    ),
    _StubCase(
      name: 'PriceListScreen',
      titleKey: 'field_sales.stubs.price_list',
      builder: () => PriceListScreen(
        rows: PriceListDensRow.fromSeed(),
      ),
    ),
    _StubCase(
      name: 'PrinterSettingsScreen',
      titleKey: 'field_sales.stubs.printer_settings',
      builder: () => const PrinterSettingsScreen(),
    ),
    _StubCase(
      name: 'ProductCatalogScreen',
      titleKey: 'field_sales.stubs.product_catalog',
      builder: () => const ProductCatalogScreen(products: []),
    ),
    _StubCase(
      name: 'ProductDetailScreen',
      titleKey: 'field_sales.stubs.product_detail',
      builder: () => const ProductDetailScreen(),
    ),
    _StubCase(
      name: 'ProductionReceiptScreen',
      titleKey: 'field_sales.stubs.production_receipt',
      builder: () => const ProductionReceiptScreen(),
    ),
    _StubCase(
      name: 'ProfileSettingsScreen',
      titleKey: 'field_sales.stubs.profile_settings',
      builder: () => const ProfileSettingsScreen(),
    ),
    _StubCase(
      name: 'StockCountScreen',
      titleKey: 'field_sales.stubs.stock_count',
      builder: () => const StockCountScreen(),
    ),
    _StubCase(
      name: 'StockTransferListScreen.transferred',
      titleKey: 'field_sales.stubs.stock_transferred',
      builder: () => const StockTransferListScreen(
        mode: StockTransferListMode.transferred,
      ),
    ),
    _StubCase(
      name: 'StockTransferListScreen.untransferred',
      titleKey: 'field_sales.stubs.stock_untransferred',
      builder: () => const StockTransferListScreen(
        mode: StockTransferListMode.untransferred,
      ),
    ),
    _StubCase(
      name: 'PromissoryNoteScreen',
      titleKey: 'field_sales.stubs.promissory_note',
      builder: () => const PromissoryNoteScreen(customerId: 'TEST-CARI'),
    ),
    _StubCase(
      name: 'ReturnEntryScreen',
      titleKey: 'field_sales.stubs.return_entry',
      builder: () => const ReturnEntryScreen(),
    ),
    _StubCase(
      name: 'ReturnsListScreen',
      titleKey: 'field_sales.stubs.returns_list',
      builder: () => const ReturnsListScreen(),
    ),
    _StubCase(
      name: 'RouteMapScreen',
      titleKey: 'field_sales.stubs.route_map',
      builder: () => const RouteMapScreen(points: []),
    ),
    _StubCase(
      name: 'SalesReportScreen',
      titleKey: 'field_sales.stubs.sales_report',
      builder: () => const SalesReportScreen(),
    ),
    _StubCase(
      name: 'SalesTargetsScreen',
      titleKey: 'field_sales.stubs.sales_targets',
      builder: () => const SalesTargetsScreen(initialRows: []),
    ),
    _StubCase(
      name: 'SampleGiveawayScreen',
      titleKey: 'field_sales.stubs.sample_giveaway',
      builder: () => const SampleGiveawayScreen(),
    ),
    _StubCase(
      name: 'ShelfAuditScreen',
      titleKey: 'field_sales.stubs.shelf_audit',
      builder: () => const ShelfAuditScreen(),
    ),
    _StubCase(
      name: 'StockMovementScreen',
      titleKey: 'field_sales.stubs.stock_movement',
      builder: () => const StockMovementScreen(),
    ),
    _StubCase(
      name: 'SyncQueueStatusScreen',
      titleKey: 'field_sales.stubs.sync_queue_status',
      builder: () => const SyncQueueStatusScreen(),
    ),
    _StubCase(
      name: 'VehicleInventoryScreen',
      titleKey: 'field_sales.stubs.vehicle_inventory',
      builder: () => const VehicleInventoryScreen(),
    ),
    _StubCase(
      name: 'VehicleLoadScreen',
      titleKey: 'field_sales.stubs.vehicle_load',
      builder: () => const VehicleLoadScreen(),
    ),
    _StubCase(
      name: 'VehicleUnloadScreen',
      titleKey: 'field_sales.stubs.vehicle_unload',
      builder: () => const VehicleUnloadScreen(),
    ),
    _StubCase(
      name: 'VisitHistoryScreen',
      titleKey: 'field_sales.stubs.visit_history',
      builder: () => const VisitHistoryScreen(),
    ),
    _StubCase(
      name: 'VisitNewCustomerScreen',
      titleKey: 'field_sales.stubs.visit_new_customer',
      builder: () => const VisitNewCustomerScreen(),
    ),
    _StubCase(
      name: 'VisitPhotoScreen',
      titleKey: 'field_sales.stubs.visit_photo',
      builder: () => const VisitPhotoScreen(),
    ),
    _StubCase(
      name: 'VisitReportScreen',
      titleKey: 'field_sales.stubs.visit_report',
      builder: () => const VisitReportScreen(),
    ),
    _StubCase(
      name: 'VisitUntransferredScreen',
      titleKey: 'field_sales.stubs.visit_untransferred',
      builder: () => const VisitUntransferredScreen(),
    ),
    _StubCase(
      name: 'WarehouseStockQueryScreen',
      titleKey: 'field_sales.stubs.warehouse_stock_query',
      builder: () => const WarehouseStockQueryScreen(),
    ),
    _StubCase(
      name: 'WarehouseTransferScreen',
      titleKey: 'field_sales.stubs.warehouse_transfer',
      builder: () => const WarehouseTransferScreen(),
    ),
    _StubCase(
      name: 'WaybillEntryScreen',
      titleKey: 'field_sales.stubs.waybill_wholesale',
      builder: () => const WaybillEntryScreen(cariId: 'TEST-CARI'),
    ),
    _StubCase(
      name: 'WaybillListScreen',
      titleKey: 'field_sales.stubs.waybill_list',
      builder: () => const WaybillListScreen(),
    ),
    _StubCase(
      name: 'WaybillRetailEntryScreen',
      titleKey: 'field_sales.stubs.waybill_retail_entry',
      builder: () => const WaybillRetailEntryScreen(customerId: 'TEST-CARI'),
    ),
    _StubCase(
      name: 'WaybillsPendingScreen',
      titleKey: 'field_sales.stubs.waybills_pending',
      builder: () => const WaybillsPendingScreen(),
    ),
    _StubCase(
      name: 'WaybillsUntransferredScreen',
      titleKey: 'field_sales.stubs.waybills_untransferred',
      builder: () => const WaybillsUntransferredScreen(),
    ),
    _StubCase(
      name: 'WireTransferScreen',
      titleKey: 'field_sales.wire_entry_title',
      builder: () => const WireTransferScreen(customerId: 'TEST-CARI'),
    ),
  ];

  group('Stub ekran smoke (compile + AppLocalization)', () {
    for (final c in cases) {
      testWidgets('${c.name} pump + l10n', (tester) async {
        await pumpStubWithL10n(
          tester,
          c.builder(),
          overrides: c.overrides,
        );
        expectStubL10nSmoke(tester, c.titleKey);
      });
    }
  });
}

/// Smoke için boş cari ekstre store (SQLite yok).
class _StubEmptyExtractStore extends CustomerExtractStore {
  const _StubEmptyExtractStore();

  @override
  Future<List<CustomerExtractMovement>> query({
    String? customerId,
    required DateTime start,
    required DateTime end,
    ExtractMovementFilter filter = ExtractMovementFilter.all,
    String search = '',
  }) async {
    return const [];
  }
}
