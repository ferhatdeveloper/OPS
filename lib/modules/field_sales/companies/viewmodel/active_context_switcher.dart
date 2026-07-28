// Dosya Adı: active_context_switcher.dart
// Açıklama: Uygulama içi firma/dönem/ambar bağlam geçişi + master yenileme
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';

import '../../../../core/tenant/postgrest_master_sync.dart';
import '../../../../core/tenant/postgrest_table_names.dart';
import '../../../../service/data_cache_service.dart';
import '../../../../service/database_service.dart';
import '../../../../service/postgres_service.dart';
import '../../stock/model/active_warehouse_session.dart';
import '../../stock/model/warehouse_master_seed.dart';
import '../../stock/viewmodel/active_warehouse_store.dart';
import '../model/active_company_session.dart';
import 'active_company_store.dart';
import 'company_context_loader.dart';

/// {@template active_context_switch_result}
/// Firma/dönem geçişi sonucu (ambar + sync özeti).
/// {@endtemplate}
class ActiveContextSwitchResult {
  /// [company]: Kaydedilen firma/dönem
  final ActiveCompanySession company;

  /// [warehouse]: Güncel veya yeniden seçilen ambar
  final ActiveWarehouseSession? warehouse;

  /// [customersSynced]: Senkron cari adedi
  final int customersSynced;

  /// [productsSynced]: Senkron ürün adedi
  final int productsSynced;

  /// [storesSynced]: Senkron store/ambar adedi
  final int storesSynced;

  /// {@macro active_context_switch_result}
  const ActiveContextSwitchResult({
    required this.company,
    this.warehouse,
    this.customersSynced = 0,
    this.productsSynced = 0,
    this.storesSynced = 0,
  });
}

/// {@template active_context_switcher}
/// Aktif firma/dönem/ambarı kaydeder; Postgres bağlamı, ambar listesi
/// ve (mümkünse) cari/ürün master’ını yeniler.
///
/// Kullanım örneği:
/// ```dart
/// final result = await const ActiveContextSwitcher().applyCompany(
///   ActiveCompanySession(
///     companyId: 'mbt_001',
///     companyName: 'MBT',
///     companyNo: '001',
///     periodNo: '01',
///   ),
/// );
/// print(result.company.appBarLabel);
/// ```
/// {@endtemplate}
class ActiveContextSwitcher {
  /// [companyStore]: Firma/dönem oturumu
  final ActiveCompanyStore companyStore;

  /// [warehouseStore]: Ambar oturumu
  final ActiveWarehouseStore warehouseStore;

  /// [syncMaster]: PostgREST master sync açıksa true
  final bool syncMaster;

  /// [syncFactory]: Test enjeksiyonu
  final PostgrestMasterSync Function()? syncFactory;

  /// [dbFactory]: Test enjeksiyonu
  final Future<DatabaseService> Function()? dbFactory;

  /// [clearCache]: Bağımlı önbelleği temizle
  final bool clearCache;

  /// [persistLocalDb]: SQLite firma seçim işaretleri
  final bool persistLocalDb;

  /// {@macro active_context_switcher}
  const ActiveContextSwitcher({
    this.companyStore = const ActiveCompanyStore(),
    this.warehouseStore = const ActiveWarehouseStore(),
    this.syncMaster = true,
    this.syncFactory,
    this.dbFactory,
    this.clearCache = true,
    this.persistLocalDb = true,
  });

  /// {@template active_context_switcher_apply_company}
  /// Firma+dönemi aktifleştirir; ambarı firmaya göre doğrular/seçer.
  ///
  /// Parametreler:
  /// - [session]: Yeni firma/dönem
  ///
  /// Dönüş değeri:
  /// - [ActiveContextSwitchResult]: Güncel bağlam özeti
  /// {@endtemplate}
  Future<ActiveContextSwitchResult> applyCompany(
    ActiveCompanySession session,
  ) async {
    await companyStore.save(session);
    if (persistLocalDb) {
      await _persistCompanySelection(session);
    }
    if (clearCache) {
      DataCacheService().clear();
    }

    var storesSynced = 0;
    ActiveWarehouseSession? warehouse;
    var customersSynced = 0;
    var productsSynced = 0;

    if (syncMaster && session.isNotEmpty) {
      try {
        final sync = syncFactory?.call() ?? PostgrestMasterSync();
        final firmNr = PostgrestTableNames.padFirm(session.companyNo);
        final restReady =
            PostgresService.instance.activeRemoteRestUrl.trim().isNotEmpty;

        if (restReady) {
          var stores = await sync.fetchStores(firmNr: firmNr);
          stores = stores.where((s) => s.firmNr == firmNr).toList();
          if (stores.isNotEmpty) {
            storesSynced = await sync.syncStoresToSqlite(stores);
            warehouse = await _resolveWarehouseForStores(sync, stores);
          }
        }

        warehouse ??= await _resolveWarehouseFromSqlite(preferKeep: true);

        final master = await sync.syncCustomersAndProducts();
        customersSynced = master.customers;
        productsSynced = master.products;
        await sync.syncPermissionGroupsOptional();
      } catch (e) {
        debugPrint('ActiveContextSwitcher.applyCompany sync: $e');
      }
    }

    return ActiveContextSwitchResult(
      company: session,
      warehouse: warehouse ?? ActiveWarehouseStore.current,
      customersSynced: customersSynced,
      productsSynced: productsSynced,
      storesSynced: storesSynced,
    );
  }

