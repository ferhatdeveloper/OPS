// Dosya Adı: postgrest_master_sync.dart
// Açıklama: firms/periods/stores çekme + cari/ürün PostgREST ↔ SQLite
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/migrations/SqlQuerys.dart';
import '../../modules/field_sales/stock/model/warehouse_master_seed.dart';
import '../../service/database_service.dart';
import '../../service/postgres_service.dart';
import 'postgrest_http_client.dart';
import 'postgrest_permission_groups_sync.dart';
import 'postgrest_table_names.dart';

/// {@template postgrest_firm_row}
/// `/firms` satırı (login firma seçici).
/// {@endtemplate}
class PostgrestFirmRow {
  /// [id]: UUID
  final String id;

  /// [firmNr]: Firma no (`001`)
  final String firmNr;

  /// [name]: Görünen ad
  final String name;

  /// [isActive]: Aktif mi
  final bool isActive;

  /// [isDefault]: Varsayılan firma
  final bool isDefault;

  /// [defaultCurrency]: Merkez ana para birimi (ana_para_birimi)
  final String? defaultCurrency;

  /// {@macro postgrest_firm_row}
  const PostgrestFirmRow({
    required this.id,
    required this.firmNr,
    required this.name,
    this.isActive = true,
    this.isDefault = false,
    this.defaultCurrency,
  });

  factory PostgrestFirmRow.fromMap(Map<String, dynamic> map) {
    final rawCurrency = map['default_currency'] ??
        map['ana_para_birimi'] ??
        map['currency_code'] ??
        map['base_currency'];
    return PostgrestFirmRow(
      id: (map['id'] ?? map['firm_nr'] ?? '').toString(),
      firmNr: PostgrestTableNames.padFirm(
        (map['firm_nr'] ?? '').toString(),
      ),
      name: (map['name'] ?? map['firm_nr'] ?? '').toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      isDefault: map['default'] == true || map['default'] == 1,
      defaultCurrency: rawCurrency?.toString(),
    );
  }

  /// Kullanıcı firm_nr için sentetik satır (firms tablosunda yoksa).
  factory PostgrestFirmRow.synthetic(String firmNr) {
    final nr = PostgrestTableNames.padFirm(firmNr);
    return PostgrestFirmRow(
      id: 'firm_$nr',
      firmNr: nr,
      name: 'Firma $nr',
      isActive: true,
    );
  }
}

/// {@template postgrest_period_row}
/// `/periods` satırı.
/// {@endtemplate}
class PostgrestPeriodRow {
  /// [id]: UUID
  final String id;

  /// [firmId]: firms.id
  final String firmId;

  /// [nr]: Dönem no (1 → `01`)
  final String nr;

  /// [begDate]: Başlangıç
  final String begDate;

  /// [endDate]: Bitiş
  final String endDate;

  /// [isActive]: Aktif
  final bool isActive;

  /// [isDefault]: Varsayılan
  final bool isDefault;

  /// {@macro postgrest_period_row}
  const PostgrestPeriodRow({
    required this.id,
    required this.firmId,
    required this.nr,
    this.begDate = '',
    this.endDate = '',
    this.isActive = true,
    this.isDefault = false,
  });

  factory PostgrestPeriodRow.fromMap(Map<String, dynamic> map) {
    final rawNr = map['nr'];
    final nrStr = rawNr == null
        ? '01'
        : PostgrestTableNames.padPeriod(rawNr.toString());
    return PostgrestPeriodRow(
      id: (map['id'] ?? '').toString(),
      firmId: (map['firm_id'] ?? '').toString(),
      nr: nrStr,
      begDate: (map['beg_date'] ?? '').toString(),
      endDate: (map['end_date'] ?? '').toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      isDefault: map['default'] == true || map['default'] == 1,
    );
  }

  /// Dönem yoksa varsayılan `01`.
  factory PostgrestPeriodRow.fallback(String firmId) {
    return PostgrestPeriodRow(
      id: 'period_default_$firmId',
      firmId: firmId,
      nr: '01',
      isActive: true,
      isDefault: true,
    );
  }
}

/// {@template postgrest_store_row}
/// RetailEX `/stores` satırı (depo / mağaza master).
/// {@endtemplate}
class PostgrestStoreRow {
  /// [id]: UUID
  final String id;

