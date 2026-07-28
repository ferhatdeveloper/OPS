// Dosya Adı: mbt_report_data_service.dart
// Açıklama: MBT rapor satırlarını SQLite’tan layout columnId map olarak okur
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import '../cari/cari_report_filter.dart';
import '../cari/cari_report_ids.dart';
import '../cari/cari_report_query_service.dart';
import '../documents/document_report_filter.dart';
import '../documents/document_report_ids.dart';
import '../documents/document_report_query_service.dart';
import '../other/model/other_report_scope.dart';
import '../other/viewmodel/other_report_query_service.dart';
import '../stock/stock_report_filter.dart';
import '../stock/stock_report_query_service.dart';
import 'mbt_report_action_service.dart';

/// {@template mbt_report_db_resolver}
/// Test inject için DB çözümleyici.
/// {@endtemplate}
typedef MbtReportDbResolver = Future<Database> Function();

/// {@template mbt_report_data_service}
/// Parametreler → Görüntüle için gerçek SQLite satırları.
/// Tablo yoksa / sorgu hata verirse boş liste (crash yok).
///
/// Kullanım örneği:
/// ```dart
/// final rows = await MbtReportDataService().fetchRows(
///   reportId: 'tahsilat_listesi',
///   snapshot: snapshot,
/// );
/// ```
/// {@endtemplate}
class MbtReportDataService {
  /// [_resolveDb]: DB inject (test)
  final MbtReportDbResolver? _resolveDb;

  /// {@macro mbt_report_data_service}
  const MbtReportDataService({MbtReportDbResolver? resolveDb})
      : _resolveDb = resolveDb;

