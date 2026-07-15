import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../../../service/database_service.dart';
import '../../../../service/data_cache_service.dart';
import '../model/customer_model.dart';

class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;

  CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? error,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  CustomerNotifier() : super(CustomerState()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    // Phase 7: Check Cache first (Redis-like)
    // Geçici olarak mock verileri anında görebilmek için cache devre dışı bırakıldı
    // final cached = DataCacheService().get<List<CustomerModel>>('all_customers');
    // if (cached != null) {
    //   state = state.copyWith(customers: cached, isLoading: false);
    //   return;
    // }

    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final result = await sqliteDb.query('customers', orderBy: 'name');
      
      final customers = result.map((m) => CustomerModel.fromMap(m)).toList();
      
      // Store in Cache
      DataCacheService().set('all_customers', customers);
      
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      return fetchCustomers();
    }
    
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final result = await sqliteDb.query(
        'customers',
        where: 'name LIKE ? OR tax_no LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name',
      );
      
      final customers = result.map((m) => CustomerModel.fromMap(m)).toList();
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      
      // Determine if insert or update (we'll just use insert with replace strategy)
      await sqliteDb.insert(
        'customers',
        customer.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      
      // Clear cache and refetch
      DataCacheService().invalidate('all_customers');
      await fetchCustomers();
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier();
});
