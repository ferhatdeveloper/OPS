// Dosya Adı: admin_kpi_repository.dart
// Açıklama: Yönetici KPI SQLite COUNT/SUM/pivot aggregate okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/admin_kpi_summary.dart';

/// {@template admin_kpi_repository}
/// Yerel SQLite’tan yönetici KPI sayılarını / tutarlarını okur.
///
/// Kullanım örneği:
/// ```dart
/// const repo = AdminKpiRepository();
/// final summary = await repo.fetchToday(db);
/// ```
/// {@endtemplate}
class AdminKpiRepository {
  /// {@macro admin_kpi_repository}
  const AdminKpiRepository();

  /// {@template admin_kpi_repository_fetch_today}
  /// Verilen güne (varsayılan: bugün) ait özeti döner.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [day]: Hedef gün (yalnızca tarih kısmı kullanılır)
  ///
  /// Dönüş değeri:
  /// - [AdminKpiSummary]: Aktivite + snapshot alanları
  /// {@endtemplate}
  Future<AdminKpiSummary> fetchToday(
    Database db, {
    DateTime? day,
  }) async {
    final target = day ?? DateTime.now();
    final dayOnly = DateTime(target.year, target.month, target.day);
    return fetchPeriod(
      db,
      period: AdminKpiPeriod.today,
      anchor: dayOnly,
    );
  }

  /// {@template admin_kpi_repository_fetch_period}
  /// Dönem (Bugün / Hafta / Ay) için COUNT / SUM + snapshot + pivot.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite
  /// - [period]: Dens dönem seçimi
  /// - [anchor]: Aralık bitişi (varsayılan: bugün)
  ///
  /// Dönüş değeri:
  /// - [AdminKpiSummary]: Yerel tablolardan display-only KPI
  /// {@endtemplate}
  Future<AdminKpiSummary> fetchPeriod(
    Database db, {
    required AdminKpiPeriod period,
    DateTime? anchor,
  }) async {
    final end = _dateOnly(anchor ?? DateTime.now());
    final start = _periodStart(period, end);
    final startKey = _toDateOnly(start);
    final endKey = _toDateOnly(end);
    final periodPrefix = _periodPrefix(end);

    final activity = await _safeQuery(
      db,
      SqlQuerys.adminKpiPeriodActivitySql,
      [
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
      ],
    );
    final finance = await _safeQuery(
      db,
      SqlQuerys.adminKpiPeriodFinanceSql,
      [
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
        startKey, endKey,
      ],
    );
    final receivables = await _safeQuery(
      db,
      SqlQuerys.adminKpiReceivablesSql,
    );
    final pending = await _safeQuery(
      db,
      SqlQuerys.adminKpiPendingTransfersSql,
    );
    final targets = await _safeQuery(
      db,
      SqlQuerys.adminKpiTargetsSql,
      [periodPrefix],
    );
    final sparklineSales = await _fetchSparkline(
      db,
      end,
      SqlQuerys.adminKpiSparklineSalesSql,
    );
    final sparklineCollections = await _fetchSparkline(
      db,
      end,
      SqlQuerys.adminKpiSparklineCollectionsSql,
    );
    final pivotRows = await _fetchPivot(
      db,
      startKey: startKey,
      endKey: endKey,
      periodPrefix: periodPrefix,
    );

    final act = activity.isEmpty ? <String, Object?>{} : activity.first;
    final fin = finance.isEmpty ? <String, Object?>{} : finance.first;
    final recv =
        receivables.isEmpty ? <String, Object?>{} : receivables.first;
    final pend = pending.isEmpty ? <String, Object?>{} : pending.first;
    final tgt = targets.isEmpty ? <String, Object?>{} : targets.first;

    final cardCollected = _asDouble(fin['card_collected']);
    final bankDeposits = _asDouble(fin['bank_deposits']);
    final activeKeys = <String>{};
    for (final row in pivotRows) {
      if (row.salespersonKey != '_') {
        activeKeys.add(row.salespersonKey);
      }
    }

    return AdminKpiSummary(
      orderCount: _asInt(act['order_count']),
      invoiceCount: _asInt(act['invoice_count']),
      collectionCount: _asInt(act['collection_count']),
      visitCount: _asInt(act['visit_count']),
      waybillCount: _asInt(act['waybill_count']),
      salesAmount: _asDouble(act['sales_amount']),
      orderAmount: _asDouble(act['order_amount']),
      collectionAmount: _asDouble(act['collection_amount']),
      cashCollected: _asDouble(fin['cash_collected']),
      checkCollected: _asDouble(fin['check_collected']),
      bankSnapshot: cardCollected + bankDeposits,
      openReceivables: _asDouble(recv['open_receivables']),
      debtorCount: _asInt(recv['debtor_count']),
      pendingOrderCount: _asInt(pend['pending_orders']),
      pendingInvoiceCount: _asInt(pend['pending_invoices']),
      pendingWaybillCount: _asInt(pend['pending_waybills']),
      targetAmount: _asDouble(tgt['target_amount']),
      targetAchieved: _asDouble(tgt['target_achieved']),
      activeSalespersonCount: activeKeys.length,
      sparklineSales: sparklineSales,
      sparklineCollections: sparklineCollections,
      pivotRows: pivotRows,
    );
  }

