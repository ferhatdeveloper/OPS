// Dosya Adı: whms_order_kpi_store.dart
// Açıklama: WHMS emir KPI — SQLite COUNT/SUM aggregate (emir + sayım fark)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../model/whms_order_status.dart';
import '../../model/whms_orders_table.dart';
import '../model/whms_order_kpi_summary.dart';

/// {@template whms_order_kpi_store}
/// Emir / sayım fark KPI okuyucu — UI yazmaz.
///
/// Kullanım örneği:
/// ```dart
/// final kpi = await WhmsOrderKpiStore().loadSummary();
/// ```
/// {@endtemplate}
class WhmsOrderKpiStore {
  /// [openDb]: Test için DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro whms_order_kpi_store}
  const WhmsOrderKpiStore({this.openDb});

  static const String _countResultsTable = 'whms_count_results';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_order_kpi_store_ensure}
  /// Emir + sayım sonuç tablolarını hazırlar.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsOrdersTable);
    await db.execute(SqlQuerys.createWhmsOrderLinesTable);
    await db.execute(SqlQuerys.createWhmsCountResultsTable);
  }

  /// {@template whms_order_kpi_store_load}
  /// SQLite aggregate → [WhmsOrderKpiSummary].
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderKpiSummary]
  /// {@endtemplate}
  Future<WhmsOrderKpiSummary> loadSummary() async {
    await ensureReady();
    final db = await _db();

    final byStatus = await db.rawQuery(
      'SELECT status AS k, COUNT(*) AS c '
      'FROM ${WhmsOrdersTable.name} '
      'WHERE COALESCE(is_deleted, 0) = 0 '
      'GROUP BY status',
    );
    final statusMap = <String, int>{};
    for (final row in byStatus) {
      final key = (row['k']?.toString() ?? '').trim().toLowerCase();
      final c = (row['c'] as num?)?.toInt() ?? 0;
      if (key.isEmpty) continue;
      statusMap[key] = c;
    }

    final draft = statusMap['draft'] ?? 0;
    final assigned = statusMap['assigned'] ?? 0;
    final inProgress = statusMap['in_progress'] ?? 0;
    final done = (statusMap['done'] ?? 0) +
        (statusMap['completed'] ?? 0) +
        (statusMap['complete'] ?? 0);
    var total = 0;
    for (final v in statusMap.values) {
      total += v;
    }
    final open = draft + assigned + inProgress;

    final byType = await db.rawQuery(
      'SELECT order_type AS k, COUNT(*) AS c '
      'FROM ${WhmsOrdersTable.name} '
      'WHERE COALESCE(is_deleted, 0) = 0 '
      'GROUP BY order_type '
      'ORDER BY c DESC, k ASC',
    );
    final typeCounts = <WhmsOrderTypeCount>[];
    for (final row in byType) {
      final wire = (row['k']?.toString() ?? '').trim();
      final c = (row['c'] as num?)?.toInt() ?? 0;
      if (wire.isEmpty || c <= 0) continue;
      typeCounts.add(WhmsOrderTypeCount(typeWire: wire, count: c));
    }

    final varianceRows = await db.rawQuery(
      'SELECT COUNT(*) AS c, '
      'COALESCE(SUM(variance_qty), 0) AS vsum, '
      'COALESCE(SUM(ABS(variance_qty)), 0) AS vabs '
      'FROM $_countResultsTable '
      'WHERE COALESCE(is_deleted, 0) = 0',
    );
    final v = varianceRows.isEmpty
        ? <String, Object?>{}
        : varianceRows.first;

    return WhmsOrderKpiSummary(
      totalOrders: total,
      openOrders: open,
      completedOrders: done,
      draftOrders: draft,
      inProgressOrders: inProgress,
      typeCounts: typeCounts,
      countResultRows: (v['c'] as num?)?.toInt() ?? 0,
      countVarianceSum: (v['vsum'] as num?)?.toDouble() ?? 0,
      countVarianceAbsSum: (v['vabs'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Açık emir wire kodları (dokümantasyon / test).
  static List<String> get openStatusWires => [
        WhmsOrderStatus.draft.wireName,
        WhmsOrderStatus.assigned.wireName,
        WhmsOrderStatus.inProgress.wireName,
      ];
}
