// Dosya Adı: stock_report_query_service.dart
// Açıklama: 9+ STOK MBT rapor satırlarını SQLite’tan ReportLayout sütunlarına mapler
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import 'stock_report_filter.dart';
import 'stock_report_ids.dart';

/// {@template stock_report_query_service}
/// STOK raporları için dens PDF satır üretici (columnId → metin).
///
/// Kullanım örneği:
/// ```dart
/// final rows = await StockReportQueryService().fetchRows(
///   db: db,
///   reportId: 'stok_bakiye',
///   filter: const StockReportFilter(gtZero: true),
/// );
/// ```
/// {@endtemplate}
class StockReportQueryService {
  /// {@macro stock_report_query_service}
  const StockReportQueryService();

  /// {@template stock_report_query_service_handles}
  /// Rapor id destekleniyor mu?
  /// {@endtemplate}
  static bool handles(String reportId) => StockReportIds.handles(reportId);

  /// {@template stock_report_query_service_fetch_rows}
  /// Rapor id’ye göre SQLite satırlarını layout map listesine çevirir.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite
  /// - [reportId]: Katalog id
  /// - [filter]: Parametre filtresi
  ///
  /// Dönüş değeri:
  /// - [List]: columnId → string satırlar
  /// {@endtemplate}
  Future<List<Map<String, String>>> fetchRows({
    required Database db,
    required String reportId,
    StockReportFilter filter = const StockReportFilter(),
  }) async {
    await _ensureTables(db);
    switch (reportId) {
      case StockReportIds.stokBakiye:
        return _stokBakiye(db, filter);
      case StockReportIds.stokEnvanter:
        return _stokEnvanter(db, filter);
      case StockReportIds.stokHareket:
        return _stokHareket(db, filter);
      case StockReportIds.seriLot:
        return _seriLot(db, filter);
      case StockReportIds.urunHangiDepo:
        return _urunDepo(db, filter, byProduct: true);
      case StockReportIds.depodaHangiUrun:
        return _urunDepo(db, filter, byProduct: false);
      case StockReportIds.satisiYapilmayanUrun:
        return _satisiYapilmayan(db, filter);
      case StockReportIds.enCokSatilanUrun:
        return _urunRanking(db, filter, purchase: false);
      case StockReportIds.enCokAlinanUrun:
        return _urunRanking(db, filter, purchase: true);
      case StockReportIds.aracStok:
      case StockReportIds.opsVanStock:
        return _aracStok(db, filter);
      case StockReportIds.stokSayim:
        return _stokSayim(db, filter);
      default:
        return const [];
    }
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute(SqlQuerys.createProductsTable);
    await db.execute(SqlQuerys.createWarehousesTable);
    await db.execute(SqlQuerys.createWarehouseStocksTable);
    await db.execute(SqlQuerys.createWarehouseTransfersTable);
    await db.execute(SqlQuerys.createBatchExpiryTable);
    await db.execute(SqlQuerys.createVehiclesTable);
    await db.execute(SqlQuerys.createVehicleStocksTable);
    await db.execute(SqlQuerys.createStockCountsTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute(SqlQuerys.createInvoicesTable);
    await db.execute(SqlQuerys.createInvoiceItemsTable);
  }

  Future<List<Map<String, String>>> _stokBakiye(
    Database db,
    StockReportFilter f,
  ) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    _appendCodeNameRange(where, args, f, alias: 'p');
    _appendBalanceFilter(where, args, f, expr: 'COALESCE(p.stock_quantity, 0)');

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        COALESCE(p.stock_quantity, 0) AS balance,
        COALESCE(p.barcode, '') AS barcode,
        COALESCE(p.unit, p.main_unit, '') AS unit,
        COALESCE(p.price, 0) AS price,
        COALESCE(p.vat_rate, 0) AS vat_rate,
        COALESCE(p.category, '') AS category,
        COALESCE(p.description, '') AS description
      FROM products p
      WHERE ${where.join(' AND ')}
      ORDER BY p.code ASC
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'balance': _num(r['balance']),
            'barcode': '${r['barcode']}',
            'unit': '${r['unit']}',
            'price': _num(r['price']),
            'vat_rate': '${r['vat_rate']}',
            'category': '${r['category']}',
            'description': '${r['description']}',
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _stokEnvanter(
    Database db,
    StockReportFilter f,
  ) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    _appendCodeNameRange(where, args, f, alias: 'p');
    _appendWarehouse(where, args, f, expr: 'COALESCE(w.code, ws.warehouse_code)');
    _appendBalanceFilter(where, args, f, expr: 'COALESCE(ws.quantity, 0)');

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        COALESCE(w.name, w.code, ws.warehouse_code, '') AS warehouse,
        COALESCE(ws.quantity, 0) AS balance,
        COALESCE(p.barcode, '') AS barcode,
        COALESCE(p.unit, p.main_unit, '') AS unit,
        COALESCE(p.category, '') AS category
      FROM warehouse_stocks ws
      LEFT JOIN products p ON p.id = ws.product_id
      LEFT JOIN warehouses w ON w.code = ws.warehouse_code
      WHERE ${where.join(' AND ')}
      ORDER BY warehouse ASC, p.code ASC
      ''',
      args,
    );
    if (maps.isNotEmpty) {
      return maps
          .map(
            (r) => <String, String>{
              'stock_code': '${r['stock_code']}',
              'stock_name': '${r['stock_name']}',
              'warehouse': '${r['warehouse']}',
              'balance': _num(r['balance']),
              'barcode': '${r['barcode']}',
              'unit': '${r['unit']}',
              'category': '${r['category']}',
            },
          )
          .toList(growable: false);
    }
    // Fallback: ürün kartı bakiyesi (ambar yoksa)
    return _stokBakiye(db, f).then(
      (rows) => rows
          .map(
            (r) => <String, String>{
              ...r,
              'warehouse': f.warehouse.trim().isEmpty ? '—' : f.warehouse,
            },
          )
          .toList(growable: false),
    );
  }

  Future<List<Map<String, String>>> _stokHareket(
    Database db,
    StockReportFilter f,
  ) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    _appendCodeNameRange(where, args, f, alias: 'p');
    _appendDateRange(
      where,
      args,
      f,
      expr: 'date(COALESCE(t.transfer_date, t.created_at))',
    );
    if (f.warehouse.trim().isNotEmpty) {
      where.add(
        '(COALESCE(t.from_warehouse, "") LIKE ? OR '
        'COALESCE(t.to_warehouse, "") LIKE ?)',
      );
      final w = '%${f.warehouse.trim()}%';
      args.addAll([w, w]);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(t.transfer_date, t.created_at, '') AS event_date,
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        COALESCE(t.to_warehouse, t.from_warehouse, '') AS warehouse,
        COALESCE(t.from_warehouse, '') || ' → ' ||
          COALESCE(t.to_warehouse, '') AS description,
        COALESCE(t.quantity, 0) AS quantity
      FROM warehouse_transfers t
      LEFT JOIN products p ON p.id = t.product_id
      WHERE ${where.join(' AND ')}
      ORDER BY event_date DESC, p.code ASC
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'date': _date(r['event_date']?.toString()),
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'warehouse': '${r['warehouse']}',
            'description': '${r['description']}',
            'quantity': _num(r['quantity']),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _seriLot(
    Database db,
    StockReportFilter f,
  ) async {
    final where = <String>['COALESCE(b.is_deleted, 0) = 0'];
    final args = <Object?>[];
    if (f.code.trim().isNotEmpty) {
      where.add('COALESCE(b.product_code, "") >= ?');
      args.add(f.code.trim());
    }
    if (f.code2.trim().isNotEmpty) {
      where.add('COALESCE(b.product_code, "") <= ?');
      args.add(f.code2.trim());
    }
    if (f.name.trim().isNotEmpty) {
      where.add('COALESCE(b.product_name, "") LIKE ?');
      args.add('%${f.name.trim()}%');
    }
    _appendBalanceFilter(where, args, f, expr: 'COALESCE(b.quantity, 0)');
    if (f.warehouse.trim().isNotEmpty) {
      where.add(
        '(COALESCE(b.warehouse_code, "") LIKE ? OR '
        'COALESCE(b.warehouse_name, "") LIKE ?)',
      );
      final w = '%${f.warehouse.trim()}%';
      args.addAll([w, w]);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(b.product_code, '') AS stock_code,
        COALESCE(b.product_name, '') AS stock_name,
        COALESCE(b.lot_no, '') AS serial,
        COALESCE(b.quantity, 0) AS balance
      FROM batch_expiry b
      WHERE ${where.join(' AND ')}
      ORDER BY b.product_code ASC, b.lot_no ASC
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'serial': '${r['serial']}',
            'balance': _num(r['balance']),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _urunDepo(
    Database db,
    StockReportFilter f, {
    required bool byProduct,
  }) async {
    final where = <String>['COALESCE(ws.quantity, 0) != 0'];
    final args = <Object?>[];
    _appendCodeNameRange(where, args, f, alias: 'p');
    _appendWarehouse(where, args, f, expr: 'COALESCE(w.code, ws.warehouse_code)');
    _appendBalanceFilter(where, args, f, expr: 'COALESCE(ws.quantity, 0)');
    final order = byProduct
        ? 'p.code ASC, warehouse ASC'
        : 'warehouse ASC, p.code ASC';

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        COALESCE(w.name, w.code, ws.warehouse_code, '') AS warehouse,
        COALESCE(ws.quantity, 0) AS balance,
        COALESCE(p.barcode, '') AS barcode,
        COALESCE(p.unit, p.main_unit, '') AS unit,
        COALESCE(p.category, '') AS category
      FROM warehouse_stocks ws
      LEFT JOIN products p ON p.id = ws.product_id
      LEFT JOIN warehouses w ON w.code = ws.warehouse_code
      WHERE ${where.join(' AND ')}
      ORDER BY $order
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'warehouse': '${r['warehouse']}',
            'balance': _num(r['balance']),
            'barcode': '${r['barcode']}',
            'unit': '${r['unit']}',
            'category': '${r['category']}',
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _satisiYapilmayan(
    Database db,
    StockReportFilter f,
  ) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final where = <String>['sold.product_id IS NULL'];
    final args = <Object?>[from, to];
    _appendCodeNameRange(where, args, f, alias: 'p');

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        0 AS quantity,
        0 AS amount
      FROM products p
      LEFT JOIN (
        SELECT DISTINCT ii.product_id AS product_id
        FROM invoice_items ii
        INNER JOIN invoices i ON i.id = ii.invoice_id
        WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
          AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
          AND LOWER(COALESCE(i.invoice_type, 'sales')) NOT IN
            ('purchase', 'alis', 'return')
      ) sold ON sold.product_id = p.id
      WHERE ${where.join(' AND ')}
      ORDER BY p.code ASC
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'quantity': _num(r['quantity']),
            'amount': _num(r['amount']),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _urunRanking(
    Database db,
    StockReportFilter f, {
    required bool purchase,
  }) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final where = <String>['1=1'];
    final args = <Object?>[];
    _appendCodeNameRange(where, args, f, alias: 'p');

    if (purchase) {
      args.insertAll(0, [from, to]);
      final maps = await db.rawQuery(
        '''
        SELECT
          COALESCE(p.code, '') AS stock_code,
          COALESCE(p.name, '') AS stock_name,
          SUM(COALESCE(oi.quantity, 0)) AS quantity,
          SUM(COALESCE(oi.total_amount, oi.quantity * oi.price, 0)) AS amount
        FROM order_items oi
        INNER JOIN orders o ON o.id = oi.order_id
        LEFT JOIN products p ON p.id = oi.product_id
        WHERE date(COALESCE(o.order_date, o.created_at)) >= date(?)
          AND date(COALESCE(o.order_date, o.created_at)) <= date(?)
          AND LOWER(COALESCE(o.order_type, 'sales')) IN ('purchase', 'alis')
          AND ${where.join(' AND ')}
        GROUP BY p.id, p.code, p.name
        ORDER BY quantity DESC, amount DESC
        ''',
        args,
      );
      return _mapRanking(maps);
    }

    args.insertAll(0, [from, to]);
    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        SUM(COALESCE(ii.quantity, 0)) AS quantity,
        SUM(COALESCE(ii.total_amount, ii.quantity * ii.price, 0)) AS amount
      FROM invoice_items ii
      INNER JOIN invoices i ON i.id = ii.invoice_id
      LEFT JOIN products p ON p.id = ii.product_id
      WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
        AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
        AND LOWER(COALESCE(i.invoice_type, 'sales')) NOT IN
          ('purchase', 'alis', 'return')
        AND ${where.join(' AND ')}
      GROUP BY p.id, p.code, p.name
      ORDER BY quantity DESC, amount DESC
      ''',
      args,
    );
    return _mapRanking(maps);
  }

  List<Map<String, String>> _mapRanking(List<Map<String, Object?>> maps) {
    return maps
        .map(
          (r) => <String, String>{
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'quantity': _num(r['quantity']),
            'amount': _num(r['amount']),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _aracStok(
    Database db,
    StockReportFilter f,
  ) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    _appendCodeNameRange(where, args, f, alias: 'p');
    _appendBalanceFilter(where, args, f, expr: 'COALESCE(vs.quantity, 0)');

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        COALESCE(v.plate, v.name, vs.vehicle_id, '') AS warehouse,
        COALESCE(vs.quantity, 0) AS balance
      FROM vehicle_stocks vs
      LEFT JOIN products p ON p.id = vs.product_id
      LEFT JOIN vehicles v ON v.id = vs.vehicle_id
      WHERE ${where.join(' AND ')}
      ORDER BY warehouse ASC, p.code ASC
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'warehouse': '${r['warehouse']}',
            'balance': _num(r['balance']),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _stokSayim(
    Database db,
    StockReportFilter f,
  ) async {
    final where = <String>['COALESCE(sc.is_deleted, 0) = 0'];
    final args = <Object?>[];
    _appendDateRange(
      where,
      args,
      f,
      expr: 'date(COALESCE(sc.slip_date, sc.created_at))',
    );
    if (f.warehouse.trim().isNotEmpty) {
      where.add('COALESCE(sc.warehouse, "") LIKE ?');
      args.add('%${f.warehouse.trim()}%');
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(sc.slip_date, sc.created_at, '') AS event_date,
        COALESCE(sc.warehouse, '') AS warehouse,
        COALESCE(sc.status, '') AS description,
        COALESCE(sc.id, '') AS stock_code,
        COALESCE(sc.workplace, '') || ' / ' ||
          COALESCE(sc.factory, '') AS stock_name,
        1 AS quantity
      FROM stock_counts sc
      WHERE ${where.join(' AND ')}
      ORDER BY event_date DESC
      ''',
      args,
    );
    return maps
        .map(
          (r) => <String, String>{
            'date': _date(r['event_date']?.toString()),
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'warehouse': '${r['warehouse']}',
            'description': '${r['description']}',
            'quantity': _num(r['quantity']),
            'balance': _num(r['quantity']),
          },
        )
        .toList(growable: false);
  }

  void _appendCodeNameRange(
    List<String> where,
    List<Object?> args,
    StockReportFilter f, {
    required String alias,
  }) {
    if (f.code.trim().isNotEmpty) {
      where.add('COALESCE($alias.code, "") >= ?');
      args.add(f.code.trim());
    }
    if (f.code2.trim().isNotEmpty) {
      where.add('COALESCE($alias.code, "") <= ?');
      args.add(f.code2.trim());
    }
    if (f.name.trim().isNotEmpty) {
      where.add('COALESCE($alias.name, "") LIKE ?');
      args.add('%${f.name.trim()}%');
    }
    if (f.name2.trim().isNotEmpty) {
      where.add('COALESCE($alias.name, "") LIKE ?');
      args.add('%${f.name2.trim()}%');
    }
  }

  void _appendWarehouse(
    List<String> where,
    List<Object?> args,
    StockReportFilter f, {
    required String expr,
  }) {
    final w = f.warehouse.trim();
    if (w.isEmpty || w.toLowerCase() == 'merkez') return;
    where.add('$expr LIKE ?');
    args.add('%$w%');
  }

  void _appendBalanceFilter(
    List<String> where,
    List<Object?> args,
    StockReportFilter f, {
    required String expr,
  }) {
    final parts = <String>[];
    if (f.gtZero) parts.add('$expr > 0');
    if (f.ltZero) parts.add('$expr < 0');
    if (f.eqZero) parts.add('$expr = 0');
    if (parts.isEmpty) return;
    where.add('(${parts.join(' OR ')})');
  }

  void _appendDateRange(
    List<String> where,
    List<Object?> args,
    StockReportFilter f, {
    required String expr,
  }) {
    if (f.dateFrom != null) {
      where.add('$expr >= date(?)');
      args.add(_ymd(f.dateFrom));
    }
    if (f.dateTo != null) {
      where.add('$expr <= date(?)');
      args.add(_ymd(f.dateTo));
    }
  }

  String _ymd(DateTime? d) {
    final v = d ?? DateTime.now();
    final y = v.year.toString().padLeft(4, '0');
    final m = v.month.toString().padLeft(2, '0');
    final day = v.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _num(Object? raw) {
    final n = (raw as num?)?.toDouble() ?? 0;
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  String _date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd.MM.yyyy').format(parsed);
  }
}
