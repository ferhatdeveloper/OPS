import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../service/database_service.dart';
import '../model/kpi_model.dart';

class KPIState {
  final KPIModel? kpi;
  final bool isLoading;
  final String? error;

  KPIState({this.kpi, this.isLoading = false, this.error});

  KPIState copyWith({KPIModel? kpi, bool? isLoading, String? error}) {
    return KPIState(
      kpi: kpi ?? this.kpi,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class KPINotifier extends StateNotifier<KPIState> {
  KPINotifier() : super(KPIState()) {
    refreshKPIs();
  }

  Future<void> refreshKPIs() async {
    state = state.copyWith(isLoading: true);
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      // Mock aggregates for the demo
      final orders = await db.query('orders');
      final totalSales = orders.fold<double>(0, (sum, o) => sum + (o['total_amount'] as num).toDouble());
      
      final visits = await db.query('visits');
      final completedVisits = visits.where((v) => v['status'] == 'Completed').length;

      state = state.copyWith(
        kpi: KPIModel(
          salesTarget: 500000.0, // Hardcoded for demo
          currentSales: totalSales,
          plannedVisits: visits.length,
          completedVisits: completedVisits,
          totalOrders: orders.length,
          totalCollections: 0.0, // Could fetch from collections table
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final kpiProvider = StateNotifierProvider<KPINotifier, KPIState>((ref) {
  return KPINotifier();
});