  /// [code]: Depo/mağaza kodu
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// [firmNr]: Firma no (`001`)
  final String firmNr;

  /// [type]: Opsiyonel tip
  final String type;

  /// [isActive]: Aktif
  final bool isActive;

  /// [isMain]: Ana depo
  final bool isMain;

  /// [isDefault]: Varsayılan
  final bool isDefault;

  /// {@macro postgrest_store_row}
  const PostgrestStoreRow({
    required this.id,
    required this.code,
    required this.name,
    required this.firmNr,
    this.type = '',
    this.isActive = true,
    this.isMain = false,
    this.isDefault = false,
  });

  factory PostgrestStoreRow.fromMap(Map<String, dynamic> map) {
    final code = (map['code'] ?? '').toString().trim();
    final rawType = (map['type'] ?? map['warehouse_type'] ?? '').toString();
    return PostgrestStoreRow(
      id: (map['id'] ?? code).toString(),
      code: code,
      name: (map['name'] ?? code).toString(),
      firmNr: PostgrestTableNames.padFirm(
        (map['firm_nr'] ?? '').toString(),
      ),
      type: rawType.trim().isEmpty ? 'center' : rawType.trim(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      isMain: map['is_main'] == true || map['is_main'] == 1,
      isDefault: map['default'] == true || map['default'] == 1,
    );
  }

  /// Login dens satırına çevirir (l10n key yok — seedName = API adı).
  WarehouseMasterSeedRow toWarehouseSeedRow() {
    return WarehouseMasterSeedRow(
      id: id.isEmpty ? 'store_$code' : id,
      code: code,
      type: type.isEmpty ? 'center' : type,
      nameKey: 'api.store.$code',
      seedName: name,
    );
  }
}

/// {@template postgrest_master_sync}
/// Login sonrası master veri: firms, periods, stores, customers, products.
///
/// Kullanım örneği:
/// ```dart
/// final sync = PostgrestMasterSync();
/// final firms = await sync.fetchFirms(preferFirmNr: '001');
/// final stores = await sync.fetchStores(firmNr: '001');
/// await sync.syncCustomersAndProducts();
/// ```
/// {@endtemplate}
class PostgrestMasterSync {
  /// [client]: HTTP
  final PostgrestHttpClient client;

  /// [postgres]: Aktif firma/dönem
  final PostgresService postgres;

  /// {@macro postgrest_master_sync}
  PostgrestMasterSync({
    PostgrestHttpClient? client,
    PostgresService? postgres,
  })  : client = client ?? PostgrestHttpClient(),
        postgres = postgres ?? PostgresService.instance;

  /// `/firms` listesi + kullanıcı firm_nr / allowed birleşimi.
  Future<List<PostgrestFirmRow>> fetchFirms({
    String? preferFirmNr,
    List<String> allowedFirmNrs = const [],
  }) async {
    final byNr = <String, PostgrestFirmRow>{};
    try {
      final rows = await client.getRows(
        '/firms',
        query: {
          'select': 'id,firm_nr,name,is_active,default',
          'order': 'firm_nr',
        },
      );
      for (final r in rows) {
        final firm = PostgrestFirmRow.fromMap(r);
        if (firm.firmNr.isEmpty) continue;
        byNr[firm.firmNr] = firm;
      }
    } catch (e) {
      debugPrint('PostgrestMasterSync.fetchFirms: $e');
    }

    void ensure(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return;
      final nr = PostgrestTableNames.padFirm(t);
      byNr.putIfAbsent(nr, () => PostgrestFirmRow.synthetic(nr));
    }

    ensure(preferFirmNr ?? '');
    for (final a in allowedFirmNrs) {
      ensure(a);
    }

    final list = byNr.values.toList()
      ..sort((a, b) => a.firmNr.compareTo(b.firmNr));
    return list;
  }

