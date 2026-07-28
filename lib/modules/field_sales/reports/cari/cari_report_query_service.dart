// Dosya Adı: cari_report_query_service.dart
// Açıklama: 14+ CARİ MBT rapor satırlarını SQLite → ReportLayout sütun map
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/geo/haversine.dart';
import 'cari_report_filter.dart';
import 'cari_report_ids.dart';

/// {@template cari_report_query_service}
/// CARİ raporları için dens liste / PDF satır üretici (columnId → metin).
///
/// Kullanım örneği:
/// ```dart
/// final rows = await CariReportQueryService().fetchRows(
///   db: db,
///   reportId: 'cari_extre',
///   filter: const CariReportFilter(code: 'C1'),
/// );
/// ```
/// {@endtemplate}
class CariReportQueryService {
  /// {@macro cari_report_query_service}
  const CariReportQueryService();

  /// {@template cari_report_query_service_handles}
  /// Rapor id destekleniyor mu?
  /// {@endtemplate}
  static bool handles(String reportId) => CariReportIds.handles(reportId);

  /// {@template cari_report_query_service_fetch_rows}
  /// Rapor id’ye göre SQLite satırlarını layout map listesine çevirir.
  /// {@endtemplate}
  Future<List<Map<String, String>>> fetchRows({
    required Database db,
    required String reportId,
    CariReportFilter filter = const CariReportFilter(),
  }) async {
    await _ensureTables(db);
    switch (reportId) {
      case CariReportIds.cariExtre:
        return _cariExtre(db, filter, detailed: false);
      case CariReportIds.detayliCariExtre:
        return _cariExtre(db, filter, detailed: true);
      case CariReportIds.cariHareket:
        return _cariHareket(db, filter);
      case CariReportIds.tahsilatListesi:
        return _tahsilat(db, filter);
      case CariReportIds.borcAlacak:
        return _borcAlacak(db, filter, nonzeroOnly: false);
      case CariReportIds.cariRisk:
        return _cariRisk(db, filter);
      case CariReportIds.yakinimdakiCariGps:
        return _gpsCustomers(db, filter, sortByDistance: true);
      case CariReportIds.gpsKonum:
        return _gpsCustomers(db, filter, sortByDistance: false);
      case CariReportIds.satisYapilmayanCari:
        return _satisYapilmayan(db, filter);
      case CariReportIds.enCokSatisCari:
        return _enCokCari(db, filter, sales: true);
      case CariReportIds.enCokAlimCari:
        return _enCokCari(db, filter, sales: false);
      case CariReportIds.enCokUrunSatis:
        return _enCokUrun(db, filter, sales: true);
      case CariReportIds.enCokUrunAlis:
        return _enCokUrun(db, filter, sales: false);
      case CariReportIds.musteriCek:
        return _cekSenet(db, filter, checksOnly: true);
      case CariReportIds.musteriSenet:
        return _cekSenet(db, filter, checksOnly: false);
      default:
        return const [];
    }
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createInvoicesTable);
    await db.execute(SqlQuerys.createInvoiceItemsTable);
    await db.execute(SqlQuerys.createCollectionsTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute(SqlQuerys.createProductsTable);
  }

  Future<List<Map<String, String>>> _cariExtre(
    Database db,
    CariReportFilter f, {
    required bool detailed,
  }) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final whereC = <String>['1=1'];
    final argsC = <Object?>[];
    _appendCustomer(whereC, argsC, f, alias: 'c');

    final inv = await db.rawQuery(
      '''
      SELECT
        i.id AS row_id,
        COALESCE(i.invoice_date, i.created_at) AS event_date,
        COALESCE(i.total_amount, 0) AS amount,
        COALESCE(i.invoice_type, 'Sales') AS voucher_type,
        COALESCE(i.notes, '') AS description,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, '') AS customer_name
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
        AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
        AND COALESCE(i.status, '') != 'Cancelled'
        AND ${whereC.join(' AND ')}
      ''',
      [from, to, ...argsC],
    );