  Future<Database> _db() async {
    final custom = _resolveDb;
    if (custom != null) return custom();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template mbt_report_data_service_fetch_rows}
  /// Rapor id + parametre snapshot → layout sütun map satırları.
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  /// - [snapshot]: Parametreler
  /// - [db]: Opsiyonel açık DB
  ///
  /// Dönüş değeri:
  /// - [List]: columnId → değer
  /// {@endtemplate}
  Future<List<Map<String, String>>> fetchRows({
    required String reportId,
    required MbtReportParamSnapshot snapshot,
    Database? db,
    DocumentReportFilter? documentFilter,
  }) async {
    try {
      final database = db ?? await _db();
      return await _dispatch(
        database,
        reportId,
        snapshot,
        documentFilter: documentFilter,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, String>>> _dispatch(
    Database db,
    String reportId,
    MbtReportParamSnapshot snapshot, {
    DocumentReportFilter? documentFilter,
  }) async {
    if (OtherReportScope.owns(reportId)) {
      return OtherReportQueryService.fetchRows(
        db: db,
        reportId: reportId,
        snapshot: snapshot,
      );
    }
    if (CariReportIds.handles(reportId)) {
      return const CariReportQueryService().fetchRows(
        db: db,
        reportId: reportId,
        filter: CariReportFilter(
          dateFrom: snapshot.dateFrom,
          dateTo: snapshot.dateTo,
          code: snapshot.code,
          name: snapshot.name,
          code2: snapshot.code2,
          name2: snapshot.name2,
        ),
      );
    }
    if (DocumentReportIds.handles(reportId)) {
      return DocumentReportQueryService().fetchRows(
        db: db,
        reportId: reportId,
        filter: documentFilter ??
            DocumentReportFilter.fromSnapshot(snapshot),
      );
    }
    if (StockReportQueryService.handles(reportId)) {
      return const StockReportQueryService().fetchRows(
        db: db,
        reportId: reportId,
        filter: StockReportFilter.fromSnapshot(snapshot),
      );
    }
    // OPS / kalan id’ler (cari/stok/belge/other dışı)
    switch (reportId) {
      case 'ops_collection_report':
        return _tahsilat(db, snapshot);
      case 'ops_sales_report':
        return _faturalar(db, snapshot, sales: true);
      case 'ops_visit_report':
        return _ziyaret(db, snapshot);
      case 'ops_performance':
      case 'ops_gun_sonu':
      case 'ops_advanced':
        return _ozet(db, snapshot);
      case 'ops_target':
        return _hedef(db, snapshot);
      default:
        return const [];
    }
  }

  String _d(DateTime? d) {
    if (d == null) return '1970-01-01';
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd.MM.yyyy').format(d);
  }

  String _money(Object? v) {
    final n = (v as num?)?.toDouble() ?? 0;
    return n.toStringAsFixed(2);
  }

  Future<List<Map<String, dynamic>>> _safe(
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

  Future<List<Map<String, String>>> _cariHareket(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final code = s.code.trim();
    final maps = await _safe(
      db,
      '''
      SELECT i.invoice_date AS d, i.total_amount AS amt, i.status AS st,
             COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name,
             'Fatura' AS kind
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE date(i.invoice_date) BETWEEN date(?) AND date(?)
        AND (? = '' OR c.code LIKE ? OR c.name LIKE ?)
      UNION ALL
      SELECT col.collection_date, col.amount, col.payment_type,
             COALESCE(c.code,''), COALESCE(c.name,''), 'Tahsilat'
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(col.collection_date) BETWEEN date(?) AND date(?)
        AND (? = '' OR c.code LIKE ? OR c.name LIKE ?)
      ORDER BY 1 ASC
      LIMIT 500
      ''',
      [
        from,
        to,
        code,
        '%$code%',
        '%${s.name}%',
        from,
        to,
        code,
        '%$code%',
        '%${s.name}%',
      ],
    );
    var bal = 0.0;
    return maps.map((r) {
      final amt = (r['amt'] as num?)?.toDouble() ?? 0;
      final kind = (r['kind'] ?? '').toString();
      final debit = kind == 'Fatura' ? amt : 0.0;
      final credit = kind == 'Tahsilat' ? amt : 0.0;
      bal += debit - credit;
      final dateRaw = r['d']?.toString();
      final parsed = dateRaw == null ? null : DateTime.tryParse(dateRaw);
      return {
        'ref_no_date': _fmt(parsed),
        'description':
            '${r['kind']} · ${r['code']} ${r['name']}'.trim(),
        'debit': _money(debit),
        'credit': _money(credit),
        'balance': _money(bal),
      };
    }).toList();
  }

  Future<List<Map<String, String>>> _tahsilat(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final to = _d(s.dateTo ?? DateTime.now());
    final code = s.code.trim();
    final maps = await _safe(
      db,
      '''
      SELECT col.collection_date, col.due_date, col.amount, col.payment_type,
             COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(col.collection_date) <= date(?)
        AND (? = '' OR c.code LIKE ? OR c.name LIKE ?)
      ORDER BY col.collection_date DESC
      LIMIT 500
      ''',
      [to, code, '%$code%', '%${s.name}%'],
    );
    return maps.map((r) {
      final txn = DateTime.tryParse(r['collection_date']?.toString() ?? '');
      final due = DateTime.tryParse(r['due_date']?.toString() ?? '');
      var dayDiff = '';
      if (txn != null && due != null) {
        dayDiff = due.difference(txn).inDays.toString();
      }
      return {
        'code': (r['code'] ?? '').toString(),
        'title': (r['name'] ?? '').toString(),
        'txn_date': _fmt(txn),
        'due_date': _fmt(due),
        'txn_type': (r['payment_type'] ?? '').toString(),
        'amount': _money(r['amount']),
        'remaining': _money(r['amount']),
        'day_diff': dayDiff,
      };
    }).toList();
  }

  Future<List<Map<String, String>>> _borcAlacak(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final code = s.code.trim();
    final maps = await _safe(
      db,
      '''
      SELECT code, name, balance FROM customers
      WHERE is_active = 1
        AND (? = '' OR code LIKE ? OR name LIKE ?)
      ORDER BY ABS(balance) DESC
      LIMIT 500
      ''',
      [code, '%$code%', '%${s.name}%'],
    );
    return maps
        .map(
          (r) => {
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'amount': _money(r['balance']),
            'balance': _money(r['balance']),
            'status': ((r['balance'] as num?) ?? 0) >= 0 ? 'Borç' : 'Alacak',
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _enCokCari(
    Database db,
    MbtReportParamSnapshot s, {
    required bool sales,
  }) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name,
             SUM(i.total_amount) AS total
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE date(i.invoice_date) BETWEEN date(?) AND date(?)
      GROUP BY c.id
      ORDER BY total DESC
      LIMIT 100
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'amount': _money(r['total']),
            'quantity': '',
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _satisYapilmayanCari(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT c.code, c.name, c.balance FROM customers c
      WHERE c.is_active = 1
        AND NOT EXISTS (
          SELECT 1 FROM invoices i
          WHERE i.customer_id = c.id
            AND date(i.invoice_date) BETWEEN date(?) AND date(?)
        )
      ORDER BY c.name
      LIMIT 500
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'amount': _money(r['balance']),
            'status': 'Hareketsiz',
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _cekSenet(
    Database db,
    MbtReportParamSnapshot s, {
    required bool checkLike,
  }) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final like = checkLike ? '%Check%' : '%Senet%';
    final maps = await _safe(
      db,
      '''
      SELECT col.collection_date, col.due_date, col.amount, col.payment_type,
             col.check_number, COALESCE(c.code,'') AS code,
             COALESCE(c.name,'') AS name
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(col.collection_date) BETWEEN date(?) AND date(?)
        AND (col.payment_type LIKE ? OR IFNULL(col.notes,'') LIKE ?)
      ORDER BY col.collection_date DESC
      LIMIT 500
      ''',
      [from, to, like, like],
    );
    return maps
        .map(
          (r) => {
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'doc_no': (r['check_number'] ?? '').toString(),
            'date': _fmt(DateTime.tryParse(r['collection_date']?.toString() ?? '')),
            'due_date':
                _fmt(DateTime.tryParse(r['due_date']?.toString() ?? '')),
            'amount': _money(r['amount']),
            'status': (r['payment_type'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _stokBakiye(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final code = s.code.trim();
    final maps = await _safe(
      db,
      '''
      SELECT p.code AS stock_code, p.name AS stock_name,
             COALESCE(SUM(ws.quantity), p.stock_quantity, 0) AS bal
      FROM products p
      LEFT JOIN warehouse_stocks ws ON ws.product_id = p.id
      WHERE (? = '' OR p.code LIKE ? OR p.name LIKE ?)
      GROUP BY p.id
      ORDER BY p.code
      LIMIT 500
      ''',
      [code, '%$code%', '%${s.name}%'],
    );
    return maps
        .map(
          (r) => {
            'stock_code': (r['stock_code'] ?? '').toString(),
            'stock_name': (r['stock_name'] ?? '').toString(),
            'balance': _money(r['bal']),
            'quantity': _money(r['bal']),
            'warehouse': '',
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _urunDepo(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final code = s.code.trim();
    final maps = await _safe(
      db,
      '''
      SELECT p.code AS stock_code, p.name AS stock_name,
             ws.warehouse_code AS warehouse, ws.quantity AS bal
      FROM warehouse_stocks ws
      JOIN products p ON p.id = ws.product_id
      WHERE (? = '' OR p.code LIKE ? OR p.name LIKE ?)
      ORDER BY p.code, ws.warehouse_code
      LIMIT 500
      ''',
      [code, '%$code%', '%${s.name}%'],
    );
    return maps
        .map(
          (r) => {
            'stock_code': (r['stock_code'] ?? '').toString(),
            'stock_name': (r['stock_name'] ?? '').toString(),
            'warehouse': (r['warehouse'] ?? '').toString(),
            'balance': _money(r['bal']),
            'quantity': _money(r['bal']),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _seriLot(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final maps = await _safe(
      db,
      '''
      SELECT product_code, product_name, lot_no, quantity, warehouse_code, status
      FROM batch_expiry
      ORDER BY expiry_date
      LIMIT 500
      ''',
    );
    return maps
        .map(
          (r) => {
            'stock_code': (r['product_code'] ?? '').toString(),
            'stock_name': (r['product_name'] ?? '').toString(),
            'serial': (r['lot_no'] ?? '').toString(),
            'quantity': _money(r['quantity']),
            'warehouse': (r['warehouse_code'] ?? '').toString(),
            'status': (r['status'] ?? '').toString(),
            'balance': _money(r['quantity']),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _enCokUrun(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT COALESCE(p.code,'') AS stock_code,
             COALESCE(p.name,'') AS stock_name,
             SUM(oi.quantity) AS qty,
             SUM(oi.quantity * oi.price) AS total
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      LEFT JOIN products p ON p.id = oi.product_id
      WHERE date(o.order_date) BETWEEN date(?) AND date(?)
      GROUP BY oi.product_id
      ORDER BY total DESC
      LIMIT 100
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'stock_code': (r['stock_code'] ?? '').toString(),
            'stock_name': (r['stock_name'] ?? '').toString(),
            'quantity': _money(r['qty']),
            'amount': _money(r['total']),
            'balance': _money(r['qty']),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _satisiYapilmayanUrun(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT p.code AS stock_code, p.name AS stock_name, p.stock_quantity AS bal
      FROM products p
      WHERE NOT EXISTS (
        SELECT 1 FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE oi.product_id = p.id
          AND date(o.order_date) BETWEEN date(?) AND date(?)
      )
      ORDER BY p.code
      LIMIT 500
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'stock_code': (r['stock_code'] ?? '').toString(),
            'stock_name': (r['stock_name'] ?? '').toString(),
            'balance': _money(r['bal']),
            'quantity': _money(r['bal']),
            'status': 'Hareketsiz',
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _stokHareket(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT wt.transfer_date, wt.from_warehouse, wt.to_warehouse,
             wt.quantity, wt.status, COALESCE(p.code,'') AS stock_code,
             COALESCE(p.name,'') AS stock_name
      FROM warehouse_transfers wt
      LEFT JOIN products p ON p.id = wt.product_id
      WHERE date(wt.transfer_date) BETWEEN date(?) AND date(?)
      ORDER BY wt.transfer_date DESC
      LIMIT 500
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'date': _fmt(DateTime.tryParse(r['transfer_date']?.toString() ?? '')),
            'stock_code': (r['stock_code'] ?? '').toString(),
            'stock_name': (r['stock_name'] ?? '').toString(),
            'warehouse':
                '${r['from_warehouse']}→${r['to_warehouse']}',
            'quantity': _money(r['quantity']),
            'status': (r['status'] ?? '').toString(),
            'doc_no': '',
            'code': (r['stock_code'] ?? '').toString(),
            'title': (r['stock_name'] ?? '').toString(),
            'amount': _money(r['quantity']),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _siparis(
    Database db,
    MbtReportParamSnapshot s, {
    required String type,
    required bool pendingOnly,
  }) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT o.id, o.order_date, o.total_amount, o.status, o.order_type,
             COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE date(o.order_date) BETWEEN date(?) AND date(?)
        AND (LOWER(IFNULL(o.order_type,'sales')) LIKE ?)
        AND (? = 0 OR LOWER(IFNULL(o.status,'')) LIKE '%pend%')
      ORDER BY o.order_date DESC
      LIMIT 500
      ''',
      [
        from,
        to,
        type == 'purchase' ? '%purch%' : '%sale%',
        pendingOnly ? 1 : 0,
      ],
    );
    return maps
        .map(
          (r) => {
            'doc_no': (r['id'] ?? '').toString(),
            'date': _fmt(DateTime.tryParse(r['order_date']?.toString() ?? '')),
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'amount': _money(r['total_amount']),
            'status': (r['status'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _faturalar(
    Database db,
    MbtReportParamSnapshot s, {
    required bool sales,
  }) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT i.id, i.invoice_date, i.total_amount, i.status, i.invoice_type,
             COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE date(i.invoice_date) BETWEEN date(?) AND date(?)
      ORDER BY i.invoice_date DESC
      LIMIT 500
      ''',
      [from, to],
    );
    return maps
        .where((r) {
          final t = (r['invoice_type'] ?? '').toString().toLowerCase();
          final isPurchase =
              t.contains('purch') || t.contains('alis') || t == 'alış';
          return sales ? !isPurchase : isPurchase;
        })
        .map(
          (r) => {
            'doc_no': (r['id'] ?? '').toString(),
            'date':
                _fmt(DateTime.tryParse(r['invoice_date']?.toString() ?? '')),
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'amount': _money(r['total_amount']),
            'profit': _money(
              ((r['total_amount'] as num?)?.toDouble() ?? 0) * 0.1,
            ),
            'status': (r['status'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _irsaliye(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT w.id, w.waybill_date, w.total_amount, w.status,
             COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name
      FROM waybills w
      LEFT JOIN customers c ON c.id = w.customer_id
      WHERE date(w.waybill_date) BETWEEN date(?) AND date(?)
      ORDER BY w.waybill_date DESC
      LIMIT 500
      ''',
      [from, to],
    );
    if (maps.isEmpty) {
      // fallback: invoices as proxy
      return _faturalar(db, s, sales: true);
    }
    return maps
        .map(
          (r) => {
            'doc_no': (r['id'] ?? '').toString(),
            'date':
                _fmt(DateTime.tryParse(r['waybill_date']?.toString() ?? '')),
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'amount': _money(r['total_amount']),
            'status': (r['status'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _ziyaret(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT v.check_in_at, v.duration_minutes, v.status, v.user_id,
             COALESCE(c.code,'') AS code, COALESCE(c.name,'') AS name
      FROM visits v
      LEFT JOIN customers c ON c.id = v.customer_id
      WHERE date(v.check_in_at) BETWEEN date(?) AND date(?)
      ORDER BY v.check_in_at DESC
      LIMIT 500
      ''',
      [from, to],
    );
    return maps.map((r) {
      final dt = DateTime.tryParse(r['check_in_at']?.toString() ?? '');
      return {
        'date': _fmt(dt),
        'visit_time': dt == null
            ? ''
            : DateFormat('HH:mm').format(dt),
        'code': (r['code'] ?? '').toString(),
        'title': (r['name'] ?? '').toString(),
        'salesperson': (r['user_id'] ?? '').toString(),
        'status': (r['status'] ?? '').toString(),
        'amount': '${r['duration_minutes'] ?? 0}',
      };
    }).toList();
  }

  Future<List<Map<String, String>>> _gps(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final maps = await _safe(
      db,
      '''
      SELECT code, name, latitude, longitude FROM customers
      WHERE latitude IS NOT NULL AND longitude IS NOT NULL
      ORDER BY name
      LIMIT 500
      ''',
    );
    return maps
        .map(
          (r) => {
            'code': (r['code'] ?? '').toString(),
            'title': (r['name'] ?? '').toString(),
            'lat': (r['latitude'] ?? '').toString(),
            'lng': (r['longitude'] ?? '').toString(),
            'distance': '',
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _kasa(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT col.collection_date, col.document_no, col.amount, col.payment_type,
             col.cash_code, COALESCE(c.name,'') AS name
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(col.collection_date) BETWEEN date(?) AND date(?)
        AND (LOWER(IFNULL(col.payment_type,'')) LIKE '%cash%'
             OR IFNULL(col.cash_code,'') != '')
      ORDER BY col.collection_date DESC
      LIMIT 500
      ''',
      [from, to],
    );
    var bal = 0.0;
    return maps.map((r) {
      final amt = (r['amount'] as num?)?.toDouble() ?? 0;
      bal += amt;
      return {
        'date':
            _fmt(DateTime.tryParse(r['collection_date']?.toString() ?? '')),
        'doc_no': (r['document_no'] ?? '').toString(),
        'description':
            '${r['cash_code']} · ${r['name']} · ${r['payment_type']}',
        'debit': '0.00',
        'credit': _money(amt),
        'balance': _money(bal),
        'amount': _money(amt),
      };
    }).toList();
  }

  Future<List<Map<String, String>>> _banka(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    final maps = await _safe(
      db,
      '''
      SELECT deposit_date, bank_code, amount, document_no, cash_code, status
      FROM bank_deposits
      WHERE date(deposit_date) BETWEEN date(?) AND date(?)
        AND IFNULL(is_deleted,0) = 0
      ORDER BY deposit_date DESC
      LIMIT 500
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'date':
                _fmt(DateTime.tryParse(r['deposit_date']?.toString() ?? '')),
            'code': (r['bank_code'] ?? '').toString(),
            'title': (r['cash_code'] ?? '').toString(),
            'doc_no': (r['document_no'] ?? '').toString(),
            'amount': _money(r['amount']),
            'status': (r['status'] ?? '').toString(),
            'description': (r['bank_code'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<List<Map<String, String>>> _ozet(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final from = _d(s.dateFrom);
    final to = _d(s.dateTo ?? s.dateFrom);
    Future<double> sum(String sql) async {
      final rows = await _safe(db, sql, [from, to]);
      if (rows.isEmpty) return 0;
      return (rows.first.values.first as num?)?.toDouble() ?? 0;
    }

    final sales = await sum(
      'SELECT COALESCE(SUM(total_amount),0) FROM invoices WHERE date(invoice_date) BETWEEN date(?) AND date(?)',
    );
    final collections = await sum(
      'SELECT COALESCE(SUM(amount),0) FROM collections WHERE date(collection_date) BETWEEN date(?) AND date(?)',
    );
    final orders = await sum(
      'SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE date(order_date) BETWEEN date(?) AND date(?)',
    );
    final visits = await sum(
      'SELECT COALESCE(COUNT(*),0) FROM visits WHERE date(check_in_at) BETWEEN date(?) AND date(?)',
    );
    // Layout `_generic`: code · title · date · amount
    final period = '$from – $to';
    return [
      {
        'code': 'SATIS',
        'title': 'Satış (fatura)',
        'date': period,
        'amount': _money(sales),
        'description': 'Satış (fatura)',
        'col_current': _money(sales),
      },
      {
        'code': 'TAHSILAT',
        'title': 'Tahsilat',
        'date': period,
        'amount': _money(collections),
        'description': 'Tahsilat',
        'col_current': _money(collections),
      },
      {
        'code': 'SIPARIS',
        'title': 'Sipariş',
        'date': period,
        'amount': _money(orders),
        'description': 'Sipariş',
        'col_current': _money(orders),
      },
      {
        'code': 'ZIYARET',
        'title': 'Ziyaret adedi',
        'date': period,
        'amount': visits.toStringAsFixed(0),
        'description': 'Ziyaret adedi',
        'col_current': visits.toStringAsFixed(0),
      },
      {
        'code': 'FARK',
        'title': 'Fark (satış−tahsilat)',
        'date': period,
        'amount': _money(sales - collections),
        'description': 'Fark (satış−tahsilat)',
        'col_diff': _money(sales - collections),
      },
    ];
  }

  /// Hedef özeti — `targets` tablo satırları (hedef / gerçekleşen / %).
  Future<List<Map<String, String>>> _hedef(
    Database db,
    MbtReportParamSnapshot s,
  ) async {
    final code = s.code.trim();
    final maps = await _safe(
      db,
      '''
      SELECT
        COALESCE(user_id, '') AS user_id,
        COALESCE(period, '') AS period,
        COALESCE(type, 'Sales') AS type,
        COALESCE(target_amount, 0) AS target_amount,
        COALESCE(achieved_amount, 0) AS achieved_amount,
        CASE
          WHEN COALESCE(target_amount, 0) > 0
          THEN (COALESCE(achieved_amount, 0) * 100.0 / target_amount)
          ELSE 0
        END AS pct
      FROM targets
      WHERE (? = '' OR COALESCE(user_id, '') LIKE '%' || ? || '%'
            OR COALESCE(type, '') LIKE '%' || ? || '%'
            OR COALESCE(period, '') LIKE '%' || ? || '%')
      ORDER BY period DESC, type ASC, user_id ASC
      ''',
      [code, code, code, code],
    );
    return maps
        .map(
          (r) => {
            'code': (r['type'] ?? '').toString(),
            'title': (r['user_id'] ?? '').toString(),
            'salesperson': (r['user_id'] ?? '').toString(),
            'period': (r['period'] ?? '').toString(),
            'date': (r['period'] ?? '').toString(),
            'target': _money(r['target_amount']),
            'achieved': _money(r['achieved_amount']),
            'percent': _money(r['pct']),
            'amount': _money(r['achieved_amount']),
            'status': _money(r['pct']),
          },
        )
        .toList();
  }
}
