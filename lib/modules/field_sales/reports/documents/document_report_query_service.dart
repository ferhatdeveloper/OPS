// Dosya Adı: document_report_query_service.dart
// Açıklama: SİPARİŞ/FATURA/İRSALİYE MBT satırlarını SQLite → ReportLayout map
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../../orders/viewmodel/order_pending_query.dart';
import 'document_report_filter.dart';
import 'document_report_ids.dart';

/// {@template document_report_query_service}
/// Belge raporları dens PDF satır üretici (columnId → metin).
///
/// Kullanım örneği:
/// ```dart
/// final rows = await DocumentReportQueryService().fetchRows(
///   db: db,
///   reportId: 'satis_siparisleri',
///   filter: const DocumentReportFilter(),
/// );
/// ```
/// {@endtemplate}
class DocumentReportQueryService {
  /// {@macro document_report_query_service}
  const DocumentReportQueryService();

  /// Desteklenen id mi?
  static bool handles(String reportId) => DocumentReportIds.handles(reportId);

  /// {@template document_report_query_service_fetch_rows}
  /// Rapor id’ye göre SQLite → layout satırları.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite
  /// - [reportId]: Katalog id
  /// - [filter]: Parametre filtresi
  ///
  /// Dönüş değeri:
  /// - [List]: columnId → string
  /// {@endtemplate}
  Future<List<Map<String, String>>> fetchRows({
    required Database db,
    required String reportId,
    DocumentReportFilter filter = const DocumentReportFilter(),
  }) async {
    if (!handles(reportId)) return const [];
    await _ensureTables(db);

    final sales = DocumentReportIds.isSalesSide(reportId);
    switch (reportId) {
      case DocumentReportIds.satisSiparisleri:
      case DocumentReportIds.alisSiparisleri:
        return _orders(db, filter, sales: sales, pendingOnly: false);
      case DocumentReportIds.bekleyenSatisSiparis:
      case DocumentReportIds.bekleyenAlisSiparis:
        return _orders(db, filter, sales: sales, pendingOnly: true);
      case DocumentReportIds.satisFaturalari:
      case DocumentReportIds.alisFaturalari:
        return _invoices(db, filter, sales: sales);
      case DocumentReportIds.faturaKarlilik:
        return _invoiceProfitability(db, filter);
      case DocumentReportIds.satisIrsaliyeleri:
      case DocumentReportIds.alisIrsaliyeleri:
        return _waybills(db, filter, sales: sales, uninvoicedOnly: false);
      case DocumentReportIds.faturasizIrsaliyeSatis:
      case DocumentReportIds.faturasizIrsaliyeAlis:
        return _waybills(db, filter, sales: sales, uninvoicedOnly: true);
      default:
        return const [];
    }
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute(SqlQuerys.createProductsTable);
    await db.execute(SqlQuerys.createInvoicesTable);
    await db.execute(SqlQuerys.createInvoiceItemsTable);
    await db.execute(SqlQuerys.createWaybillsTable);
    await db.execute(SqlQuerys.createWaybillItemsTable);
  }

  Future<List<Map<String, String>>> _orders(
    Database db,
    DocumentReportFilter f, {
    required bool sales,
    required bool pendingOnly,
  }) async {
    final range = _dateRange(f);
    final orderType = sales ? 'sales' : 'purchase';
    final where = <String>[
      'date(COALESCE(o.order_date, o.created_at)) >= date(?)',
      'date(COALESCE(o.order_date, o.created_at)) <= date(?)',
      "COALESCE(o.order_type, 'sales') = ?",
      "COALESCE(o.status, '') != 'Cancelled'",
    ];
    final args = <Object?>[...range, orderType];
    _appendCustomerClauses(where, args, f, prefix: 'c');
    _appendStockExists(where, args, f, orderAlias: 'o');

    final sql = '''
      SELECT
        o.id AS doc_no,
        COALESCE(o.order_date, o.created_at) AS event_date,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        COALESCE(o.total_amount, 0) AS amount,
        COALESCE(o.status, '') AS status,
        COALESCE(o.approval_status, 0) AS approval_status
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY o.order_date DESC
    ''';

    final maps = await _safeQuery(db, sql, args);
    final filtered = pendingOnly
        ? maps.where(OrderPendingQuery.isPendingMap).toList(growable: false)
        : maps;
    return filtered.map(_mapBelge).toList(growable: false);
  }

