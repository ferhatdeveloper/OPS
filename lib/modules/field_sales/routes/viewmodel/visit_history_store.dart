// Dosya Adı: visit_history_store.dart
// Açıklama: Geçmiş ziyaret dens liste + detay SQLite okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/visit_detail_record.dart';
import '../model/visit_history_record.dart';

/// {@template visit_history_period}
/// Geçmiş ziyaret dens dönem preset’i.
/// {@endtemplate}
enum VisitHistoryPeriod {
  /// Bugün
  today,

  /// Bu hafta
  thisWeek,

  /// Bu ay
  thisMonth,

  /// Bu yıl
  thisYear,
}

/// {@template visit_history_store}
/// `visits` tablosundan geçmiş ziyaret dens satır / detay okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = VisitHistoryStore(openDb: () async => db);
/// final rows = await store.loadFiltered(customerId: 'c1');
/// final detail = await store.loadDetail('v1');
/// ```
/// {@endtemplate}
class VisitHistoryStore {
  /// [openDb]: SQLite bağlantısı açıcı (test / üretim enjeksiyonu)
  final Future<Database> Function() openDb;

  /// {@macro visit_history_store}
  const VisitHistoryStore({required this.openDb});

  /// {@template visit_history_store_ensure}
  /// visits tablosunu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await openDb();
    await db.execute(SqlQuerys.createVisitsTable);
  }

  /// {@template visit_history_store_ymd}
  /// Gün-only `yyyy-MM-dd` metni.
  /// {@endtemplate}
  static String ymd(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return DateFormat('yyyy-MM-dd').format(day);
  }

  /// {@template visit_history_store_range_for_period}
  /// Dönem preset → (başlangıç, bitiş) gün aralığı (saf).
  ///
  /// Parametreler:
  /// - [period]: Dönem
  /// - [now]: Referans an (test enjeksiyonu)
  ///
  /// Dönüş değeri:
  /// - [(DateTime, DateTime)]: Başlangıç ve bitiş (gün-only)
  /// {@endtemplate}
  static (DateTime, DateTime) rangeForPeriod(
    VisitHistoryPeriod period, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (period) {
      case VisitHistoryPeriod.today:
        return (today, today);
      case VisitHistoryPeriod.thisWeek:
        final weekday = today.weekday;
        final start = today.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case VisitHistoryPeriod.thisMonth:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case VisitHistoryPeriod.thisYear:
        return (
          DateTime(today.year, 1, 1),
          DateTime(today.year, 12, 31),
        );
    }
  }

  /// {@template visit_history_store_format_gps}
  /// Dens GPS metni (lat, lng) veya boş/bilinmiyor.
  /// {@endtemplate}
  static String formatGps(
    double? lat,
    double? lng, {
    required String Function(String key, {Map<String, String>? args})
        translate,
  }) {
    if (lat == null || lng == null) {
      return translate('field_sales.visit_gps_unknown');
    }
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// {@template visit_history_store_format_date_time}
  /// Dens tarih-saat (dd.MM.yyyy HH:mm) veya bilinmiyor.
  /// {@endtemplate}
  static String formatDateTime(
    DateTime? value, {
    required String Function(String key, {Map<String, String>? args})
        translate,
  }) {
    if (value == null || value.millisecondsSinceEpoch == 0) {
      return translate('field_sales.visit_datetime_unknown');
    }
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }

  /// {@template visit_history_store_load_all}
  /// Tüm ziyaret dens satırları (yeniden eskiye).
  /// {@endtemplate}
  Future<List<VisitHistoryRecord>> loadAll() => loadFiltered();

  /// {@template visit_history_store_load_filtered}
  /// Cari ve/veya tarih aralığı ile dens satırları.
  ///
  /// Parametreler:
  /// - [customerId]: Opsiyonel cari filtresi
  /// - [start]: Opsiyonel başlangıç (gün)
  /// - [end]: Opsiyonel bitiş (gün)
  ///
  /// Dönüş değeri:
  /// - [List<VisitHistoryRecord>]: JOIN’li dens kayıtları
  /// {@endtemplate}
  Future<List<VisitHistoryRecord>> loadFiltered({
    String? customerId,
    DateTime? start,
    DateTime? end,
  }) async {
    await ensureReady();
    final db = await openDb();
    final where = <String>[];
    final args = <Object?>[];
    final cid = customerId?.trim() ?? '';
    if (cid.isNotEmpty) {
      where.add('v.customer_id = ?');
      args.add(cid);
    }
    if (start != null) {
      where.add('date(v.check_in_at) >= date(?)');
      args.add(ymd(start));
    }
    if (end != null) {
      where.add('date(v.check_in_at) <= date(?)');
      args.add(ymd(end));
    }
    final buffer = StringBuffer(SqlQuerys.visitHistorySelectSql);
    if (where.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(where.join(' AND '));
    }
    buffer.write(' ORDER BY v.check_in_at DESC, v.id ASC');
    final maps = await db.rawQuery(buffer.toString(), args);
    return maps
        .map(VisitHistoryRecord.fromMap)
        .toList(growable: false);
  }

  /// {@template visit_history_store_load_related_orders}
  /// Cari + gün aralığında ilişkili siparişler.
  /// {@endtemplate}
  Future<List<VisitRelatedOrder>> loadRelatedOrders({
    required String customerId,
    required DateTime start,
    required DateTime end,
  }) async {
    final cid = customerId.trim();
    if (cid.isEmpty) return const [];
    final db = await openDb();
    try {
      await db.execute(SqlQuerys.createOrdersTable);
    } catch (_) {
      // Tablo zaten var olabilir
    }
    final maps = await db.rawQuery(
      SqlQuerys.visitRelatedOrdersSql,
      [cid, ymd(start), ymd(end)],
    );
    return maps
        .map(VisitRelatedOrder.fromMap)
        .toList(growable: false);
  }

  /// {@template visit_history_store_load_detail}
  /// Tek ziyaret detayı + ilişkili siparişler.
  ///
  /// Parametreler:
  /// - [visitId]: visits.id
  ///
  /// Dönüş değeri:
  /// - [VisitDetailRecord?]: Bulunamazsa null
  /// {@endtemplate}
  Future<VisitDetailRecord?> loadDetail(String visitId) async {
    final id = visitId.trim();
    if (id.isEmpty) return null;
    await ensureReady();
    final db = await openDb();
    final maps = await db.rawQuery(SqlQuerys.visitDetailByIdSql, [id]);
    if (maps.isEmpty) return null;
    final detail = VisitDetailRecord.fromMap(maps.first);
    final endDay = detail.checkOutAt ?? detail.checkInAt;
    final orders = await loadRelatedOrders(
      customerId: detail.customerId,
      start: detail.checkInAt,
      end: endDay,
    );
    return detail.copyWithOrders(orders);
  }

  /// {@template visit_history_store_format_duration}
  /// Dens süre metni (dk / bilinmiyor).
  ///
  /// Parametreler:
  /// - [minutes]: Süre dakikası (null → bilinmiyor)
  /// - [translate]: l10n çevirici
  ///
  /// Dönüş değeri:
  /// - [String]: Dens süre etiketi
  /// {@endtemplate}
  static String formatDuration(
    int? minutes, {
    required String Function(String key, {Map<String, String>? args})
        translate,
  }) {
    if (minutes == null) {
      return translate('field_sales.visit_duration_unknown');
    }
    return translate(
      'field_sales.visit_duration_minutes',
      args: {'minutes': '$minutes'},
    );
  }
}