  /// Firma için dönemler; yoksa `01` fallback ([allowFallback]).
  Future<List<PostgrestPeriodRow>> fetchPeriodsForFirm(
    PostgrestFirmRow firm, {
    bool allowFallback = true,
  }) async {
    try {
      final query = <String, String>{
        'select': '*',
        'order': 'nr',
        'is_active': 'eq.true',
      };
      if (firm.id.isNotEmpty && !firm.id.startsWith('firm_')) {
        query['firm_id'] = 'eq.${firm.id}';
      }
      final rows = await client.getRows('/periods', query: query);
      final mapped = rows.map(PostgrestPeriodRow.fromMap).toList();
      if (mapped.isNotEmpty) return mapped;

      // firm_id eşleşmezse embed ile dene
      final all = await client.getRows(
        '/periods',
        query: {
          'select': '*,firms(firm_nr)',
          'order': 'nr',
        },
      );
      final filtered = all.where((r) {
        final firms = r['firms'];
        if (firms is Map) {
          return PostgrestTableNames.padFirm(
                (firms['firm_nr'] ?? '').toString(),
              ) ==
              firm.firmNr;
        }
        return false;
      }).map(PostgrestPeriodRow.fromMap).toList();
      if (filtered.isNotEmpty) return filtered;
    } catch (e) {
      debugPrint('PostgrestMasterSync.fetchPeriods: $e');
    }
    if (allowFallback) {
      return [PostgrestPeriodRow.fallback(firm.id)];
    }
    return const [];
  }

  /// `/firms` → SQLite `companies` (demo seed üzerine yazar).
  Future<int> syncFirmsToSqlite(List<PostgrestFirmRow> firms) async {
    if (firms.isEmpty) return 0;
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      // Bilinen dens demo satırlarını temizle
      await db.delete(
        'companies',
        where: "id = ? OR lower(name) = ? OR name LIKE ?",
        whereArgs: ['mbt_001', 'mbt', '%EXFIN-ERP Demo%'],
      );
      var n = 0;
      for (final f in firms) {
        if (f.firmNr.isEmpty) continue;
        await dbService.addOrUpdateCompany(
          id: f.id.isEmpty ? 'firm_${f.firmNr}' : f.id,
          name: f.name.isEmpty ? f.firmNr : f.name,
          companyNo: f.firmNr,
          description: 'firm_nr=${f.firmNr}',
          isActive: f.isActive,
          defaultCurrency: f.defaultCurrency,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        n++;
      }
      debugPrint('PostgREST → SQLite companies (firms): $n');
      return n;
    } catch (e) {
      debugPrint('PostgrestMasterSync.syncFirmsToSqlite: $e');
      return 0;
    }
  }

