// Dosya Adı: whms_order_kpi_store.dart
// Açıklama: whms_orders üzerinden dens KPI agregasyonu (SQLite)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../core/database/migrations/SqlQuerys.dart';
import '../../../service/database_service.dart';
import '../model/whms_order_status.dart';
import '../model/whms_order_type.dart';
import '../model/whms_orders_table.dart';
import 'whms_order_kpi.dart';

/// {@template whms_order_kpi_store}
/// Emir KPI okuyucu — ERP yok; yerel SQLite.
///
/// Kullanım örneği:
/// ```dart
/// final kpi = await WhmsOrderKpiStore().load();
/// ```
/// {@endtemplate}
class WhmsOrderKpiStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_order_kpi_store}
  const WhmsOrderKpiStore({this.openDb});

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloları hazırlar.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsOrdersTable);
    await db.execute(SqlQuerys.createWhmsOrderLinesTable);
  }

  /// {@template whms_order_kpi_store_load}
  /// Soft-delete edilmemiş emirlerden KPI üretir.
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderKpi]: Özet sayılar
  /// {@endtemplate}
  Future<WhmsOrderKpi> load() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      WhmsOrdersTable.name,
      columns: const <String>['order_type', 'status', 'ONAY'],
      where: 'COALESCE(is_deleted, 0) = 0',
    );

    final byType = <WhmsOrderType, int>{};
    final byStatus = <WhmsOrderStatus, int>{};
    var approved = 0;
    var pending = 0;
    var open = 0;
    var done = 0;

    for (final m in maps) {
      final type = WhmsOrderType.fromWire(m['order_type']?.toString());
      final status = WhmsOrderStatus.fromWire(m['status']?.toString());
      final onay = (m['ONAY'] as num?)?.toInt() ?? 0;

      byType[type] = (byType[type] ?? 0) + 1;
      byStatus[status] = (byStatus[status] ?? 0) + 1;

      if (onay == 1) {
        approved++;
      } else if (onay == 0) {
        pending++;
      }

      if (status == WhmsOrderStatus.done) {
        done++;
      } else if (!status.isTerminal) {
        open++;
      }
    }

    return WhmsOrderKpi(
      total: maps.length,
      byType: Map<WhmsOrderType, int>.unmodifiable(byType),
      byStatus: Map<WhmsOrderStatus, int>.unmodifiable(byStatus),
      approvedCount: approved,
      pendingApproval: pending,
      openCount: open,
      doneCount: done,
    );
  }
}
