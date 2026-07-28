// Dosya Adı: other_report_query_service.dart
// Açıklama: DİĞER / yönetici / finans rapor satırlarını SQLite’tan okur
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../../core/geo/haversine.dart';
import '../../engine/mbt_report_action_service.dart';
import '../model/other_report_scope.dart';

/// {@template other_report_query_service}
/// Other-owned raporlar için dens satır üretimi (columnId → değer).
///
/// Kullanım örneği:
/// ```dart
/// final rows = await OtherReportQueryService.fetchRows(
///   db: db,
///   reportId: 'ziyaret_listesi',
///   snapshot: snapshot,
/// );
/// ```
/// {@endtemplate}
class OtherReportQueryService {
  /// {@macro other_report_query_service}
  const OtherReportQueryService._();

  /// {@template other_report_query_service_fetch_rows}
  /// Rapor id’ye göre satır listesi (bilinmeyen / hata → boş).
  /// {@endtemplate}
  static Future<List<Map<String, String>>> fetchRows({
    required Database db,
    required String reportId,
    required MbtReportParamSnapshot snapshot,
  }) async {
    if (!OtherReportScope.owns(reportId)) return const [];
    try {
      final from = _dateOnly(snapshot.dateFrom ?? DateTime.now());
      final to = _dateOnly(snapshot.dateTo ?? DateTime.now());
      final code = snapshot.code.trim();

      switch (reportId) {
        case 'plasiyer_gps':
          return _gps(db, from: from, to: to, code: code);
        case 'plasiyer_rota':
          return _rota(db, code: code);
        case 'ziyaret_listesi':
          return _visitsList(db, from: from, to: to, code: code);
        case 'ziyaret_listesi_ozel':
          // Özel: süre (dk) + check-out durumu
          return _visitsDetailed(db, from: from, to: to, code: code);
        case 'plasiyer_gunluk':
          // Günlük: plasiyer × gün ziyaret özeti (adet)
          return _visitsDailySummary(db, from: from, to: to, code: code);
        case 'plasiyer_ziyaret_ozet':
          // Özet: cari bazlı ziyaret adedi
          return _visitsCustomerSummary(db, from: from, to: to, code: code);
        case 'plasiyer_satis_ozet':
          return _invoices(db, from: from, to: to);
        case 'plasiyer_tahsilat_ozet':
          return _collections(db, from: from, to: to, code: code);
        case 'plasiyer_performans':
          return _performans(db, from: from, to: to);
        case 'yonetici_kpi':
          // Yönetici KPI: satış/tahsilat/ziyaret + sipariş satırı
          return _yoneticiKpi(db, from: from, to: to);
        case 'yonetici_leaderboard':
          return _leaderboard(db, code: code);
        case 'yonetici_period_compare':
          return _periodCompare(db, from: from, to: to);
        case 'kasa_hareket':
        case 'yonetici_kasa':
          return _kasaHareket(db, from: from, to: to, code: code);
        case 'yonetici_banka':
          return _banka(db, from: from, to: to);
        case 'yonetici_cek':
        case 'finans_portfoy_cek':
          return _cekSenet(db, from: from, to: to, check: true, firma: false);
        case 'finans_firma_cek':
          return _cekSenet(db, from: from, to: to, check: true, firma: true);
        case 'yonetici_senet':
        case 'finans_portfoy_senet':
          return _cekSenet(db, from: from, to: to, check: false, firma: false);
        case 'finans_firma_senet':
          return _cekSenet(db, from: from, to: to, check: false, firma: true);
        case 'yonetici_firma_genel':
          return _firmaGenel(db, from: from, to: to);
        case 'yonetici_fatura_satis':
          return _invoices(db, from: from, to: to, purchaseSide: false);
        case 'yonetici_fatura_alis':
          // Alış fatura — iade (Return) değil; Purchase/Alış tipi
          return _invoices(db, from: from, to: to, purchaseSide: true);
        case 'yonetici_siparis_satis':
          return _orders(db, from: from, to: to, type: 'sales');
        case 'yonetici_siparis_alis':
          return _orders(db, from: from, to: to, type: 'purchase');
        case 'finans_transfer_edilen':
          return _transfer(db, synced: true);
        case 'finans_transfer_edilmeyen':
          return _transfer(db, synced: false);
        case 'finans_kasa_bakiye':
          return _kasaBakiye(db, code: code);
        default:
          return const [];
      }
    } catch (_) {
      return const [];
    }
  }