    final col = await db.rawQuery(
      '''
      SELECT
        col.id AS row_id,
        COALESCE(col.collection_date, col.created_at) AS event_date,
        COALESCE(col.amount, 0) AS amount,
        COALESCE(col.payment_type, 'Cash') AS voucher_type,
        COALESCE(col.notes, col.document_no, '') AS description,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, '') AS customer_name
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
        AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
        AND COALESCE(col.status, '') != 'Cancelled'
        AND ${whereC.join(' AND ')}
      ''',
      [from, to, ...argsC],
    );

    final events = <_CariEvt>[];
    for (final r in inv) {
      events.add(
        _CariEvt(
          date: _parse(r['event_date']) ?? DateTime(1970),
          ref: '${r['row_id']}',
          description: '${r['description']}'.isEmpty
              ? 'Fatura'
              : '${r['description']}',
          debit: _asD(r['amount']),
          credit: 0,
          voucher: '${r['voucher_type']}',
          code: '${r['customer_code']}',
          title: '${r['customer_name']}',
        ),
      );
    }
    for (final r in col) {
      events.add(
        _CariEvt(
          date: _parse(r['event_date']) ?? DateTime(1970),
          ref: '${r['row_id']}',
          description: '${r['description']}'.isEmpty
              ? 'Tahsilat'
              : '${r['description']}',
          debit: 0,
          credit: _asD(r['amount']),
          voucher: '${r['voucher_type']}',
          code: '${r['customer_code']}',
          title: '${r['customer_name']}',
        ),
      );
    }
    events.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.ref.compareTo(b.ref);
    });

    var balance = 0.0;
    final out = <Map<String, String>>[];
    for (final e in events) {
      balance += e.debit - e.credit;
      final refDate = '${e.ref} ${_fmtDate(e.date)}'.trim();
      if (detailed) {
        out.add({
          'ref_no_date': refDate,
          'voucher_type': e.voucher,
          'description': e.description,
          'currency': 'TRY',
          'debit': _amt(e.debit),
          'credit': _amt(e.credit),
          'balance': _amt(balance),
          'code': e.code,
          'title': e.title,
        });
      } else {
        out.add({
          'ref_no_date': refDate,
          'description': e.description,
          'debit': _amt(e.debit),
          'credit': _amt(e.credit),
          'balance': _amt(balance),
          'code': e.code,
          'title': e.title,
          'voucher_type': e.voucher,
          'currency': 'TRY',
        });
      }
    }
    return out;
  }

  Future<List<Map<String, String>>> _cariHareket(
    Database db,
    CariReportFilter f,
  ) async {
    final extre = await _cariExtre(db, f, detailed: true);
    return extre
        .map(
          (r) => {
            'date': (r['ref_no_date'] ?? '').split(' ').last,
            'code': r['code'] ?? '',
            'title': r['title'] ?? '',
            'description': r['description'] ?? '',
            'debit': r['debit'] ?? '',
            'credit': r['credit'] ?? '',
            'balance': r['balance'] ?? '',
            'voucher_type': r['voucher_type'] ?? '',
            'currency': r['currency'] ?? '',
            'ref_no_date': r['ref_no_date'] ?? '',
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _tahsilat(
    Database db,
    CariReportFilter f,
  ) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final where = <String>['1=1'];
    final args = <Object?>[from, to];
    _appendCustomer(where, args, f, alias: 'c');

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        COALESCE(col.collection_date, col.created_at) AS txn_date,
        col.due_date AS due_date,
        COALESCE(col.payment_type, '') AS txn_type,
        COALESCE(col.amount, 0) AS amount,
        COALESCE(col.amount, 0) AS remaining,
        COALESCE(col.document_no, col.id, '') AS doc_no,
        COALESCE(col.status, '') AS status
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
        AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
        AND COALESCE(col.status, '') != 'Cancelled'
        AND ${where.join(' AND ')}
      ORDER BY col.collection_date DESC
      ''',
      args,
    );
    final today = DateTime.now();
    return maps.map((r) {
      final due = _parse(r['due_date']);
      final dayDiff = due != null ? due.difference(today).inDays : 0;
      return {
        'code': '${r['code']}',
        'title': '${r['title']}',
        'txn_date': _fmtDate(_parse(r['txn_date'])),
        'due_date': _fmtDate(due),
        'txn_type': '${r['txn_type']}',
        'amount': _amt(_asD(r['amount'])),
        'remaining': _amt(_asD(r['remaining'])),
        'day_diff': '$dayDiff',
        'doc_no': '${r['doc_no']}',
        'status': '${r['status']}',
      };
    }).toList(growable: false);
  }

  Future<List<Map<String, String>>> _borcAlacak(
    Database db,
    CariReportFilter f, {
    required bool nonzeroOnly,
  }) async {
    final where = <String>['COALESCE(is_active, 1) = 1'];
    final args = <Object?>[];
    _appendCustomer(where, args, f, alias: null);
    if (nonzeroOnly) {
      where.add('COALESCE(balance, 0) != 0');
    }
    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(code, '') AS code,
        COALESCE(name, '') AS title,
        COALESCE(balance, 0) AS balance,
        COALESCE(phone, '') AS phone,
        COALESCE(tax_no, '') AS tax_no,
        COALESCE(address, '') AS address
      FROM customers
      WHERE ${where.join(' AND ')}
      ORDER BY name COLLATE NOCASE
      ''',
      args,
    );
    return maps.map((r) {
      final bal = _asD(r['balance']);
      return {
        'code': '${r['code']}',
        'title': '${r['title']}',
        'debit': _amt(bal > 0 ? bal : 0),
        'credit': _amt(bal < 0 ? -bal : 0),
        'balance': _amt(bal),
        'phone': '${r['phone']}',
        'tax_no': '${r['tax_no']}',
        'address': '${r['address']}',
      };
    }).toList(growable: false);
  }

  Future<List<Map<String, String>>> _cariRisk(
    Database db,
    CariReportFilter f,
  ) async {
    return _borcAlacak(db, f, nonzeroOnly: false);
  }

  Future<List<Map<String, String>>> _gpsCustomers(
    Database db,
    CariReportFilter f, {
    required bool sortByDistance,
  }) async {
    final where = <String>[
      'latitude IS NOT NULL',
      'longitude IS NOT NULL',
      'COALESCE(is_active, 1) = 1',
    ];
    final args = <Object?>[];
    _appendCustomer(where, args, f, alias: null);

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(code, '') AS code,
        COALESCE(name, '') AS title,
        latitude AS lat,
        longitude AS lng,
        COALESCE(phone, '') AS phone,
        COALESCE(address, '') AS address
      FROM customers
      WHERE ${where.join(' AND ')}
      ORDER BY name COLLATE NOCASE
      LIMIT 500
      ''',
      args,
    );

    final oLat = f.originLat;
    final oLng = f.originLng;
    final withDist = maps.map((r) {
      final lat = _asD(r['lat']);
      final lng = _asD(r['lng']);
      double? meters;
      if (oLat != null && oLng != null) {
        meters = haversineMeters(oLat, oLng, lat, lng);
      }
      return (
        code: '${r['code']}',
        title: '${r['title']}',
        lat: lat,
        lng: lng,
        meters: meters,
        phone: '${r['phone']}',
        address: '${r['address']}',
      );
    }).toList();

    if (sortByDistance && oLat != null && oLng != null) {
      withDist.sort((a, b) {
        final am = a.meters ?? double.infinity;
        final bm = b.meters ?? double.infinity;
        return am.compareTo(bm);
      });
    }

    final maxM = f.maxDistanceMeters;
    return withDist
        .where((e) {
          if (maxM <= 0 || e.meters == null) return true;
          return e.meters! <= maxM;
        })
        .map(
          (e) => {
            'code': e.code,
            'title': e.title,
            'distance': e.meters == null
                ? ''
                : '${(e.meters! / 1000).toStringAsFixed(2)} km',
            'lat': e.lat.toStringAsFixed(6),
            'lng': e.lng.toStringAsFixed(6),
            'phone': e.phone,
            'address': e.address,
            'date': '',
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _satisYapilmayan(
    Database db,
    CariReportFilter f,
  ) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        0 AS amount
      FROM customers c
      WHERE COALESCE(c.is_active, 1) = 1
        ${_customerAnd(f, 'c')}
        AND NOT EXISTS (
          SELECT 1 FROM invoices i
          WHERE i.customer_id = c.id
            AND date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
        )
      ORDER BY c.name COLLATE NOCASE
      ''',
      [..._customerArgs(f), from, to],
    );
    return maps
        .map(
          (r) => {
            'code': '${r['code']}',
            'title': '${r['title']}',
            'amount': _amt(0),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _enCokCari(
    Database db,
    CariReportFilter f, {
    required bool sales,
  }) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final typeClause = sales
        ? "LOWER(COALESCE(i.invoice_type, 'sales')) NOT IN "
            "('purchase', 'alis', 'return')"
        : "LOWER(COALESCE(i.invoice_type, '')) IN "
            "('purchase', 'alis', 'return')";

    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        SUM(COALESCE(i.total_amount, 0)) AS amount,
        COUNT(*) AS quantity
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
        AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
        AND COALESCE(i.status, '') != 'Cancelled'
        AND $typeClause
        ${_customerAnd(f, 'c')}
      GROUP BY c.id
      ORDER BY amount DESC
      LIMIT 200
      ''',
      [from, to, ..._customerArgs(f)],
    );
    return maps
        .map(
          (r) => {
            'code': '${r['code']}',
            'title': '${r['title']}',
            'amount': _amt(_asD(r['amount'])),
            'quantity': _asD(r['quantity']).toStringAsFixed(0),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _enCokUrun(
    Database db,
    CariReportFilter f, {
    required bool sales,
  }) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    if (sales) {
      final maps = await db.rawQuery(
        '''
        SELECT
          COALESCE(p.code, p.id, '') AS stock_code,
          COALESCE(p.name, '') AS stock_name,
          SUM(COALESCE(ii.quantity, 0)) AS quantity,
          SUM(COALESCE(ii.total_amount, ii.quantity * ii.price, 0)) AS amount
        FROM invoice_items ii
        INNER JOIN invoices i ON i.id = ii.invoice_id
        LEFT JOIN products p ON p.id = ii.product_id
        WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
          AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
          AND COALESCE(i.status, '') != 'Cancelled'
          AND LOWER(COALESCE(i.invoice_type, 'sales')) NOT IN
            ('purchase', 'alis', 'return')
        GROUP BY p.id
        ORDER BY amount DESC
        LIMIT 200
        ''',
        [from, to],
      );
      return _mapUrun(maps);
    }
    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(p.code, p.id, '') AS stock_code,
        COALESCE(p.name, '') AS stock_name,
        SUM(COALESCE(oi.quantity, 0)) AS quantity,
        SUM(COALESCE(oi.total_amount, oi.quantity * oi.price, 0)) AS amount
      FROM order_items oi
      INNER JOIN orders o ON o.id = oi.order_id
      LEFT JOIN products p ON p.id = oi.product_id
      WHERE date(COALESCE(o.order_date, o.created_at)) >= date(?)
        AND date(COALESCE(o.order_date, o.created_at)) <= date(?)
        AND LOWER(COALESCE(o.order_type, 'sales')) IN ('purchase', 'alis')
      GROUP BY p.id
      ORDER BY amount DESC
      LIMIT 200
      ''',
      [from, to],
    );
    return _mapUrun(maps);
  }

  List<Map<String, String>> _mapUrun(List<Map<String, Object?>> maps) {
    return maps
        .map(
          (r) => {
            'stock_code': '${r['stock_code']}',
            'stock_name': '${r['stock_name']}',
            'quantity': _amt(_asD(r['quantity'])),
            'amount': _amt(_asD(r['amount'])),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> _cekSenet(
    Database db,
    CariReportFilter f, {
    required bool checksOnly,
  }) async {
    final from = _ymd(f.dateFrom);
    final to = _ymd(f.dateTo);
    final maps = await db.rawQuery(
      '''
      SELECT
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, '') AS title,
        COALESCE(col.document_no, col.check_number, col.id) AS doc_no,
        col.due_date AS due_date,
        COALESCE(col.amount, 0) AS amount,
        COALESCE(col.status, '') AS status,
        COALESCE(col.payment_type, '') AS payment_type
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
        AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
        ${_customerAnd(f, 'c')}
      ORDER BY col.due_date ASC
      ''',
      [from, to, ..._customerArgs(f)],
    );
    return maps
        .where((r) {
          final pt = '${r['payment_type']}'.toLowerCase();
          if (checksOnly) {
            return pt.contains('check') || pt.contains('cek');
          }
          return pt.contains('note') ||
              pt.contains('senet') ||
              pt.contains('promissory');
        })
        .map(
          (r) => {
            'code': '${r['code']}',
            'title': '${r['title']}',
            'doc_no': '${r['doc_no']}',
            'due_date': _fmtDate(_parse(r['due_date'])),
            'amount': _amt(_asD(r['amount'])),
            'status': '${r['status']}',
          },
        )
        .toList(growable: false);
  }

  void _appendCustomer(
    List<String> where,
    List<Object?> args,
    CariReportFilter f, {
    required String? alias,
  }) {
    final p = alias == null ? '' : '$alias.';
    if (f.code.trim().isNotEmpty) {
      where.add('COALESCE(${p}code, "") LIKE ?');
      args.add('%${f.code.trim()}%');
    }
    if (f.name.trim().isNotEmpty) {
      where.add('COALESCE(${p}name, "") LIKE ?');
      args.add('%${f.name.trim()}%');
    }
    if (f.code2.trim().isNotEmpty) {
      where.add('COALESCE(${p}code, "") <= ?');
      args.add(f.code2.trim());
    }
  }

  String _customerAnd(CariReportFilter f, String alias) {
    final parts = <String>[];
    if (f.code.trim().isNotEmpty) {
      parts.add('AND COALESCE($alias.code, "") LIKE ?');
    }
    if (f.name.trim().isNotEmpty) {
      parts.add('AND COALESCE($alias.name, "") LIKE ?');
    }
    if (f.code2.trim().isNotEmpty) {
      parts.add('AND COALESCE($alias.code, "") <= ?');
    }
    return parts.isEmpty ? '' : ' ${parts.join(' ')}';
  }

  List<Object?> _customerArgs(CariReportFilter f) {
    final args = <Object?>[];
    if (f.code.trim().isNotEmpty) args.add('%${f.code.trim()}%');
    if (f.name.trim().isNotEmpty) args.add('%${f.name.trim()}%');
    if (f.code2.trim().isNotEmpty) args.add(f.code2.trim());
    return args;
  }

  String _ymd(DateTime? d) {
    final v = d ?? DateTime.now();
    final y = v.year.toString().padLeft(4, '0');
    final m = v.month.toString().padLeft(2, '0');
    final dd = v.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  DateTime? _parse(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  double _asD(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _amt(double v) => v.toStringAsFixed(2);
}

class _CariEvt {
  _CariEvt({
    required this.date,
    required this.ref,
    required this.description,
    required this.debit,
    required this.credit,
    required this.voucher,
    required this.code,
    required this.title,
  });

  final DateTime date;
  final String ref;
  final String description;
  final double debit;
  final double credit;
  final String voucher;
  final String code;
  final String title;
}