  /// {@template admin_kpi_repository_period_start}
  /// Dönem başlangıç tarihini hesaplar.
  /// {@endtemplate}
  DateTime _periodStart(AdminKpiPeriod period, DateTime end) {
    switch (period) {
      case AdminKpiPeriod.today:
        return end;
      case AdminKpiPeriod.week:
        // Pazartesi = 1 … Pazar = 7
        final weekday = end.weekday;
        return end.subtract(Duration(days: weekday - 1));
      case AdminKpiPeriod.month:
        return DateTime(end.year, end.month, 1);
    }
  }

  /// {@template admin_kpi_repository_period_prefix}
  /// Hedef tablosu `period` öneki (`yyyy-MM`).
  /// {@endtemplate}
  String _periodPrefix(DateTime end) {
    final y = end.year.toString().padLeft(4, '0');
    final m = end.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  /// {@template admin_kpi_repository_fetch_sparkline}
  /// Son 7 gün (bitiş dahil) günlük tutar; boş gün = 0.
  /// {@endtemplate}
  Future<List<double>> _fetchSparkline(
    Database db,
    DateTime end,
    String sql,
  ) async {
    final start = end.subtract(const Duration(days: 6));
    final startKey = _toDateOnly(start);
    final endKey = _toDateOnly(end);
    final rows = await _safeQuery(db, sql, [startKey, endKey]);
    final byDay = <String, double>{};
    for (final row in rows) {
      final key = row['day_key']?.toString() ?? '';
      if (key.isEmpty) continue;
      byDay[key] = _asDouble(row['amount']);
    }
    final out = <double>[];
    for (var i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      out.add(byDay[_toDateOnly(d)] ?? 0);
    }
    return out;
  }

  /// {@template admin_kpi_repository_fetch_pivot}
  /// Plasiyer × ziyaret / tahsilat / hedef pivot satırları.
  /// {@endtemplate}
  Future<List<AdminKpiPivotRow>> _fetchPivot(
    Database db, {
    required String startKey,
    required String endKey,
    required String periodPrefix,
  }) async {
    final visits = await _safeQuery(
      db,
      SqlQuerys.adminKpiPivotVisitsSql,
      [startKey, endKey],
    );
    final collections = await _safeQuery(
      db,
      SqlQuerys.adminKpiPivotCollectionsSql,
      [startKey, endKey],
    );
    final targets = await _safeQuery(
      db,
      SqlQuerys.adminKpiPivotTargetsSql,
      [periodPrefix],
    );
    final names = await _safeQuery(db, SqlQuerys.adminKpiUserNamesSql);
    final nameById = <String, String>{};
    for (final row in names) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      nameById[id] = row['display_name']?.toString() ?? id;
    }

    final merged = <String, _PivotAcc>{};
    void ensure(String key) {
      merged.putIfAbsent(key, () => _PivotAcc());
    }

    for (final row in visits) {
      final key = row['sp_key']?.toString() ?? '_';
      ensure(key);
      merged[key]!.visitCount = _asInt(row['visit_count']);
    }
    for (final row in collections) {
      final key = row['sp_key']?.toString() ?? '_';
      ensure(key);
      merged[key]!.collectionCount = _asInt(row['collection_count']);
      merged[key]!.collectionAmount = _asDouble(row['collection_amount']);
    }
    for (final row in targets) {
      final key = row['sp_key']?.toString() ?? '_';
      ensure(key);
      merged[key]!.targetAmount = _asDouble(row['target_amount']);
      merged[key]!.targetAchieved = _asDouble(row['target_achieved']);
    }

    final out = <AdminKpiPivotRow>[];
    for (final entry in merged.entries) {
      final key = entry.key;
      final acc = entry.value;
      final name = nameById[key] ?? (key == '_' ? '—' : key);
      out.add(
        AdminKpiPivotRow(
          salespersonKey: key,
          salespersonName: name,
          visitCount: acc.visitCount,
          collectionCount: acc.collectionCount,
          collectionAmount: acc.collectionAmount,
          targetAmount: acc.targetAmount,
          targetAchieved: acc.targetAchieved,
        ),
      );
    }
    out.sort((a, b) {
      final byAmount =
          b.collectionAmount.compareTo(a.collectionAmount);
      if (byAmount != 0) return byAmount;
      return b.visitCount.compareTo(a.visitCount);
    });
    return out;
  }

  /// {@template admin_kpi_repository_safe_query}
  /// Tablo yoksa boş liste döner (kısmi şema / test DB).
  /// {@endtemplate}
  Future<List<Map<String, Object?>>> _safeQuery(
    Database db,
    String sql, [
    List<Object?>? args,
  ]) async {
    try {
      return await db.rawQuery(sql, args);
    } catch (_) {
      return const <Map<String, Object?>>[];
    }
  }

  /// {@template admin_kpi_repository_date_only}
  /// Saati sıfırlanmış tarih.
  /// {@endtemplate}
  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// {@template admin_kpi_repository_to_date_only}
  /// Tarihi `yyyy-MM-dd` olarak biçimlendirir.
  /// {@endtemplate}
  String _toDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// {@template admin_kpi_repository_as_int}
  /// SQLite sonucunu güvenli int’e çevirir.
  /// {@endtemplate}
  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// {@template admin_kpi_repository_as_double}
  /// SQLite SUM sonucunu güvenli double’a çevirir.
  /// {@endtemplate}
  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Pivot birleştirme biriktirici.
class _PivotAcc {
  int visitCount = 0;
  int collectionCount = 0;
  double collectionAmount = 0;
  double targetAmount = 0;
  double targetAchieved = 0;
}
