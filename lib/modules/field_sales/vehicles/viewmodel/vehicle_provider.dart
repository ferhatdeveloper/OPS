import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/vehicle_model.dart';
import '../../vehicle/engine/vehicle_load_service.dart';
import '../../vehicle/engine/vehicle_unload_service.dart';
import '../../../../service/database_service.dart';

class VehicleState {
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;
  final List<VehicleStockModel> stocks;
  final List<LoadingModel> recentLoadings;
  final bool isLoading;
  final String? error;

  VehicleState({
    this.vehicles = const [],
    this.selectedVehicle,
    this.stocks = const [],
    this.recentLoadings = const [],
    this.isLoading = false,
    this.error,
  });

  VehicleState copyWith({
    List<VehicleModel>? vehicles,
    VehicleModel? selectedVehicle,
    List<VehicleStockModel>? stocks,
    List<LoadingModel>? recentLoadings,
    bool? isLoading,
    String? error,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      stocks: stocks ?? this.stocks,
      recentLoadings: recentLoadings ?? this.recentLoadings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  VehicleNotifier() : super(VehicleState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final vehicleMaps = await sqliteDb.query('vehicles', where: 'is_active = 1');
      final vehicles = vehicleMaps.map((m) => VehicleModel.fromMap(m)).toList();

      state = state.copyWith(
        vehicles: vehicles,
        selectedVehicle: vehicles.isNotEmpty ? vehicles.first : null,
        isLoading: false,
      );

      if (state.selectedVehicle != null) {
        await loadVehicleStock(state.selectedVehicle!.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectVehicle(VehicleModel vehicle) async {
    state = state.copyWith(selectedVehicle: vehicle);
    await loadVehicleStock(vehicle.id);
  }

  Future<void> loadVehicleStock(String vehicleId) async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final stockMaps = await sqliteDb.rawQuery('''
        SELECT vs.*, p.name as product_name 
        FROM vehicle_stocks vs
        JOIN products p ON vs.product_id = p.id
        WHERE vs.vehicle_id = ?
      ''', [vehicleId]);

      final stocks = stockMaps.map((m) => VehicleStockModel.fromMap(m, productName: m['product_name'] as String?)).toList();
      state = state.copyWith(stocks: stocks);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadVehicleStocks(String vehicleId) => loadVehicleStock(vehicleId);

  /// {@template load_stock_into_vehicle}
  /// Yükleme fişi yazar; merkez `products.stock_quantity` düşer,
  /// `vehicle_stocks` artar.
  ///
  /// Parametreler:
  /// - [items]: `{productId, quantity, unit?}` listesi
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarılıysa true
  /// {@endtemplate}
  Future<bool> loadStockIntoVehicle({
    required List<Map<String, dynamic>> items, // {productId, quantity, unit}
  }) async {
    if (state.selectedVehicle == null) return false;
    if (items.isEmpty) return false;

    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final session = await db.getUserSession();
      final userId = session?['id'] as String? ?? 'system';

      await sqliteDb.transaction((txn) async {
        final loadingId = const Uuid().v4();
        final now = DateTime.now().toIso8601String();

        await txn.insert('vehicle_loadings', {
          'id': loadingId,
          'vehicle_id': state.selectedVehicle!.id,
          'salesperson_id': userId,
          'loading_date': now,
          'status': 'Completed',
          'is_synced': 0,
          'created_at': now,
        });

        for (final item in items) {
          final productId = item['productId'] as String;
          final qty = (item['quantity'] as num).toDouble();

          await txn.insert('vehicle_loading_items', {
            'id': const Uuid().v4(),
            'loading_id': loadingId,
            'product_id': productId,
            'quantity': qty,
            'unit': item['unit'] ?? 'Adet',
          });
        }

        await VehicleLoadService.applyLoad(
          db: txn,
          vehicleId: state.selectedVehicle!.id,
          items: items,
        );
      });

      await loadVehicleStock(state.selectedVehicle!.id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template unload_stock_from_vehicle}
  /// Araç stoğunu düşer; merkez `products.stock_quantity` artırır.
  ///
  /// Parametreler:
  /// - [items]: `{productId, quantity}` listesi
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarılıysa true
  /// {@endtemplate}
  Future<bool> unloadStockFromVehicle({
    required List<Map<String, dynamic>> items,
  }) async {
    if (state.selectedVehicle == null) return false;
    if (items.isEmpty) return false;

    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      await sqliteDb.transaction((txn) async {
        await VehicleUnloadService.applyUnload(
          db: txn,
          vehicleId: state.selectedVehicle!.id,
          items: items,
        );
      });

      await loadVehicleStock(state.selectedVehicle!.id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reconcileEndOfDay(List<Map<String, dynamic>> finalCounts) async {
    state = state.copyWith(isLoading: true);
    try {
      // Implement real EOD reconciliation logic here
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  return VehicleNotifier();
});