  /// {@template active_context_switcher_apply_warehouse}
  /// Aktif ambarı kaydeder.
  ///
  /// Parametreler:
  /// - [session]: Seçilen ambar
  /// {@endtemplate}
  Future<void> applyWarehouse(ActiveWarehouseSession session) async {
    await warehouseStore.save(session);
  }

  /// Yerel DB’de seçili firma/dönem işaretleri.
  Future<void> _persistCompanySelection(ActiveCompanySession session) async {
    try {
      final db = await (dbFactory?.call() ?? DatabaseService.getInstance());
      if (session.companyId.isNotEmpty) {
        // Demo seed id’si: gerçek API satırı gibi upsert et
        if (CompanyContextLoader.isDemoCompanySeed(
          id: session.companyId,
          name: session.companyName,
        )) {
          await db.addOrUpdateCompany(
            id: session.companyId,
            name: session.companyName,
            companyNo: session.companyNo,
            description: 'session',
            isActive: true,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            isSelected: true,
          );
        } else {
          await db.updateCompanySelection(session.companyId);
        }
      }
      if (session.periodNo.isNotEmpty) {
        await db.updateCompanyPeriod(session.periodNo);
      }
    } catch (e) {
      debugPrint('ActiveContextSwitcher._persistCompanySelection: $e');
    }
  }

  /// PostgREST store listesine göre ambar seç / kaydet.
  Future<ActiveWarehouseSession?> _resolveWarehouseForStores(
    PostgrestMasterSync sync,
    List<PostgrestStoreRow> stores,
  ) async {
    final current = await warehouseStore.load();
    PostgrestStoreRow? match;
    if (current.isNotEmpty) {
      for (final s in stores) {
        if (s.code == current.code) {
          match = s;
          break;
        }
      }
    }
    match ??= sync.pickDefaultStore(stores) ??
        (stores.isEmpty ? null : stores.first);
    if (match == null) {
      await warehouseStore.clear();
      return null;
    }
    final session = ActiveWarehouseSession(
      code: match.code,
      name: match.name,
      type: match.type,
    );
    await warehouseStore.save(session);
    return session;
  }

  /// SQLite / seed ambarlarından seçim.
  Future<ActiveWarehouseSession?> _resolveWarehouseFromSqlite({
    required bool preferKeep,
  }) async {
    try {
      final current = await warehouseStore.load();
      final db = await (dbFactory?.call() ?? DatabaseService.getInstance());
      await db.ensureWarehousesSchema();
      final rawDb = await db.getDatabase();
      final maps = await rawDb.query(WarehouseMasterSeed.tableName);

      if (maps.isEmpty) {
        if (preferKeep && current.isNotEmpty) return current;
        final restReady =
            PostgresService.instance.activeRemoteRestUrl.trim().isNotEmpty;
        if (restReady) {
          await warehouseStore.clear();
          return null;
        }
        final seed = WarehouseMasterSeed.byCode('ARC') ??
            WarehouseMasterSeed.defaultRows.first;
        final session = ActiveWarehouseSession(
          code: seed.code,
          name: seed.seedName,
          type: seed.type,
        );
        await warehouseStore.save(session);
        return session;
      }

      if (preferKeep && current.isNotEmpty) {
        for (final m in maps) {
          if ((m['code'] ?? '').toString() == current.code) {
            return current;
          }
        }
      }

      final first = maps.first;
      final code = (first['code'] ?? '').toString();
      final name = (first['name'] ?? code).toString();
      final type = (first['type'] ?? '').toString();
      final session = ActiveWarehouseSession(
        code: code,
        name: name,
        type: type,
      );
      await warehouseStore.save(session);
      return session;
    } catch (e) {
      debugPrint('ActiveContextSwitcher._resolveWarehouseFromSqlite: $e');
      return ActiveWarehouseStore.current;
    }
  }
}