  Future<List<Map<String, String>>> _invoices(
    Database db,
    DocumentReportFilter f, {
    required bool sales,
  }) async {
    final range = _dateRange(f);
    final where = <String>[
      'date(COALESCE(i.invoice_date, i.created_at)) >= date(?)',
      'date(COALESCE(i.invoice_date, i.created_at)) <= date(?)',
      "COALESCE(i.status, '') != 'Cancelled'",
    ];
    final args = <Object?>[...range];
    _appendCustomerClauses(where, args, f, prefix: 'c');

    final sql = '''
      SELECT
        i.id AS doc_no,
        COALESCE(i.invoice_date, i.created_at) AS event_date,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        COALESCE(i.total_amount, 0) AS amount,
        COALESCE(i.status, '') AS status,
        COALESCE(i.invoice_type, 'Sales') AS invoice_type
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY i.invoice_date DESC
    ''';

    final maps = await _safeQuery(db, sql, args);
    return maps
        .where((r) => _invoiceMatchesSide(r['invoice_type']?.toString(), sales))
        .map(_mapBelge)
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _invoiceProfitability(
    Database db,
    DocumentReportFilter f,
  ) async {
    final range = _dateRange(f);
    final where = <String>[
      'date(COALESCE(i.invoice_date, i.created_at)) >= date(?)',
      'date(COALESCE(i.invoice_date, i.created_at)) <= date(?)',
      "COALESCE(i.status, '') != 'Cancelled'",
    ];
    final args = <Object?>[...range];
    _appendCustomerClauses(where, args, f, prefix: 'c');

    final sql = '''
      SELECT
        i.id AS doc_no,
        COALESCE(i.invoice_date, i.created_at) AS event_date,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        COALESCE(i.total_amount, 0) AS amount,
        COALESCE(i.status, '') AS status,
        COALESCE(i.invoice_type, 'Sales') AS invoice_type,
        (
          SELECT COALESCE(SUM(COALESCE(ii.quantity, 0) * COALESCE(ii.price, 0)), 0)
          FROM invoice_items ii
          WHERE ii.invoice_id = i.id
        ) AS line_cost_base
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY i.invoice_date DESC
    ''';

    final maps = await _safeQuery(db, sql, args);
    return maps
        .where((r) => _invoiceMatchesSide(r['invoice_type']?.toString(), true))
        .map((r) {
          final amount = _asDouble(r['amount']);
          final lineBase = _asDouble(r['line_cost_base']);
          // Kalem yoksa tutarın %85’i maliyet vekili → ~%15 brüt kar
          final cost = lineBase > 0 ? lineBase * 0.85 : amount * 0.85;
          final profit = amount - cost;
          return {
            'doc_no': (r['doc_no'] ?? '').toString(),
            'date': _fmtDate(_parseDate(r['event_date'])),
            'code': (r['code'] ?? '').toString(),
            'title': (r['title'] ?? '').toString(),
            'amount': _fmtAmt(amount),
            'profit': _fmtAmt(profit),
            'status': (r['status'] ?? '').toString(),
          };
        })
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _waybills(
    Database db,
    DocumentReportFilter f, {
    required bool sales,
    required bool uninvoicedOnly,
  }) async {
    final range = _dateRange(f);
    final side = sales ? 'waybill_wholesale' : 'waybill_purchase';
    final where = <String>[
      'date(COALESCE(w.waybill_date, w.created_at)) >= date(?)',
      'date(COALESCE(w.waybill_date, w.created_at)) <= date(?)',
      "COALESCE(w.waybill_type, 'waybill_wholesale') = ?",
      "LOWER(COALESCE(w.status, '')) NOT IN ('cancelled', 'iptal')",
    ];
    final args = <Object?>[...range, side];
    _appendCustomerClauses(where, args, f, prefix: 'c');

    if (uninvoicedOnly) {
      final hasInvoiceId = await _waybillHasInvoiceIdColumn(db);
      if (hasInvoiceId) {
        // invoice_id dolu → bağlı fatura; boşsa aynı gün heuristic
        where.add('''
          NOT EXISTS (
            SELECT 1 FROM invoices i
            WHERE COALESCE(i.status, '') != 'Cancelled'
              AND (
                (
                  TRIM(COALESCE(w.invoice_id, '')) != ''
                  AND i.id = w.invoice_id
                )
                OR (
                  TRIM(COALESCE(w.invoice_id, '')) = ''
                  AND i.customer_id = w.customer_id
                  AND date(COALESCE(i.invoice_date, i.created_at)) =
                      date(COALESCE(w.waybill_date, w.created_at))
                )
              )
          )
        ''');
      } else {
        // Heuristik: aynı cari + aynı gün fatura yoksa faturasız say
        // (waybills.invoice_id kolonu yokken geriye dönük uyumluluk)
        where.add('''
          NOT EXISTS (
            SELECT 1 FROM invoices i
            WHERE i.customer_id = w.customer_id
              AND date(COALESCE(i.invoice_date, i.created_at)) =
                  date(COALESCE(w.waybill_date, w.created_at))
              AND COALESCE(i.status, '') != 'Cancelled'
          )
        ''');
      }
      where.add('''
        LOWER(COALESCE(w.status, '')) NOT IN
          ('invoiced', 'fatura_kesildi', 'faturakesildi')
      ''');
    }

    final sql = '''
      SELECT
        w.id AS doc_no,
        COALESCE(w.waybill_date, w.created_at) AS event_date,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        COALESCE(w.total_amount, 0) AS amount,
        COALESCE(w.status, '') AS status
      FROM waybills w
      LEFT JOIN customers c ON c.id = w.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY w.waybill_date DESC
    ''';

    final maps = await _safeQuery(db, sql, args);
    return maps.map(_mapBelge).toList(growable: false);
  }

  /// waybills tablosunda `invoice_id` kolonu var mı (PRAGMA).
  Future<bool> _waybillHasInvoiceIdColumn(Database db) async {
    try {
      final cols = await db.rawQuery('PRAGMA table_info(waybills)');
      for (final c in cols) {
        if ((c['name'] ?? '').toString().toLowerCase() == 'invoice_id') {
          return true;
        }
      }
    } catch (_) {
      // tablo yok / pragma hata → heuristic
    }
    return false;
  }

  Map<String, String> _mapBelge(Map<String, Object?> r) {
    return {
      'doc_no': (r['doc_no'] ?? '').toString(),
      'date': _fmtDate(_parseDate(r['event_date'])),
      'code': (r['code'] ?? '').toString(),
      'title': (r['title'] ?? '').toString(),
      'amount': _fmtAmt(_asDouble(r['amount'])),
      'status': (r['status'] ?? '').toString(),
      'salesperson': '',
      'voucher_type': (r['invoice_type'] ?? r['approval_status'] ?? '').toString(),
    };
  }

  bool _invoiceMatchesSide(String? invoiceType, bool sales) {
    final q = LogoPayloadMapper.resolveInvoiceQueueType(invoiceType);
    final isPurchase = q == LogoPayloadMapper.invoiceQueuePurchase;
    return sales ? !isPurchase : isPurchase;
  }

  void _appendCustomerClauses(
    List<String> where,
    List<Object?> args,
    DocumentReportFilter f, {
    required String prefix,
  }) {
    final code = f.cariCode.trim().isNotEmpty ? f.cariCode.trim() : f.code.trim();
    final name = f.cariName.trim().isNotEmpty ? f.cariName.trim() : f.name.trim();
    if (code.isNotEmpty) {
      where.add("$prefix.code LIKE ? ESCAPE '\\'");
      args.add('%${_like(code)}%');
    }
    if (name.isNotEmpty) {
      where.add("$prefix.name LIKE ? ESCAPE '\\'");
      args.add('%${_like(name)}%');
    }
  }

  void _appendStockExists(
    List<String> where,
    List<Object?> args,
    DocumentReportFilter f, {
    required String orderAlias,
  }) {
    final sc = f.stockCode.trim();
    final sn = f.stockName.trim();
    if (sc.isEmpty && sn.isEmpty) return;
    final stockWhere = <String>['oi.order_id = $orderAlias.id'];
    if (sc.isNotEmpty) {
      stockWhere.add(
        "(COALESCE(p.code, oi.product_id, '') LIKE ? ESCAPE '\\')",
      );
      args.add('%${_like(sc)}%');
    }
    if (sn.isNotEmpty) {
      stockWhere.add("COALESCE(p.name, '') LIKE ? ESCAPE '\\'");
      args.add('%${_like(sn)}%');
    }
    where.add('''
      EXISTS (
        SELECT 1 FROM order_items oi
        LEFT JOIN products p ON p.id = oi.product_id
        WHERE ${stockWhere.join(' AND ')}
      )
    ''');
  }

  List<String> _dateRange(DocumentReportFilter f) {
    final from = f.dateFrom ?? DateTime(2000, 1, 1);
    final to = f.dateTo ?? DateTime.now();
    return [_toDateOnly(from), _toDateOnly(to)];
  }

  Future<List<Map<String, Object?>>> _safeQuery(
    Database db,
    String sql, [
    List<Object?> args = const [],
  ]) async {
    try {
      return await db.rawQuery(sql, args);
    } catch (_) {
      return const [];
    }
  }

  String _like(String raw) =>
      raw.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');

  String _toDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _fmtAmt(double v) => v.toStringAsFixed(2);
}
