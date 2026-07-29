// Dosya Adı: logo_tiger_pull_sync.dart
// Açıklama: Logo Tiger REST → SQLite offline-first upsert (ürün/cari/ambar/sipariş/kasa/banka)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../service/database_service.dart';
import 'logo_salesman_user_provisioner.dart';
import 'logo_tiger_rest_client.dart';

/// {@template logo_tiger_entity_sync_result}
/// Tek entity sync özeti.
/// {@endtemplate}
class LogoTigerEntitySyncResult {
  final int fetched;
  final int upserted;
  final int errors;
  final String? message;

  /// Kullanıcı provision sayısı (salesmen).
  final int usersCreated;

  const LogoTigerEntitySyncResult({
    this.fetched = 0,
    this.upserted = 0,
    this.errors = 0,
    this.message,
    this.usersCreated = 0,
  });
}

/// {@template logo_tiger_sync_result}
/// Toplu pull sonucu.
/// {@endtemplate}
class LogoTigerSyncResult {
  final bool ok;
  final LogoTigerEntitySyncResult products;
  final LogoTigerEntitySyncResult customers;
  final LogoTigerEntitySyncResult warehouses;
  final LogoTigerEntitySyncResult orders;
  final LogoTigerEntitySyncResult salesmen;
  final LogoTigerEntitySyncResult cash;
  final LogoTigerEntitySyncResult banks;
  final LogoTigerEntitySyncResult currencies;
  final LogoTigerEntitySyncResult unitSets;
  final String? error;
  final List<String> messages;

  const LogoTigerSyncResult({
    required this.ok,
    this.products = const LogoTigerEntitySyncResult(),
    this.customers = const LogoTigerEntitySyncResult(),
    this.warehouses = const LogoTigerEntitySyncResult(),
    this.orders = const LogoTigerEntitySyncResult(),
    this.salesmen = const LogoTigerEntitySyncResult(),
    this.cash = const LogoTigerEntitySyncResult(),
    this.banks = const LogoTigerEntitySyncResult(),
    this.currencies = const LogoTigerEntitySyncResult(),
    this.unitSets = const LogoTigerEntitySyncResult(),
    this.error,
    this.messages = const [],
  });
}

/// {@template logo_tiger_pull_sync}
/// RetailEX `logoRestSync` read/upsert karşılığı — yerel SQLite.
///
/// Kullanım örneği:
/// ```dart
/// final sync = LogoTigerPullSync();
/// final r = await sync.pullAll(cash: true, banks: true);
/// ```
/// {@endtemplate}
class LogoTigerPullSync {
  final LogoTigerRestClient _client;
  final Future<Database> Function()? _dbFactory;
  final LogoSalesmanUserProvisioner _userProvisioner;

  /// {@macro logo_tiger_pull_sync}
  LogoTigerPullSync({
    LogoTigerRestClient? client,
    Future<Database> Function()? dbFactory,
    LogoSalesmanUserProvisioner? userProvisioner,
  })  : _client = client ?? LogoTigerRestClient(),
        _dbFactory = dbFactory,
        _userProvisioner =
            userProvisioner ?? LogoSalesmanUserProvisioner();