  static Future<List<Map<String, Object?>>> _q(
    Database db,
    String sql, [
    List<Object?>? args,
  ]) async {
    try {
      return await db.rawQuery(sql, args);
    } catch (_) {
      return const [];
    }
  }

  static Future<List<Map<String, String>>> _gps(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT salesperson_code, label, latitude, longitude, timestamp
      FROM gps_logs
      WHERE COALESCE(is_deleted, 0) = 0
        AND date(timestamp) >= date(?)
        AND date(timestamp) <= date(?)
        AND (? = '' OR salesperson_code = ?)
      ORDER BY timestamp DESC
      ''',
      [from, to, code, code],
    );
    return maps
        .map(
          (r) => {
            'code': '${r['salesperson_code'] ?? ''}',
            'title': '${r['label'] ?? ''}',
            'distance': '',
            'lat': _num(r['latitude']),
            'lng': _num(r['longitude']),
            'date': _fmtDate(r['timestamp']?.toString()),
          },
        )
        .toList(growable: false);
  }

  /// Haftalık rota durakları (`routes` + `route_customers`).
  static Future<List<Map<String, String>>> _rota(
    Database db, {
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        rc.visit_order AS visit_order,
        COALESCE(r.day_of_week, 0) AS day_of_week,
        COALESCE(r.name, '') AS route_name,
        COALESCE(r.salesperson_id, '') AS salesperson_id,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, '') AS customer_name,
        COALESCE(rc.is_mandatory, 1) AS is_mandatory,
        c.latitude AS latitude,
        c.longitude AS longitude
      FROM route_customers rc
      INNER JOIN routes r ON r.id = rc.route_id
      LEFT JOIN customers c ON c.id = rc.customer_id
      WHERE COALESCE(r.is_active, 1) = 1
        AND (
          ? = ''
          OR COALESCE(r.salesperson_id, '') = ?
          OR COALESCE(c.code, '') = ?
        )
      ORDER BY
        COALESCE(r.day_of_week, 0) ASC,
        COALESCE(r.salesperson_id, '') ASC,
        rc.visit_order ASC,
        rc.id ASC
      ''',
      [code, code, code],
    );
    // Durak arası mesafe (önceki → sonraki haversine km); ilk durak boş
    double? prevLat;
    double? prevLng;
    final out = <Map<String, String>>[];
    for (final r in maps) {
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      var distance = '';
      if (prevLat != null &&
          prevLng != null &&
          lat != null &&
          lng != null) {
        distance = haversineKm(prevLat, prevLng, lat, lng).toStringAsFixed(2);
      }
      if (lat != null && lng != null) {
        prevLat = lat;
        prevLng = lng;
      }
      out.add({
        'visit_order': '${r['visit_order'] ?? ''}',
        'rank': '${r['visit_order'] ?? ''}',
        'weekday': '${r['day_of_week'] ?? ''}',
        'period': '${r['day_of_week'] ?? ''}',
        'code': '${r['customer_code'] ?? ''}',
        'title': '${r['customer_name'] ?? ''}',
        'salesperson': '${r['salesperson_id'] ?? ''}',
        'status':
            (r['is_mandatory'] as num?)?.toInt() == 1
                ? 'mandatory'
                : 'optional',
        'distance': distance,
        'lat': _num(r['latitude']),
        'lng': _num(r['longitude']),
        'description': '${r['route_name'] ?? ''}',
      });
    }
    return out;
  }

  /// Standart ziyaret listesi (satır bazlı).
  static Future<List<Map<String, String>>> _visitsList(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        v.check_in_at AS event_date,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, v.customer_id, '') AS customer_name,
        COALESCE(v.user_id, '') AS salesperson_code,
        COALESCE(v.status, '') AS status
      FROM visits v
      LEFT JOIN customers c ON c.id = v.customer_id
      WHERE date(COALESCE(v.check_in_at, v.created_at)) >= date(?)
        AND date(COALESCE(v.check_in_at, v.created_at)) <= date(?)
        AND (? = '' OR v.user_id = ?)
      ORDER BY v.check_in_at DESC
      ''',
      [from, to, code, code],
    );
    return maps
        .map(
          (r) => {
            'date': _fmtDate(r['event_date']?.toString()),
            'visit_time': _fmtTime(r['event_date']?.toString()),
            'code': '${r['customer_code'] ?? ''}',
            'title': '${r['customer_name'] ?? ''}',
            'salesperson': '${r['salesperson_code'] ?? ''}',
            'status': '${r['status'] ?? ''}',
            'amount': '0.00',
          },
        )
        .toList(growable: false);
  }

  /// Cari bazlı ziyaret özeti — son tarih + adet.
  static Future<List<Map<String, String>>> _visitsCustomerSummary(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, v.customer_id, '') AS customer_name,
        COUNT(*) AS visit_count,
        MAX(COALESCE(v.check_in_at, v.created_at)) AS last_visit
      FROM visits v
      LEFT JOIN customers c ON c.id = v.customer_id
      WHERE date(COALESCE(v.check_in_at, v.created_at)) >= date(?)
        AND date(COALESCE(v.check_in_at, v.created_at)) <= date(?)
        AND (? = '' OR v.user_id = ?)
      GROUP BY customer_code, customer_name
      ORDER BY visit_count DESC, customer_code ASC
      ''',
      [from, to, code, code],
    );
    return maps
        .map(
          (r) => {
            'date': _fmtDate(r['last_visit']?.toString()),
            'visit_time': _fmtTime(r['last_visit']?.toString()),
            'code': '${r['customer_code'] ?? ''}',
            'title': '${r['customer_name'] ?? ''}',
            'salesperson': '',
            'status': '',
            'amount': _num(r['visit_count']),
          },
        )
        .toList(growable: false);
  }

  /// Ziyaret listesi özel — süre (dk) + check-out.
  static Future<List<Map<String, String>>> _visitsDetailed(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        v.check_in_at AS event_date,
        v.check_out_at AS check_out_at,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, v.customer_id, '') AS customer_name,
        COALESCE(v.user_id, '') AS salesperson_code,
        COALESCE(v.status, '') AS status
      FROM visits v
      LEFT JOIN customers c ON c.id = v.customer_id
      WHERE date(COALESCE(v.check_in_at, v.created_at)) >= date(?)
        AND date(COALESCE(v.check_in_at, v.created_at)) <= date(?)
        AND (? = '' OR v.user_id = ?)
      ORDER BY v.check_in_at DESC
      ''',
      [from, to, code, code],
    );
    return maps.map((r) {
      final inAt = DateTime.tryParse('${r['event_date'] ?? ''}');
      final outAt = DateTime.tryParse('${r['check_out_at'] ?? ''}');
      final minutes = (inAt != null && outAt != null)
          ? outAt.difference(inAt).inMinutes
          : null;
      final status = '${r['status'] ?? ''}';
      final dur =
          minutes == null ? status : '$status · ${minutes}dk';
      return {
        'date': _fmtDate(r['event_date']?.toString()),
        'visit_time': _fmtTime(r['event_date']?.toString()),
        'code': '${r['customer_code'] ?? ''}',
        'title': '${r['customer_name'] ?? ''}',
        'salesperson': '${r['salesperson_code'] ?? ''}',
        'status': dur,
        'amount': minutes == null ? '0.00' : minutes.toStringAsFixed(2),
      };
    }).toList(growable: false);
  }

  /// Plasiyer günlük — gün × plasiyer ziyaret adedi.
  static Future<List<Map<String, String>>> _visitsDailySummary(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        date(COALESCE(v.check_in_at, v.created_at)) AS day,
        COALESCE(v.user_id, '') AS salesperson_code,
        COUNT(*) AS cnt
      FROM visits v
      WHERE date(COALESCE(v.check_in_at, v.created_at)) >= date(?)
        AND date(COALESCE(v.check_in_at, v.created_at)) <= date(?)
        AND (? = '' OR v.user_id = ?)
      GROUP BY date(COALESCE(v.check_in_at, v.created_at)),
               COALESCE(v.user_id, '')
      ORDER BY day DESC, salesperson_code ASC
      ''',
      [from, to, code, code],
    );
    return maps
        .map(
          (r) => {
            'date': _fmtDate(r['day']?.toString()),
            'salesperson': '${r['salesperson_code'] ?? ''}',
            'code': '${r['salesperson_code'] ?? ''}',
            'title': 'Ziyaret',
            'amount': '${r['cnt'] ?? 0}.00',
            'quantity': '${r['cnt'] ?? 0}',
            'status': 'daily',
            'visit_time': '',
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _invoices(
    Database db, {
    required String from,
    required String to,
    bool? purchaseSide,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        i.id AS doc_no,
        i.invoice_date AS event_date,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, i.customer_id, '') AS title,
        COALESCE(i.total_amount, 0) AS amount,
        COALESCE(i.status, '') AS status,
        COALESCE(i.invoice_type, 'Sales') AS invoice_type
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
        AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
        AND COALESCE(i.status, '') != 'Cancelled'
      ORDER BY i.invoice_date DESC
      ''',
      [from, to],
    );
    return maps
        .where((r) {
          if (purchaseSide == null) return true;
          final t = '${r['invoice_type'] ?? ''}'.toLowerCase();
          final isPurchase = t.contains('purch') ||
              t.contains('alis') ||
              t == 'alış';
          return purchaseSide ? isPurchase : !isPurchase;
        })
        .map(
          (r) => {
            'doc_no': '${r['doc_no'] ?? ''}',
            'date': _fmtDate(r['event_date']?.toString()),
            'code': '${r['code'] ?? ''}',
            'title': '${r['title'] ?? ''}',
            'amount': _num(r['amount']),
            'status': '${r['status'] ?? ''}',
            'salesperson': '',
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _orders(
    Database db, {
    required String from,
    required String to,
    required String type,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        o.id AS doc_no,
        o.order_date AS event_date,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, o.customer_id, '') AS title,
        COALESCE(o.total_amount, 0) AS amount,
        COALESCE(o.status, '') AS status
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE date(COALESCE(o.order_date, o.created_at)) >= date(?)
        AND date(COALESCE(o.order_date, o.created_at)) <= date(?)
        AND COALESCE(o.order_type, 'sales') = ?
      ORDER BY o.order_date DESC
      ''',
      [from, to, type],
    );
    return maps
        .map(
          (r) => {
            'doc_no': '${r['doc_no'] ?? ''}',
            'date': _fmtDate(r['event_date']?.toString()),
            'code': '${r['code'] ?? ''}',
            'title': '${r['title'] ?? ''}',
            'amount': _num(r['amount']),
            'status': '${r['status'] ?? ''}',
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _collections(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        col.collection_date AS event_date,
        COALESCE(col.salesperson_code, '') AS salesperson_code,
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, col.customer_id, '') AS title,
        COALESCE(col.amount, 0) AS amount,
        COALESCE(col.payment_type, '') AS payment_type,
        COALESCE(col.status, '') AS status
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
        AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
        AND (? = '' OR COALESCE(col.salesperson_code, '') = ?)
      ORDER BY col.collection_date DESC
      ''',
      [from, to, code, code],
    );
    return maps
        .map(
          (r) => {
            'date': _fmtDate(r['event_date']?.toString()),
            'salesperson': '${r['salesperson_code'] ?? ''}',
            'code': '${r['code'] ?? ''}',
            'title': '${r['title'] ?? ''}',
            'amount': _num(r['amount']),
            'txn_type': '${r['payment_type'] ?? ''}',
            'status': '${r['status'] ?? ''}',
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _performans(
    Database db, {
    required String from,
    required String to,
  }) async {
    final sales = await _q(
      db,
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS amount, COUNT(*) AS cnt
      FROM invoices
      WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
        AND date(COALESCE(invoice_date, created_at)) <= date(?)
        AND COALESCE(status, '') != 'Cancelled'
      ''',
      [from, to],
    );
    final col = await _q(
      db,
      '''
      SELECT COALESCE(SUM(amount), 0) AS amount, COUNT(*) AS cnt
      FROM collections
      WHERE date(COALESCE(collection_date, created_at)) >= date(?)
        AND date(COALESCE(collection_date, created_at)) <= date(?)
      ''',
      [from, to],
    );
    final vis = await _q(
      db,
      '''
      SELECT COUNT(*) AS cnt
      FROM visits
      WHERE date(COALESCE(check_in_at, created_at)) >= date(?)
        AND date(COALESCE(check_in_at, created_at)) <= date(?)
      ''',
      [from, to],
    );
    return [
      {
        'code': 'SATIS',
        'title': 'Satış',
        'amount': _num(sales.isEmpty ? 0 : sales.first['amount']),
        'quantity': '${sales.isEmpty ? 0 : sales.first['cnt'] ?? 0}',
        'date': '$from – $to',
        'salesperson': '',
      },
      {
        'code': 'TAHSILAT',
        'title': 'Tahsilat',
        'amount': _num(col.isEmpty ? 0 : col.first['amount']),
        'quantity': '${col.isEmpty ? 0 : col.first['cnt'] ?? 0}',
        'date': '$from – $to',
        'salesperson': '',
      },
      {
        'code': 'ZIYARET',
        'title': 'Ziyaret',
        'amount': '0.00',
        'quantity': '${vis.isEmpty ? 0 : vis.first['cnt'] ?? 0}',
        'date': '$from – $to',
        'salesperson': '',
      },
    ];
  }

  /// Yönetici KPI — performans + sipariş satırı (ad ayrı).
  static Future<List<Map<String, String>>> _yoneticiKpi(
    Database db, {
    required String from,
    required String to,
  }) async {
    final base = await _performans(db, from: from, to: to);
    final orders = await _q(
      db,
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS amount, COUNT(*) AS cnt
      FROM orders
      WHERE date(COALESCE(order_date, created_at)) >= date(?)
        AND date(COALESCE(order_date, created_at)) <= date(?)
        AND COALESCE(status, '') != 'Cancelled'
      ''',
      [from, to],
    );
    return [
      ...base,
      {
        'code': 'SIPARIS',
        'title': 'Sipariş',
        'amount': _num(orders.isEmpty ? 0 : orders.first['amount']),
        'quantity': '${orders.isEmpty ? 0 : orders.first['cnt'] ?? 0}',
        'date': '$from – $to',
        'salesperson': '',
      },
    ];
  }

  /// Hedef sıralaması — `plasiyer_profile` puan veya `targets` gerçekleşme.
  static Future<List<Map<String, String>>> _leaderboard(
    Database db, {
    required String code,
  }) async {
    final points = await _q(
      db,
      '''
      SELECT
        COALESCE(id, '') AS id,
        COALESCE(name, id, '') AS name,
        COALESCE(total_points, 0) AS points,
        COALESCE(level, 1) AS level
      FROM plasiyer_profile
      WHERE (? = '' OR COALESCE(name, '') LIKE '%' || ? || '%'
            OR COALESCE(id, '') = ?)
      ORDER BY COALESCE(total_points, 0) DESC, name ASC
      ''',
      [code, code, code],
    );
    if (points.isNotEmpty) {
      final rows = <Map<String, String>>[];
      for (var i = 0; i < points.length; i++) {
        final r = points[i];
        rows.add({
          'rank': '${i + 1}',
          'code': '${r['id'] ?? ''}',
          'title': '${r['name'] ?? ''}',
          'salesperson': '${r['name'] ?? ''}',
          'points': '${(r['points'] as num?)?.toInt() ?? 0}',
          'amount': _num(r['points']),
          'quantity': '${r['level'] ?? 1}',
          'period': '',
          'percent': '',
          'target': '',
          'achieved': _num(r['points']),
        });
      }
      return rows;
    }

    final targets = await _q(
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
      WHERE (? = '' OR COALESCE(user_id, '') LIKE '%' || ? || '%')
      ORDER BY pct DESC, achieved_amount DESC, user_id ASC
      ''',
      [code, code],
    );
    final rows = <Map<String, String>>[];
    for (var i = 0; i < targets.length; i++) {
      final r = targets[i];
      rows.add({
        'rank': '${i + 1}',
        'code': '${r['type'] ?? ''}',
        'title': '${r['user_id'] ?? ''}',
        'salesperson': '${r['user_id'] ?? ''}',
        'period': '${r['period'] ?? ''}',
        'target': _num(r['target_amount']),
        'achieved': _num(r['achieved_amount']),
        'percent': _num(r['pct']),
        'points': _num(r['pct']),
        'amount': _num(r['achieved_amount']),
        'quantity': _num(r['pct']),
      });
    }
    return rows;
  }

  /// Seçili dönem vs önceki eşit uzunlukta dönem KPI karşılaştırma.
  static Future<List<Map<String, String>>> _periodCompare(
    Database db, {
    required String from,
    required String to,
  }) async {
    final fromDt = DateTime.tryParse(from) ?? DateTime.now();
    final toDt = DateTime.tryParse(to) ?? fromDt;
    final spanDays = toDt.difference(fromDt).inDays.abs() + 1;
    final prevToDt = fromDt.subtract(const Duration(days: 1));
    final prevFromDt = prevToDt.subtract(Duration(days: spanDays - 1));
    final prevFrom = _dateOnly(prevFromDt);
    final prevTo = _dateOnly(prevToDt);

    Future<double> metricSum(String sql, String a, String b) async {
      final rows = await _q(db, sql, [a, b]);
      if (rows.isEmpty) return 0;
      return (rows.first.values.first as num?)?.toDouble() ?? 0;
    }

    const salesSql = '''
      SELECT COALESCE(SUM(total_amount), 0)
      FROM invoices
      WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
        AND date(COALESCE(invoice_date, created_at)) <= date(?)
        AND COALESCE(status, '') != 'Cancelled'
    ''';
    const colSql = '''
      SELECT COALESCE(SUM(amount), 0)
      FROM collections
      WHERE date(COALESCE(collection_date, created_at)) >= date(?)
        AND date(COALESCE(collection_date, created_at)) <= date(?)
    ''';
    const visSql = '''
      SELECT COALESCE(COUNT(*), 0)
      FROM visits
      WHERE date(COALESCE(check_in_at, created_at)) >= date(?)
        AND date(COALESCE(check_in_at, created_at)) <= date(?)
    ''';

    final metrics = <Map<String, String>>[
      {'code': 'SATIS', 'title': 'Satış', 'sql': salesSql},
      {'code': 'TAHSILAT', 'title': 'Tahsilat', 'sql': colSql},
      {'code': 'ZIYARET', 'title': 'Ziyaret', 'sql': visSql},
    ];

    final out = <Map<String, String>>[];
    for (final m in metrics) {
      final current = await metricSum(m['sql']!, from, to);
      final previous = await metricSum(m['sql']!, prevFrom, prevTo);
      final growth = previous == 0
          ? (current == 0 ? 0.0 : 100.0)
          : ((current - previous) / previous) * 100;
      out.add({
        'code': m['code']!,
        'title': m['title']!,
        'period': '$from – $to',
        'previous': _num(previous),
        'current': _num(current),
        'growth': _num(growth),
        'amount': _num(current),
        'date': '$prevFrom – $prevTo',
        'diff': _num(current - previous),
      });
    }
    return out;
  }

  static Future<List<Map<String, String>>> _kasaHareket(
    Database db, {
    required String from,
    required String to,
    required String code,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        col.collection_date AS event_date,
        COALESCE(col.document_no, col.id, '') AS document_no,
        COALESCE(col.payment_type, '') AS payment_type,
        COALESCE(c.name, col.customer_id, '') AS customer_name,
        COALESCE(col.amount, 0) AS amount
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
        AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
        AND LOWER(COALESCE(col.payment_type, '')) IN
            ('cash', 'nakit', 'creditcard', 'credit_card')
        AND (? = '' OR COALESCE(col.cash_code, '') = ?)
      ORDER BY col.collection_date DESC
      ''',
      [from, to, code, code],
    );
    return maps
        .map(
          (r) => {
            'date': _fmtDate(r['event_date']?.toString()),
            'doc_no': '${r['document_no'] ?? ''}',
            'description':
                '${r['payment_type'] ?? ''} · ${r['customer_name'] ?? ''}',
            'debit': _num(r['amount']),
            'credit': '0.00',
            'balance': _num(r['amount']),
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _banka(
    Database db, {
    required String from,
    required String to,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        COALESCE(bank_name, 'BANKA') AS bank_name,
        COALESCE(branch_name, '') AS branch_name,
        COALESCE(amount, 0) AS amount,
        COALESCE(payment_type, '') AS payment_type,
        collection_date AS event_date
      FROM collections
      WHERE date(COALESCE(collection_date, created_at)) >= date(?)
        AND date(COALESCE(collection_date, created_at)) <= date(?)
        AND (
          LOWER(COALESCE(payment_type, '')) LIKE '%card%'
          OR LOWER(COALESCE(payment_type, '')) LIKE '%bank%'
          OR LOWER(COALESCE(payment_type, '')) LIKE '%kk%'
        )
      ORDER BY collection_date DESC
      ''',
      [from, to],
    );
    return maps
        .map(
          (r) => {
            'code': '${r['bank_name'] ?? ''}',
            'title': '${r['branch_name'] ?? ''}',
            'amount': _num(r['amount']),
            'status': '${r['payment_type'] ?? ''}',
            'date': _fmtDate(r['event_date']?.toString()),
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _cekSenet(
    Database db, {
    required String from,
    required String to,
    required bool check,
    required bool firma,
  }) async {
    final types = check
        ? "('check', 'cek', 'çek')"
        : "('promissory', 'senet', 'note')";
    final maps = await _q(
      db,
      '''
      SELECT
        COALESCE(c.code, '') AS code,
        COALESCE(c.name, col.customer_id, '') AS title,
        COALESCE(col.check_number, col.document_no, '') AS doc_no,
        col.due_date AS due_date,
        COALESCE(col.amount, 0) AS amount,
        COALESCE(col.status, '') AS status
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
        AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
        AND LOWER(COALESCE(col.payment_type, '')) IN $types
      ORDER BY col.due_date ASC
      ''',
      [from, to],
    );
    return maps
        .where((r) {
          final status = '${r['status'] ?? ''}'.toLowerCase();
          if (firma) {
            return status.contains('firma') || status.contains('company');
          }
          return !status.contains('firma') && !status.contains('company');
        })
        .map(
          (r) => {
            'code': '${r['code'] ?? ''}',
            'title': '${r['title'] ?? ''}',
            'doc_no': '${r['doc_no'] ?? ''}',
            'due_date': _fmtDate(r['due_date']?.toString()),
            'amount': _num(r['amount']),
            'status': '${r['status'] ?? ''}',
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _firmaGenel(
    Database db, {
    required String from,
    required String to,
  }) async {
    final perf = await _performans(db, from: from, to: to);
    return [
      for (final r in perf)
        {
          'code': r['code'] ?? '',
          'title': r['title'] ?? '',
          'amount': r['amount'] ?? '0.00',
          'date': r['date'] ?? '',
        },
    ];
  }

  static Future<List<Map<String, String>>> _transfer(
    Database db, {
    required bool synced,
  }) async {
    final maps = await _q(
      db,
      '''
      SELECT
        col.customer_id AS customer_id,
        COALESCE(c.name, col.customer_id, '') AS customer_name,
        col.collection_date AS collection_date,
        COALESCE(col.payment_type, '') AS payment_type,
        COALESCE(col.amount, 0) AS amount,
        COALESCE(col.document_no, '') AS document_no
      FROM collections col
      LEFT JOIN customers c ON c.id = col.customer_id
      WHERE COALESCE(col.is_synced, 0) = ?
      ORDER BY col.collection_date DESC
      ''',
      [synced ? 1 : 0],
    );
    return maps
        .map(
          (r) => {
            'code': '${r['customer_id'] ?? ''}',
            'title': '${r['customer_name'] ?? ''}',
            'txn_date': _fmtDate(r['collection_date']?.toString()),
            'txn_type': '${r['payment_type'] ?? ''}',
            'amount': _num(r['amount']),
            'remaining': '0.00',
            'due_date': '',
            'day_diff': '',
            'doc_no': '${r['document_no'] ?? ''}',
            'status': synced ? 'synced' : 'pending',
          },
        )
        .toList(growable: false);
  }

  static Future<List<Map<String, String>>> _kasaBakiye(
    Database db, {
    required String code,
  }) async {
    // Kasa kartı + collections cash_code toplami (gerçek bakiye vekili)
    final maps = await _q(
      db,
      '''
      SELECT
        cc.code AS code,
        cc.name AS name,
        cc.is_active AS is_active,
        COALESCE((
          SELECT SUM(COALESCE(col.amount, 0))
          FROM collections col
          WHERE COALESCE(col.cash_code, '') = cc.code
            AND LOWER(COALESCE(col.payment_type, '')) IN
                ('cash', 'nakit', 'creditcard', 'credit_card')
        ), 0) AS balance
      FROM cash_cards cc
      WHERE (? = '' OR cc.code = ? OR cc.name LIKE '%' || ? || '%')
      ORDER BY cc.code ASC
      ''',
      [code, code, code],
    );
    if (maps.isNotEmpty) {
      return maps
          .map(
            (r) => {
              'code': '${r['code'] ?? ''}',
              'title': '${r['name'] ?? ''}',
              'balance': _num(r['balance']),
              'amount': _num(r['balance']),
              'date': '',
              'status':
                  (r['is_active'] as num?)?.toInt() == 1 ? 'Aktif' : 'Pasif',
            },
          )
          .toList(growable: false);
    }
    // cash_cards yoksa collections cash_code grupla
    final fallback = await _q(
      db,
      '''
      SELECT
        COALESCE(NULLIF(TRIM(cash_code), ''), '01') AS code,
        COALESCE(SUM(amount), 0) AS balance
      FROM collections
      WHERE LOWER(COALESCE(payment_type, '')) IN
            ('cash', 'nakit', 'creditcard', 'credit_card')
        AND (? = '' OR COALESCE(cash_code, '') = ?)
      GROUP BY COALESCE(NULLIF(TRIM(cash_code), ''), '01')
      ORDER BY code ASC
      ''',
      [code, code],
    );
    return fallback
        .map(
          (r) => {
            'code': '${r['code'] ?? ''}',
            'title': '${r['code'] ?? ''}',
            'balance': _num(r['balance']),
            'amount': _num(r['balance']),
            'date': '',
            'status': 'Aktif',
          },
        )
        .toList(growable: false);
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _num(Object? raw) {
    final n = (raw as num?)?.toDouble() ?? 0;
    return n.toStringAsFixed(2);
  }

  static String _fmtDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  static String _fmtTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat('HH:mm').format(parsed);
  }
}
