// Dosya Adı: order_pending_seed.dart
// Açıklama: Bekleyen sipariş dens stub seed (SQLite boş / test)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../view/orders_pending_screen.dart';
import 'order_model.dart';
import 'order_pending_record.dart';

/// {@template order_pending_seed}
/// MBT Bekleyen Siparişler dens stub seed.
///
/// Kullanım örneği:
/// ```dart
/// final rows = OrderPendingSeed.defaultRows;
/// ```
/// {@endtemplate}
class OrderPendingSeed {
  OrderPendingSeed._();

  /// Named route
  static const String route = OrdersPendingScreen.routeName;

  /// Alt menü başlığı (TR stub)
  static const String submenuTitle = 'Bekleyen Siparişler';

  /// Kaynak tablo
  static const String tableName = 'orders';

  /// Varsayılan dens satırlar
  static List<OrderPendingRecord> get defaultRows => [
        ...salesRows,
        ...purchaseRows,
      ];

  /// Satış bekleyen örnekleri
  static List<OrderPendingRecord> get salesRows => [
        OrderPendingRecord(
          id: 'ORD-P-S-001',
          customerId: 'cust_1',
          customerCode: 'C001',
          customerName: 'Demo Market',
          orderDate: DateTime(2026, 7, 20),
          totalAmount: 1250.0,
          status: 'Pending',
          orderType: OrderType.sales,
          approvalStatus: 0,
        ),
        OrderPendingRecord(
          id: 'ORD-P-S-002',
          customerId: 'cust_2',
          customerCode: 'C002',
          customerName: 'Anadolu Gıda',
          orderDate: DateTime(2026, 7, 22),
          totalAmount: 480.5,
          status: 'Proposal',
          orderType: OrderType.sales,
          approvalStatus: 0,
        ),
      ];

  /// Alış bekleyen örnekleri
  static List<OrderPendingRecord> get purchaseRows => [
        OrderPendingRecord(
          id: 'ORD-P-A-001',
          customerId: 'sup_1',
          customerCode: 'T001',
          customerName: 'Tedarik A.Ş.',
          orderDate: DateTime(2026, 7, 18),
          totalAmount: 3200.0,
          status: 'Pending',
          orderType: OrderType.purchase,
          approvalStatus: 0,
        ),
      ];

  /// SQLite insert map listesi
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