  Future<Database> _db() async {
    final factory = _dbFactory;
    if (factory != null) return factory();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template logo_tiger_pull_sync_all}
  /// Ürün + cari + ambar + sipariş + plasiyer (+ kasa/banka/döviz/birim set).
  ///
  /// Yeni bayraklar varsayılan `false` — mevcut çağrılar değişmez.
  /// {@endtemplate}
  Future<LogoTigerSyncResult> pullAll({
    bool products = true,
    bool customers = true,
    bool warehouses = true,
    bool orders = true,
    bool salesmen = true,
    bool cash = false,
    bool banks = false,
    bool currencies = false,
    bool unitSets = false,
    int maxPages = 100,
  }) async {
    final messages = <String>[];
    try {
      final session = await _client.ensureSession();
      if (!session.success) {
        return LogoTigerSyncResult(
          ok: false,
          error: session.error ?? 'Oturum açılamadı',
        );
      }

      final db = await _db();
      var productsR = const LogoTigerEntitySyncResult();
      var customersR = const LogoTigerEntitySyncResult();
      var warehousesR = const LogoTigerEntitySyncResult();
      var ordersR = const LogoTigerEntitySyncResult();
      var salesmenR = const LogoTigerEntitySyncResult();
      var cashR = const LogoTigerEntitySyncResult();
      var banksR = const LogoTigerEntitySyncResult();
      var currenciesR = const LogoTigerEntitySyncResult();
      var unitSetsR = const LogoTigerEntitySyncResult();

      if (products) {
        productsR = await _syncProducts(db, maxPages: maxPages);
        messages.add('Ürün: ${productsR.upserted}/${productsR.fetched}');
      }
      if (customers) {
        customersR = await _syncCustomers(db, maxPages: maxPages);
        messages.add('Cari: ${customersR.upserted}/${customersR.fetched}');
      }
      if (warehouses) {
        warehousesR = await _syncWarehouses(db, maxPages: maxPages);
        messages.add(
          'Ambar/lokasyon: ${warehousesR.upserted}/${warehousesR.fetched}'
          '${warehousesR.message != null ? ' (${warehousesR.message})' : ''}',
        );
      }
      if (orders) {
        ordersR = await _syncOrders(db, maxPages: maxPages);
        messages.add('Sipariş: ${ordersR.upserted}/${ordersR.fetched}');
      }
      if (salesmen) {
        salesmenR = await _syncSalesmen(db, maxPages: maxPages);
        messages.add(
          'Plasiyer: ${salesmenR.upserted}/${salesmenR.fetched}'
          ' · kullanıcı: +${salesmenR.usersCreated}'
          '${salesmenR.message != null ? ' (${salesmenR.message})' : ''}',
        );
      }
      if (cash) {
        cashR = await _syncCash(db, maxPages: maxPages);
        messages.add(
          'Kasa: ${cashR.upserted}/${cashR.fetched}'
          '${cashR.message != null ? ' (${cashR.message})' : ''}',
        );
      }
      if (banks) {
        banksR = await _syncBanks(db, maxPages: maxPages);
        messages.add(
          'Banka: ${banksR.upserted}/${banksR.fetched}'
          '${banksR.message != null ? ' (${banksR.message})' : ''}',
        );
      }
      if (currencies) {
        currenciesR = await _syncCurrencies(db, maxPages: maxPages);
        messages.add(
          'Döviz: ${currenciesR.upserted}/${currenciesR.fetched}'
          '${currenciesR.message != null ? ' (${currenciesR.message})' : ''}',
        );
      }
      if (unitSets) {
        unitSetsR = await _syncUnitSets(db, maxPages: maxPages);
        messages.add(
          'Birim set: ${unitSetsR.upserted}/${unitSetsR.fetched}'
          '${unitSetsR.message != null ? ' (${unitSetsR.message})' : ''}',
        );
      }

      final anyError = productsR.errors +
              customersR.errors +
              warehousesR.errors +
              ordersR.errors +
              salesmenR.errors +
              cashR.errors +
              banksR.errors +
              currenciesR.errors +
              unitSetsR.errors >
          0;
      return LogoTigerSyncResult(
        ok: !anyError,
        products: productsR,
        customers: customersR,
        warehouses: warehousesR,
        orders: ordersR,
        salesmen: salesmenR,
        cash: cashR,
        banks: banksR,
        currencies: currenciesR,
        unitSets: unitSetsR,
        messages: messages,
        error: anyError ? 'Bazı kayıtlar atlandı/hatalı' : null,
      );
    } catch (e, st) {
      debugPrint('LogoTigerPullSync: $e\n$st');
      return LogoTigerSyncResult(ok: false, error: e.toString());
    }
  }

