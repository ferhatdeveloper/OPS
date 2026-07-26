// Dosya Adı: admin_kpi_repository.dart
// Açıklama: Yönetici KPI için SQLite COUNT aggregate okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/admin_kpi_summary.dart';

/// {@template admin_kpi_repository}
/// Yerel SQLite’tan günlük yönetici KPI sayılarını okur.
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
  /// Verilen güne (varsayılan: bugün) ait COUNT aggregate özetini döner.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [day]: Hedef gün (yalnızca tarih kısmı kullanılır)
  ///
  /// Dönüş değeri:
  /// - [AdminKpiSummary]: Sipariş / fatura / tahsilat / ziyaret sayıları
  /// {@endtemplate}
  Future<AdminKpiSummary> fetchToday(
    Database db, {
    DateTime? day,
  }) async {
    final target = day ?? DateTime.now();
    final dayKey = _toDateOnly(target);
    final rows = await db.rawQuery(
      SqlQuerys.adminKpiTodayCountsSql,
      [dayKey, dayKey, dayKey, dayKey],
    );
    if (rows.isEmpty) {
      return AdminKpiSummary.zero;
    }
    final row = rows.first;
    return AdminKpiSummary(
      orderCount: _asInt(row['order_count']),
      invoiceCount: _asInt(row['invoice_count']),
      collectionCount: _asInt(row['collection_count']),
      visitCount: _asInt(row['visit_count']),
    );
  }

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
  /// SQLite COUNT sonucunu güvenli int’e çevirir.
  /// {@endtemplate}
  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
