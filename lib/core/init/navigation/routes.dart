import 'package:flutter/material.dart';
import '../../../view/settings/sync_log_screen.dart';
import '../../../modules/field_sales/customers/view/customer_list_screen.dart';
import '../../../modules/field_sales/reports/view/logo_reports_screen.dart';
import '../../../modules/field_sales/campaigns/view/campaign_management_screen.dart';
import '../../../modules/field_sales/routes/view/route_plan_screen.dart';
import '../../../modules/field_sales/orders/view/order_entry_screen.dart';
import '../../../modules/field_sales/collections/view/collection_entry_screen.dart';
import '../../../modules/field_sales/merchandising/view/audit_form_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';

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

  // Saha Satış modülü rotaları
  static const String fieldSalesMain = '/field-sales';
  static const String fieldSalesCustomers = '/field-sales/customers';
  static const String fieldSalesOrders = '/field-sales/orders';
  static const String fieldSalesCollections = '/field-sales/collections';
  static const String fieldSalesVisits = '/field-sales/visits';
  static const String fieldSalesReports = '/field-sales/reports';
  static const String fieldSalesAudit = '/field-sales/audit';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Bu metot, ileride eklenecek ekranlar için rota yapılandırması yapacak
    switch (settings.name) {
      case splash:
      // return MaterialPageRoute(builder: (_) => SplashScreen());
      case login:
      // return MaterialPageRoute(builder: (_) => LoginScreen());
      case home:
      // return MaterialPageRoute(builder: (_) => HomeScreen());
      case systemLogs:
        return MaterialPageRoute(builder: (_) => const SyncLogScreen());
      case fieldSalesCustomers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      case fieldSalesReports:
        return MaterialPageRoute(builder: (_) => const LogoReportsScreen());
      case fieldSalesVisits:
        return MaterialPageRoute(builder: (_) => const RoutePlanScreen());
      case fieldSalesOrders:
        final customerId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OrderEntryScreen(customerId: customerId));
      case fieldSalesCollections:
        final customerId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => CollectionEntryScreen(customerId: customerId));
      case fieldSalesAudit:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => AuditFormScreen(
          formId: args['formId'],
          visitId: args['visitId'],
        ));
      case fieldSalesMain: // Placeholder for main menu
        return MaterialPageRoute(builder: (_) => const CampaignManagementScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('${settings.name} için rota bulunamadı'),
                ),
              ),
        );
    }
  }
}