  Future<LogoTigerEntitySyncResult> _syncProducts(
    Database db, {
    required int maxPages,
  }) async {
    final rows = await _client.fetchItems(maxPages: maxPages);
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final code = _str(row, ['CODE', 'code']);
        if (code.isEmpty) continue;
        final name = _str(row, ['NAME', 'name'], fallback: code);
        final data = <String, Object?>{
          'id': code,
          'code': code,
          'name': name,
          'barcode': _str(row, ['BARCODE', 'barcode']),
          'unit': _str(row, ['UNIT', 'unit'], fallback: 'AD'),
          'price': _num(row, ['PRICE', 'price', 'VATMATRAH']),
          'stock_quantity': _num(row, ['ONHAND', 'stock', 'STOCK_QTY']),
          'vat_rate': _num(row, ['VAT', 'vat_rate'], fallback: 20).round(),
          'updated_at': now,
          'created_at': now,
        };
        await db.insert(
          'products',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger product upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  Future<LogoTigerEntitySyncResult> _syncCustomers(
    Database db, {
    required int maxPages,
  }) async {
    final rows = await _client.fetchArps(maxPages: maxPages);
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final code = _str(row, ['CODE', 'code']);
        if (code.isEmpty) continue;
        final name = _str(
          row,
          ['DEFINITION_', 'DEFINITION', 'TITLE', 'name', 'NAME'],
          fallback: code,
        );
        final existing = await db.query(
          'customers',
          where: 'id = ? OR code = ?',
          whereArgs: [code, code],
          limit: 1,
        );
        final data = <String, Object?>{
          'id': existing.isNotEmpty ? existing.first['id'] : code,
          'code': code,
          'name': name,
          'tax_no': _str(row, ['TAXNR', 'tax_number', 'tax_no']),
          'tax_office': _str(row, ['TAXOFFICE', 'tax_office']),
          'address': _str(row, ['ADDR1', 'address']),
          'il': _str(row, ['CITY', 'city', 'il']),
          'phone': _str(row, ['TELNRS1', 'phone', 'TELNR1']),
          'email': _str(row, ['EMAILADDR', 'email']),
          'balance': _num(row, ['BALANCE', 'balance']),
          'is_active': 1,
          'updated_at': now,
          'created_at': existing.isNotEmpty
              ? existing.first['created_at']
              : now,
        };
        await db.insert(
          'customers',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger customer upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  Future<LogoTigerEntitySyncResult> _syncWarehouses(
    Database db, {
    required int maxPages,
  }) async {
    // Logo Tiger’da ayrı warehouses kaynağı yok; locationCodes dene.
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client.fetchLocationCodes(maxPages: maxPages);
    } catch (e) {
      return LogoTigerEntitySyncResult(
        message: 'locationCodes okunamadı: $e',
      );
    }
    if (rows.isEmpty) {
      return const LogoTigerEntitySyncResult(
        message: 'locationCodes boş veya yetkisiz — ambar atlandı',
      );
    }
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final code = _str(row, ['CODE', 'code', 'LOCCODE']);
        if (code.isEmpty) continue;
        final name = _str(
          row,
          ['NAME', 'name', 'DESCRIPTION', 'DEFINITION_'],
          fallback: code,
        );
        await db.insert(
          'warehouses',
          {
            'id': code,
            'code': code,
            'name': name,
            'type': 'location',
            'is_active': 1,
            'is_synced': 1,
            'is_deleted': 0,
            'updated_at': now,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger warehouse upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  Future<LogoTigerEntitySyncResult> _syncOrders(
    Database db, {
    required int maxPages,
  }) async {
    final rows = await _client.fetchSalesOrders(maxPages: maxPages);
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final ref = _str(
          row,
          ['INTERNAL_REFERENCE', 'LOGICALREF', 'NUMBER', 'FICHENO', 'code'],
        );
        if (ref.isEmpty) continue;
        final id = 'logo_so_$ref';
        final customerCode = _str(
          row,
          ['ARP_CODE', 'CLIENTCODE', 'CUSTOMER_CODE', 'code'],
        );
        final total = _num(
          row,
          ['TOTAL_NET', 'GROSS_TOTAL', 'TOTAL', 'total_amount'],
        );
        final date = _str(row, ['DATE', 'order_date', 'DATE_'], fallback: now);
        await db.insert(
          'orders',
          {
            'id': id,
            'customer_id': customerCode.isEmpty ? null : customerCode,
            'order_date': date,
            'total_amount': total,
            'status': 'Approved',
            'notes': 'logo_tiger_pull',
            'is_synced': 1,
            'is_deleted': 0,
            'approval_status': 1,
            'order_type': 'sales',
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger order upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  /// Plasiyer kartları + OPS kullanıcı provision (şifre 1234).
  Future<LogoTigerEntitySyncResult> _syncSalesmen(
    Database db, {
    required int maxPages,
  }) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client.fetchSalesmen(maxPages: maxPages);
    } catch (e) {
      return LogoTigerEntitySyncResult(
        message: 'salesmen okunamadı: $e',
      );
    }
    if (rows.isEmpty) {
      return const LogoTigerEntitySyncResult(
        message: 'salesmen boş veya kaynak yok',
      );
    }

    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    final forUsers = <Map<String, String>>[];

    for (final row in rows) {
      try {
        final code = _str(row, ['CODE', 'code', 'SPECODE', 'SALESMANCODE']);
        if (code.isEmpty) continue;
        final name = _str(
          row,
          ['NAME', 'name', 'DEFINITION_', 'DEFINITION', 'TITLE'],
          fallback: code,
        );
        final logoRef = _str(
          row,
          ['LOGICALREF', 'INTERNAL_REFERENCE', 'REF'],
        );
        await db.insert(
          'salesmen',
          {
            'id': code,
            'code': code,
            'name': name,
            'is_active': 1,
            'logo_ref': logoRef.isEmpty ? null : logoRef,
            'is_synced': 1,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        forUsers.add({'code': code, 'name': name});
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger salesman upsert: $e');
      }
    }

    final usersCreated = await _userProvisioner.ensureUsers(db, forUsers);

    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
      usersCreated: usersCreated,
    );
  }

  /// Kasa kartları → `cash_cards`.
  Future<LogoTigerEntitySyncResult> _syncCash(
    Database db, {
    required int maxPages,
  }) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client.fetchCash(maxPages: maxPages);
    } catch (e) {
      return LogoTigerEntitySyncResult(
        message: 'cash okunamadı: $e',
      );
    }
    if (rows.isEmpty) {
      return const LogoTigerEntitySyncResult(
        message: 'cash boş veya kaynak yok',
      );
    }
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final code = _str(row, ['CODE', 'code', 'SAFECODE']);
        if (code.isEmpty) continue;
        final name = _str(
          row,
          ['NAME', 'name', 'DEFINITION_', 'DEFINITION', 'DESCRIPTION'],
          fallback: code,
        );
        await db.insert(
          'cash_cards',
          {
            'id': code,
            'code': code,
            'name': name,
            'name_key': 'logo_cash_$code',
            'is_active': 1,
            'is_synced': 1,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger cash upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  /// Banka kartları → `bank_cards`.
  Future<LogoTigerEntitySyncResult> _syncBanks(
    Database db, {
    required int maxPages,
  }) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client.fetchBanks(maxPages: maxPages);
    } catch (e) {
      return LogoTigerEntitySyncResult(
        message: 'banks okunamadı: $e',
      );
    }
    if (rows.isEmpty) {
      return const LogoTigerEntitySyncResult(
        message: 'banks boş veya kaynak yok',
      );
    }
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final code = _str(row, ['CODE', 'code', 'BANKCODE', 'ACCOUNTCODE']);
        if (code.isEmpty) continue;
        final name = _str(
          row,
          ['NAME', 'name', 'DEFINITION_', 'DEFINITION', 'DESCRIPTION'],
          fallback: code,
        );
        final balance = _num(
          row,
          ['BALANCE', 'balance', 'BALANCE_TL', 'DEBIT'],
        );
        await db.insert(
          'bank_cards',
          {
            'id': code,
            'code': code,
            'name': name,
            'name_key': 'logo_bank_$code',
            'balance_tl': balance,
            'balance_usd': 0,
            'balance_iqd': 0,
            'is_active': 1,
            'is_synced': 1,
            'is_deleted': 0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger bank upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  /// Döviz — yerel kalıcı kur tablosu yok; tablo uydurma.
  Future<LogoTigerEntitySyncResult> _syncCurrencies(
    Database db, {
    required int maxPages,
  }) async {
    // Yerel FX şeması yok → fetch edilmez, tablo yaratılmaz.
    // db/maxPages imza tutarlılığı (ileride tablo eklenirse kullanılır).
    if (!db.isOpen || maxPages < 0) {
      return const LogoTigerEntitySyncResult(message: 'no local table');
    }
    return const LogoTigerEntitySyncResult(
      fetched: 0,
      upserted: 0,
      errors: 0,
      message: 'no local table',
    );
  }

  /// Birim setleri → `unit_sets` + `unit_set_lines`.
  Future<LogoTigerEntitySyncResult> _syncUnitSets(
    Database db, {
    required int maxPages,
  }) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client.fetchUnitSets(maxPages: maxPages);
    } catch (e) {
      return LogoTigerEntitySyncResult(
        message: 'unitSets okunamadı: $e',
      );
    }
    if (rows.isEmpty) {
      return const LogoTigerEntitySyncResult(
        message: 'unitSets boş veya kaynak yok',
      );
    }
    var upserted = 0;
    var errors = 0;
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      try {
        final id = _str(
          row,
          ['CODE', 'code', 'LOGICALREF', 'INTERNAL_REFERENCE'],
        );
        if (id.isEmpty) continue;
        final name = _str(
          row,
          ['DESCRIPTION', 'NAME', 'name', 'DEFINITION_', 'DEFINITION'],
          fallback: id,
        );
        await db.insert(
          'unit_sets',
          {
            'id': id,
            'name': name,
            'is_active': 1,
            'is_synced': 1,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _upsertUnitSetLines(db, unitSetId: id, row: row);
        upserted++;
      } catch (e) {
        errors++;
        debugPrint('LogoTiger unitSet upsert: $e');
      }
    }
    return LogoTigerEntitySyncResult(
      fetched: rows.length,
      upserted: upserted,
      errors: errors,
    );
  }

  Future<void> _upsertUnitSetLines(
    Database db, {
    required String unitSetId,
    required Map<String, dynamic> row,
  }) async {
    final lines = _extractUnitLines(row);
    if (lines.isEmpty) return;
    await db.delete(
      'unit_set_lines',
      where: 'unit_set_id = ?',
      whereArgs: [unitSetId],
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final unitName = _str(
        line,
        ['UNIT_CODE', 'unit_code', 'CODE', 'code', 'UNIT', 'name'],
      );
      if (unitName.isEmpty) continue;
      final factor = _num(
        line,
        ['CONV_FACT', 'conversion_factor', 'FACTOR', 'conv_fact'],
        fallback: 1,
      );
      final isMain = _num(
        line,
        ['MAIN_UNIT', 'is_main_unit', 'MAIN'],
      );
      await db.insert(
        'unit_set_lines',
        {
          'id': '${unitSetId}_$unitName',
          'unit_set_id': unitSetId,
          'unit_name': unitName,
          'conversion_factor': factor,
          'is_main_unit': isMain != 0 ? 1 : (i == 0 ? 1 : 0),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static List<Map<String, dynamic>> _extractUnitLines(
    Map<String, dynamic> row,
  ) {
    for (final key in ['UNITS', 'units', 'LINES', 'lines', 'ITEMS']) {
      final v = row[key];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (v is Map) {
        final nested = LogoTigerRestClient.extractItems(v);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  static String _str(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return fallback;
  }

  static num _num(
    Map<String, dynamic> row,
    List<String> keys, {
    num fallback = 0,
  }) {
    for (final k in keys) {
      final v = row[k];
      if (v is num) return v;
      if (v != null) {
        final p = num.tryParse(v.toString().replaceAll(',', '.'));
        if (p != null) return p;
      }
    }
    return fallback;
  }
}
