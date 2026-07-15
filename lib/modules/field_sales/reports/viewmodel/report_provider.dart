import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../service/database_service.dart';
import 'package:geolocator/geolocator.dart';

class ReportData {
  final double totalSales;
  final double totalCollections;
  final int totalVisits;
  final int completedVisits;
  final List<SalesReportEntry> dailySales;
  final List<Map<String, dynamic>> vehicleStocks;
  final Map<String, dynamic>? nearestCustomer;

  ReportData({
    required this.totalSales,
    required this.totalCollections,
    required this.totalVisits,
    required this.completedVisits,
    required this.dailySales,
    required this.vehicleStocks,
    required this.dailyTarget,
    required this.targetReached,
    this.nearestCustomer,
  });

  final double dailyTarget;
  final double targetReached;

  Map<String, dynamic> toMap() {
    return {
      'total_sales': totalSales,
      'total_collections': totalCollections,
      'total_visits': totalVisits,
      'completed_visits': completedVisits,
      'daily_target': dailyTarget,
      'target_reached': targetReached,
      'nearest_customer': nearestCustomer,
      'total_turnover': totalSales,
      'last_year_turnover': totalSales * 0.9,
      'growth_rate': '+10%',
      'stores': [],
    };
  }
}

class SalesReportEntry {
  final String date;
  final double amount;

  SalesReportEntry(this.date, this.amount);
}

class ReportNotifier extends StateNotifier<AsyncValue<ReportData>> {
  ReportNotifier() : super(const AsyncValue.loading()) {
    loadReportData();
  }

  Future<void> loadReportData() async {
    state = const AsyncValue.loading();
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      // 1. Total Sales (Invoices)
      final salesResult = await db.rawQuery('SELECT SUM(total_amount) as total FROM invoices WHERE status = "Completed"');
      final totalSales = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 2. Total Collections
      final collectionResult = await db.rawQuery('SELECT SUM(amount) as total FROM collections');
      final totalCollections = (collectionResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 3. Visits Summary
      final visitsResult = await db.rawQuery('SELECT COUNT(*) as total, SUM(CASE WHEN status = "Completed" THEN 1 ELSE 0 END) as completed FROM visits');
      final totalVisits = (visitsResult.first['total'] as int?) ?? 0;
      final completedVisits = (visitsResult.first['completed'] as int?) ?? 0;

      // 4. Daily Sales (Last 7 days)
      final dailySalesResult = await db.rawQuery('''
        SELECT date(invoice_date) as date, SUM(total_amount) as amount 
        FROM invoices 
        WHERE status = "Completed" 
        GROUP BY date(invoice_date) 
        ORDER BY date(invoice_date) DESC 
        LIMIT 7
      ''');
      
      final dailySales = dailySalesResult.map((row) => SalesReportEntry(
        row['date'] as String,
        (row['amount'] as num).toDouble(),
      )).toList().reversed.toList();

      // 5. Vehicle Stocks
      final vehicleStocksResult = await db.rawQuery('''
        SELECT vs.product_id, vs.quantity, p.name as product_name 
        FROM vehicle_stocks vs
        LEFT JOIN products p ON vs.product_id = p.id
        WHERE vs.quantity > 0
      ''');

      // 6. Nearest Pending Customer
      Map<String, dynamic>? nearestCustomer;
      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        final customersResult = await db.rawQuery('''
          SELECT c.id, c.name, c.latitude, c.longitude, c.address 
          FROM customers c
          JOIN route_customers rc ON c.id = rc.customer_id
          LEFT JOIN visits v ON c.id = v.customer_id AND date(v.check_in_at) = date('now')
          WHERE v.id IS NULL
        ''');

        double minDistance = double.infinity;
        for (final c in customersResult) {
          final lat = (c['latitude'] as num?)?.toDouble();
          final lng = (c['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            final distance = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
            if (distance < minDistance) {
              minDistance = distance;
              nearestCustomer = Map<String, dynamic>.from(c);
              nearestCustomer['distance'] = distance;
            }
          }
        }
      } catch (e) {
        print('Error calculating nearest customer: $e');
      }

      // 7. Today's Target Progress
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todaySalesResult = await db.rawQuery('SELECT SUM(total_amount) as total FROM invoices WHERE status = "Completed" AND date(invoice_date) = ?', [today]);
      final todaySales = (todaySalesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      const dailyTarget = 5000.0; // Mock target

      state = AsyncValue.data(ReportData(
        totalSales: totalSales,
        totalCollections: totalCollections,
        totalVisits: totalVisits,
        completedVisits: completedVisits,
        dailySales: dailySales,
        vehicleStocks: vehicleStocksResult,
        nearestCustomer: nearestCustomer,
        dailyTarget: dailyTarget,
        targetReached: todaySales,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> fetchDailySales() => loadReportData();
}

final dailySalesReportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<ReportData>>((ref) {
  return ReportNotifier();
});