  /// `/periods` → SQLite `company_period`.
  Future<int> syncPeriodsToSqlite(
    List<
            ({
              String companyId,
              String companyNo,
              String periodNo,
              String startDate,
              String endDate,
            })>
        periods,
  ) async {
    if (periods.isEmpty) return 0;
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.execute(SqlQuerys.createCompanyPeriodTable);
      await db.delete(
        'company_period',
        where: "company_id = ? OR company_id LIKE ?",
        whereArgs: ['mbt_001', 'mbt_%'],
      );
      final now = DateTime.now().toIso8601String();
      final batch = db.batch();
      var n = 0;
      for (final p in periods) {
        final nr = PostgrestTableNames.padPeriod(p.periodNo);
        if (nr.isEmpty || p.companyNo.isEmpty) continue;
        final id = 'period_${p.companyNo}_$nr';
        batch.insert(
          'company_period',
          {
            'id': id,
            'company_id': p.companyId,
            'period_name': nr,
            'start_date': p.startDate.isEmpty ? now : p.startDate,
            'end_date': p.endDate.isEmpty ? now : p.endDate,
            'is_active': 1,
            'created_at': now,
            'updated_at': now,
            'company_no': PostgrestTableNames.padFirm(p.companyNo),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite company_period: $n');
      return n;
    } catch (e) {
      debugPrint('PostgrestMasterSync.syncPeriodsToSqlite: $e');
      return 0;
    }
  }

  /// Varsayılan / aktif dönem seç.
  PostgrestPeriodRow pickDefaultPeriod(List<PostgrestPeriodRow> periods) {
    if (periods.isEmpty) {
      return PostgrestPeriodRow.fallback('');
    }
    return periods.firstWhere(
      (p) => p.isDefault && p.isActive,
      orElse: () => periods.firstWhere(
        (p) => p.isActive,
        orElse: () => periods.first,
      ),
    );
  }

  /// RetailEX `/stores` (depo/mağaza). Opsiyonel firma filtresi.
  Future<List<PostgrestStoreRow>> fetchStores({String? firmNr}) async {
    try {
      final query = <String, String>{
        'select':
            'id,code,name,type,firm_nr,is_main,is_active,default,'
                'logo_warehouse_id',
        'order': 'code',
        'is_active': 'eq.true',
      };
      final firm = (firmNr ?? '').trim();
      if (firm.isNotEmpty) {
        query['firm_nr'] = 'eq.${PostgrestTableNames.padFirm(firm)}';
      }
      final rows = await client.getRows('/stores', query: query);
      final mapped = rows
          .map(PostgrestStoreRow.fromMap)
          .where((s) => s.code.isNotEmpty)
          .toList();
      if (mapped.isNotEmpty) return mapped;

      // firm_nr filtre boş dönerse tüm aktif store'ları alıp yerelde filtrele
      if (firm.isNotEmpty) {
        final all = await client.getRows(
          '/stores',
          query: {
            'select':
                'id,code,name,type,firm_nr,is_main,is_active,default,'
                    'logo_warehouse_id',
            'order': 'code',
            'is_active': 'eq.true',
          },
        );
        final want = PostgrestTableNames.padFirm(firm);
        return all
            .map(PostgrestStoreRow.fromMap)
            .where((s) => s.code.isNotEmpty && s.firmNr == want)
            .toList();
      }
    } catch (e) {
      debugPrint('PostgrestMasterSync.fetchStores: $e');
    }
    return const [];
  }

  /// Varsayılan depo: default → main → ilk aktif.
  PostgrestStoreRow? pickDefaultStore(List<PostgrestStoreRow> stores) {
    if (stores.isEmpty) return null;
    try {
      return stores.firstWhere((s) => s.isDefault && s.isActive);
    } catch (_) {}
    try {
      return stores.firstWhere((s) => s.isMain && s.isActive);
    } catch (_) {}
    try {
      return stores.firstWhere((s) => s.isActive);
    } catch (_) {
      return stores.first;
    }
  }

  /// `/stores` → SQLite `warehouses` (tenant master; seed MRK/ARC/IAD değil).
  Future<int> syncStoresToSqlite(List<PostgrestStoreRow> stores) async {
    if (stores.isEmpty) return 0;
    try {
      final dbService = await DatabaseService.getInstance();
      await dbService.ensureWarehousesSchema();
      final db = await dbService.getDatabase();
      final now = DateTime.now().toIso8601String();
      final batch = db.batch();
      var n = 0;
      for (final s in stores) {
        batch.insert(
          WarehouseMasterSeed.tableName,
          {
            'id': s.id.isEmpty ? 'store_${s.code}' : s.id,
            'code': s.code,
            'name': s.name,
            'type': s.type.isEmpty ? 'center' : s.type,
            'is_active': s.isActive ? 1 : 0,
            'is_synced': 1,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite warehouses (stores): $n');
      return n;
    } catch (e) {
      debugPrint('PostgrestMasterSync.syncStoresToSqlite: $e');
      return 0;
    }
  }

  /// Aktif firma cari + ürünlerini SQLite'a çeker.
  Future<({int customers, int products})> syncCustomersAndProducts() async {
    final firm = PostgrestTableNames.padFirm(postgres.activeFirmNr);
    final customers = await _syncCustomers(firm);
    final products = await _syncProducts(firm);
    return (customers: customers, products: products);
  }

  /// Yetki grupları pull (opsiyonel; hata yutulur — yerel resolve bozulmaz).
  Future<int> syncPermissionGroupsOptional() {
    return PostgrestPermissionGroupsSync(
      client: client,
      postgres: postgres,
    ).pullOptional();
  }

  Future<int> _syncCustomers(String firmNr) async {
    final table = PostgrestTableNames.firmTable(firmNr, 'customers');
    try {
      final rows = await client.getRows(
        '/$table',
        query: {
          'select':
              'id,code,name,phone,phone2,email,tax_nr,tax_office,address,'
                  'city,district,neighborhood,balance,credit_limit,is_active,'
                  'created_at,notes',
          'order': 'name',
          'limit': '5000',
        },
      );
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.execute(SqlQuerys.createCustomersTable);
      final batch = db.batch();
      var n = 0;
      for (final r in rows) {
        final id = (r['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final now = DateTime.now().toIso8601String();
        batch.insert(
          'customers',
          {
            'id': id,
            'code': r['code']?.toString(),
            'name': (r['name'] ?? '').toString(),
            'tax_no': r['tax_nr']?.toString() ?? r['tax_no']?.toString(),
            'tax_office': r['tax_office']?.toString(),
            'address': r['address']?.toString(),
            'il': r['city']?.toString() ?? r['il']?.toString(),
            'ilce': r['district']?.toString() ?? r['ilce']?.toString(),
            'semt': r['neighborhood']?.toString(),
            'phone': r['phone']?.toString(),
            'telefon2': r['phone2']?.toString(),
            'email': r['email']?.toString(),
            'balance': (r['balance'] as num?)?.toDouble() ?? 0.0,
            'is_active':
                (r['is_active'] == true || r['is_active'] == 1) ? 1 : 0,
            'created_at': (r['created_at'] ?? now).toString(),
            'updated_at': now,
            'card_role': 'customer',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite customers: $n ($table)');
      return n;
    } catch (e) {
      debugPrint('PostgrestMasterSync._syncCustomers: $e');
      return 0;
    }
  }

  Future<int> _syncProducts(String firmNr) async {
    final table = PostgrestTableNames.firmTable(firmNr, 'products');
    try {
      final rows = await client.getRows(
        '/$table',
        query: {
          'select':
              'id,code,name,barcode,unit,price,vat_rate,stock,category_code,'
                  'description,is_active,created_at,updated_at',
          'order': 'name',
          'limit': '5000',
        },
      );
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.execute(SqlQuerys.createProductsTable);
      final batch = db.batch();
      var n = 0;
      final now = DateTime.now().toIso8601String();
      for (final r in rows) {
        final id = (r['id'] ?? '').toString();
        final code = (r['code'] ?? '').toString();
        if (id.isEmpty || code.isEmpty) continue;
        batch.insert(
          'products',
          {
            'id': id,
            'code': code,
            'name': (r['name'] ?? code).toString(),
            'description': r['description']?.toString(),
            'barcode': r['barcode']?.toString(),
            'unit': (r['unit'] ?? 'ADET').toString(),
            'main_unit': (r['unit'] ?? 'ADET').toString(),
            'price': (r['price'] as num?)?.toDouble() ?? 0.0,
            'vat_rate': (r['vat_rate'] as num?)?.toInt() ?? 20,
            'stock_quantity': (r['stock'] as num?)?.toDouble() ?? 0.0,
            'category': r['category_code']?.toString() ??
                r['category']?.toString(),
            'created_at': (r['created_at'] ?? now).toString(),
            'updated_at': (r['updated_at'] ?? now).toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite products: $n ($table)');
      return n;
    } catch (e) {
      debugPrint('PostgrestMasterSync._syncProducts: $e');
      return 0;
    }
  }

  /// Yeni cariyi kiracı PostgREST'e yazar (başarısızsa false).
  Future<bool> postCustomer(Map<String, dynamic> localCustomer) async {
    final firm = PostgrestTableNames.padFirm(postgres.activeFirmNr);
    final table = PostgrestTableNames.firmTable(firm, 'customers');
    try {
      final body = <String, dynamic>{
        if ((localCustomer['id'] ?? '').toString().isNotEmpty)
          'id': localCustomer['id'],
        'firm_nr': firm,
        'code': localCustomer['code'],
        'name': localCustomer['name'],
        'phone': localCustomer['phone'],
        'phone2': localCustomer['telefon2'],
        'email': localCustomer['email'],
        'tax_nr': localCustomer['tax_no'],
        'tax_office': localCustomer['tax_office'],
        'address': localCustomer['address'],
        'city': localCustomer['il'],
        'district': localCustomer['ilce'],
        'neighborhood': localCustomer['semt'],
        'balance': localCustomer['balance'] ?? 0,
        'is_active': true,
      };
      body.removeWhere((k, v) => v == null || (v is String && v.isEmpty));
      await client.postRow('/$table', body);
      return true;
    } catch (e) {
      debugPrint('PostgrestMasterSync.postCustomer: $e');
      return false;
    }
  }
}
