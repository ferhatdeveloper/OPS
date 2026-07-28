import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/tenant/postgrest_master_sync.dart';
import '../../../../service/data_cache_service.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../service/postgres_service.dart';
import '../model/customer_model.dart';

class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  /// {@template emptySelectionL10nKey}
  /// Cari seçim ekranı boş liste mesajının çeviri anahtarı.
  /// {@endtemplate}
  String get emptySelectionL10nKey => 'field_sales.no_customer_cards';

  /// {@template hasSelectableCustomers}
  /// Seçilebilir (boş olmayan id) cari kartı var mı.
  /// {@endtemplate}
  bool get hasSelectableCustomers =>
      customers.any((c) => c.id.trim().isNotEmpty);

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
  CustomerNotifier() : super(const CustomerState()) {
    fetchCustomers();
  }

  /// {@template _mapRows}
  /// SQLite satırlarını modele çevirir; bozuk satırları atlar.
  /// {@endtemplate}
  List<CustomerModel> _mapRows(List<Map<String, dynamic>> rows) {
    final customers = <CustomerModel>[];
    for (final row in rows) {
      try {
        final customer = CustomerModel.fromMap(row);
        if (customer.id.trim().isEmpty) continue;
        customers.add(customer);
      } catch (_) {
        // Tek bozuk satır tüm listeyi boşaltmasın
      }
    }
    return customers;
  }

  /// {@template _tableColumns}
  /// customers tablosu kolon adlarını döner (eski şema uyumu).
  /// {@endtemplate}
  Future<Set<String>> _tableColumns(sqflite.Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(customers)');
    return info
        .map((row) => (row['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  /// {@template _queryCustomers}
  /// Aktif carileri listeler; eksik kolonlarda SQL patlamaz.
  ///
  /// Cihaz kanıtı: 5 satır vardı, `updated_at` null + sabit WHERE
  /// (`code` yokken) catch ile boş listeye düşüyordu. Kolon-aware
  /// WHERE + fromMap null tarih tolere eder.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> _queryCustomers(
    sqflite.Database db, {
    String? search,
  }) async {
    final cols = await _tableColumns(db);
    if (cols.isEmpty) return const [];

    final whereParts = <String>[];
    final args = <Object?>[];

    if (cols.contains('is_active')) {
      whereParts.add('COALESCE(is_active, 1) = 1');
    }

    final q = search?.trim() ?? '';
    if (q.isNotEmpty) {
      final like = '%$q%';
      final orParts = <String>[];
      if (cols.contains('name')) {
        orParts.add('name LIKE ?');
        args.add(like);
      }
      if (cols.contains('tax_no')) {
        orParts.add('tax_no LIKE ?');
        args.add(like);
      }
      if (cols.contains('code')) {
        orParts.add('code LIKE ?');
        args.add(like);
      }
      if (cols.contains('id')) {
        orParts.add('id LIKE ?');
        args.add(like);
      }
      if (orParts.isNotEmpty) {
        whereParts.add('(${orParts.join(' OR ')})');
      }
    }

    return db.query(
      'customers',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: cols.contains('name') ? 'name' : null,
    );
  }

  /// {@template _repairNullTimestamps}
  /// Eski seed satırlarında null `updated_at` değerlerini doldurur.
  /// {@endtemplate}
  Future<void> _repairNullTimestamps(sqflite.Database db) async {
    try {
      final cols = await _tableColumns(db);
      if (!cols.contains('updated_at')) return;
      final now = DateTime.now().toIso8601String();
      await db.rawUpdate(
        "UPDATE customers SET updated_at = ? "
        "WHERE updated_at IS NULL OR TRIM(updated_at) = ''",
        [now],
      );
    } catch (_) {
      // fromMap null tarihi zaten tolere eder
    }
  }

  Future<void> fetchCustomers() async {
    state = state.copyWith(isLoading: true);
    try {
      // Kiracı PostgREST aktifse önce uzak → SQLite senkron
      final rest = PostgresService.instance.activeRemoteRestUrl.trim();
      if (rest.isNotEmpty) {
        try {
          await PostgrestMasterSync().syncCustomersAndProducts();
        } catch (_) {}
      }

      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      await _repairNullTimestamps(sqliteDb);

      final result = await _queryCustomers(sqliteDb);
      final customers = _mapRows(result);

      DataCacheService().set('all_customers', customers);

      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        customers: const [],
        error: e.toString(),
      );
    }
  }

  Future<void> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      return fetchCustomers();
    }

    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final result = await _queryCustomers(sqliteDb, search: query);
      final customers = _mapRows(result);
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        customers: const [],
        error: e.toString(),
      );
    }
  }

  /// {@template saveCustomer}
  /// Cari kartı SQLite'a yazar, sync_queue'ya ekler; REST varsa PostgREST.
  ///
  /// Parametreler:
  /// - [customer]: Kaydedilecek cari
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarı
  /// {@endtemplate}
  Future<bool> saveCustomer(CustomerModel customer) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      await sqliteDb.execute(SqlQuerys.createCustomersTable);
      await sqliteDb.execute(SqlQuerys.createSyncQueueTable);

      final map = customer.toMap();
      await sqliteDb.transaction((txn) async {
        await txn.insert(
          'customers',
          map,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
        await txn.insert('sync_queue', {
          'id': const Uuid().v4(),
          'entity_type': 'customer',
          'entity_id': customer.id,
          'payload': jsonEncode({
            ...map,
            'op': 'upsert',
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      final rest = PostgresService.instance.activeRemoteRestUrl.trim();
      if (rest.isNotEmpty) {
        await PostgrestMasterSync().postCustomer(map);
      } else {
        // Logo kuyruk işleyici bilinmeyen tipi atlar; tetikle
        JobQueueService().processQueue();
      }

      DataCacheService().invalidate('all_customers');
      await fetchCustomers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template deactivateCustomer}
  /// Cariyi soft-delete (`is_active=0`) + sync_queue.
  ///
  /// Parametreler:
  /// - [customerId]: Cari kimliği
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarı
  /// {@endtemplate}
  Future<bool> deactivateCustomer(String customerId) async {
    final id = customerId.trim();
    if (id.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      await sqliteDb.execute(SqlQuerys.createSyncQueueTable);
      final now = DateTime.now().toIso8601String();

      await sqliteDb.transaction((txn) async {
        await txn.update(
          'customers',
          {'is_active': 0, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.insert('sync_queue', {
          'id': const Uuid().v4(),
          'entity_type': 'customer',
          'entity_id': id,
          'payload': jsonEncode({
            'id': id,
            'op': 'deactivate',
            'is_active': 0,
            'updated_at': now,
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': now,
        });
      });

      DataCacheService().invalidate('all_customers');
      await fetchCustomers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier();
});
