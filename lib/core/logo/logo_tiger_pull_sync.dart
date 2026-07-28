// Dosya Adı: logo_tiger_pull_sync.dart
// Açıklama: Logo Tiger REST → SQLite offline-first upsert (ürün/cari/ambar/sipariş)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../service/database_service.dart';
import 'logo_tiger_rest_client.dart';

/// {@template logo_tiger_entity_sync_result}
/// Tek entity sync özeti.
/// {@endtemplate}
class LogoTigerEntitySyncResult {
  final int fetched;
  final int upserted;
  final int errors;
  final String? message;

  const LogoTigerEntitySyncResult({
    this.fetched = 0,
    this.upserted = 0,
    this.errors = 0,
    this.message,
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
  final String? error;
  final List<String> messages;

  const LogoTigerSyncResult({
    required this.ok,
    this.products = const LogoTigerEntitySyncResult(),
    this.customers = const LogoTigerEntitySyncResult(),
    this.warehouses = const LogoTigerEntitySyncResult(),
    this.orders = const LogoTigerEntitySyncResult(),
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
/// final r = await sync.pullAll();
/// ```
/// {@endtemplate}
class LogoTigerPullSync {
  final LogoTigerRestClient _client;
  final Future<Database> Function()? _dbFactory;

  /// {@macro logo_tiger_pull_sync}
  LogoTigerPullSync({
    LogoTigerRestClient? client,
    Future<Database> Function()? dbFactory,
  })  : _client = client ?? LogoTigerRestClient(),
        _dbFactory = dbFactory;

  Future<Database> _db() async {
    final factory = _dbFactory;
    if (factory != null) return factory();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template logo_tiger_pull_sync_all}
  /// Ürün + cari + ambar(locationCodes) + satış siparişleri çeker.
  /// {@endtemplate}
  Future<LogoTigerSyncResult> pullAll({
    bool products = true,
    bool customers = true,
    bool warehouses = true,
    bool orders = true,
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

      final anyError = productsR.errors +
              customersR.errors +
              warehousesR.errors +
              ordersR.errors >
          0;
      return LogoTigerSyncResult(
        ok: !anyError,
        products: productsR,
        customers: customersR,
        warehouses: warehousesR,
        orders: ordersR,
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
