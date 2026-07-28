// Dosya Adı: weekly_route_plan_store.dart
// Açıklama: Haftalık rota planı offline SQLite CRUD (routes + route_customers)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/weekly_route_distance.dart';
import '../model/weekly_route_stop.dart';
import '../model/weekly_route_weekday.dart';

/// {@template weekly_route_plan_store}
/// Gün + opsiyonel personel bazlı rota planını SQLite'ta tutar.
/// Paylaşılan plan: [salespersonId] null → `weekly-route-dow-N`.
/// Personel planı: `weekly-route-sp-{id}-dow-N`.
///
/// Kullanım örneği:
/// ```dart
/// final store = WeeklyRoutePlanStore(openDb: () async => db);
/// final stops = await store.loadStopsForDay(
///   WeeklyRouteWeekday.monday,
///   salespersonId: 'u1',
/// );
/// ```
/// {@endtemplate}
class WeeklyRoutePlanStore {
  /// [openDb]: SQLite bağlantısı
  final Future<Database> Function() openDb;

  /// [uuid]: Kimlik üretici (test enjeksiyonu)
  final Uuid uuid;

  /// {@macro weekly_route_plan_store}
  const WeeklyRoutePlanStore({
    required this.openDb,
    this.uuid = const Uuid(),
  });

  /// {@template weekly_route_plan_store_ensure}
  /// routes / route_customers tablolarını oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await openDb();
    await db.execute(SqlQuerys.createRoutesTable);
    await db.execute(SqlQuerys.createRouteCustomersTable);
  }

  String? _normSalespersonId(String? salespersonId) {
    final sp = salespersonId?.trim() ?? '';
    return sp.isEmpty ? null : sp;
  }

  /// {@template weekly_route_plan_store_ensure_route}
  /// Verilen gün (+ opsiyonel personel) için kararlı rota satırını oluşturur.
  ///
  /// Parametreler:
  /// - [weekday]: 1–7 gün
  /// - [salespersonId]: Personel kapsamı (null = paylaşılan plan)
  ///
  /// Dönüş değeri:
  /// - [String]: routes.id
  /// {@endtemplate}
  Future<String> ensureRouteForDay(
    WeeklyRouteWeekday weekday, {
    String? salespersonId,
  }) async {
    await ensureReady();
    final db = await openDb();
    final sp = _normSalespersonId(salespersonId);
    final routeId = weekday.stableRouteId(salespersonId: sp);

    final existing = await db.query(
      'routes',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [routeId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'routes',
        {
          'day_of_week': weekday.dayOfWeek,
          'is_active': 1,
          'salesperson_id': sp,
        },
        where: 'id = ?',
        whereArgs: [routeId],
      );
      return routeId;
    }

    // Eski / seed: yalnızca paylaşılan planda gün eşleşmesi
    if (sp == null) {
      final byDay = await db.query(
        'routes',
        columns: ['id'],
        where: 'is_active = 1 AND day_of_week = ? AND '
            '(salesperson_id IS NULL OR TRIM(salesperson_id) = \'\')',
        whereArgs: [weekday.dayOfWeek],
        orderBy: 'created_at ASC',
        limit: 1,
      );
      if (byDay.isNotEmpty) {
        return byDay.first['id'] as String;
      }
    }

    final now = DateTime.now().toIso8601String();
    await db.insert('routes', {
      'id': routeId,
      'name': weekday.defaultRouteName,
      'salesperson_id': sp,
      'day_of_week': weekday.dayOfWeek,
      'is_active': 1,
      'is_synced': 0,
      'created_at': now,
    });
    return routeId;
  }

  /// {@template weekly_route_plan_store_load_stops}
  /// Günün (personel kapsamlı) duraklarını ziyaret sırasına göre yükler.
  ///
  /// Parametreler:
  /// - [weekday]: Hedef gün
  /// - [salespersonId]: Personel; null = paylaşılan plan
  ///
  /// Dönüş değeri:
  /// - [List<WeeklyRouteStop>]: Dens duraklar
  /// {@endtemplate}
  Future<List<WeeklyRouteStop>> loadStopsForDay(
    WeeklyRouteWeekday weekday, {
    String? salespersonId,
  }) async {
    final routeId = await ensureRouteForDay(
      weekday,
      salespersonId: salespersonId,
    );
    final db = await openDb();
    final maps = await db.rawQuery(
      SqlQuerys.weeklyRouteStopsByRouteIdSql,
      [routeId],
    );
    return maps.map(WeeklyRouteStop.fromMap).toList(growable: false);
  }

  /// {@template weekly_route_plan_store_load_today}
  /// Bugünün (cihaz saati) rota duraklarını yükler.
  ///
  /// Parametreler:
  /// - [now]: Opsiyonel saat (test)
  /// - [salespersonId]: Personel kapsamı
  ///
  /// Dönüş değeri:
  /// - [List<WeeklyRouteStop>]: Bugünkü plan
  /// {@endtemplate}
  Future<List<WeeklyRouteStop>> loadTodaysStops({
    DateTime? now,
    String? salespersonId,
  }) async {
    final weekday = WeeklyRouteWeekday.fromDateTime(now ?? DateTime.now());
    return loadStopsForDay(weekday, salespersonId: salespersonId);
  }

  /// {@template weekly_route_plan_store_list_salespersons}
  /// Aktif kullanıcıları personel seçici için listeler.
  ///
  /// Dönüş değeri:
  /// - [List<WeeklyRouteSalesperson>]: Personel satırları
  /// {@endtemplate}
  Future<List<WeeklyRouteSalesperson>> listSalespersons() async {
    await ensureReady();
    final db = await openDb();
    try {
      final rows = await db.rawQuery(SqlQuerys.weeklyRouteSalespersonsSql);
      return rows
          .map(WeeklyRouteSalesperson.fromMap)
          .where((s) => s.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      // users tablosu henüz yoksa boş liste
      return const [];
    }
  }

  /// {@template weekly_route_plan_store_search_customers}
  /// Cari seçici — kod/ünvan arama.
  ///
  /// Parametreler:
  /// - [query]: Arama metni
  /// - [excludeCustomerIds]: Zaten plandaki cariler
  /// - [limit]: Üst sınır
  ///
  /// Dönüş değeri:
  /// - [List<WeeklyRouteCustomerPick>]: Aday cariler
  /// {@endtemplate}
  Future<List<WeeklyRouteCustomerPick>> searchCustomers({
    String query = '',
    Set<String> excludeCustomerIds = const {},
    int limit = 40,
  }) async {
    await ensureReady();
    final db = await openDb();
    final q = query.trim();
    final rows = q.isEmpty
        ? await db.query(
            'customers',
            columns: ['id', 'code', 'name', 'address'],
            where: 'COALESCE(is_active, 1) = 1',
            orderBy: 'name COLLATE NOCASE ASC',
            limit: limit * 2,
          )
        : await db.query(
            'customers',
            columns: ['id', 'code', 'name', 'address'],
            where: 'COALESCE(is_active, 1) = 1 AND '
                '(code LIKE ? OR name LIKE ? OR address LIKE ?)',
            whereArgs: ['%$q%', '%$q%', '%$q%'],
            orderBy: 'name COLLATE NOCASE ASC',
            limit: limit * 2,
          );

    final picks = <WeeklyRouteCustomerPick>[];
    for (final row in rows) {
      final id = row['id'] as String? ?? '';
      if (id.isEmpty || excludeCustomerIds.contains(id)) continue;
      picks.add(WeeklyRouteCustomerPick.fromMap(row));
      if (picks.length >= limit) break;
    }
    return picks;
  }

  /// {@template weekly_route_plan_store_add_stop}
  /// Güne cari ekler (son sıraya).
  ///
  /// Parametreler:
  /// - [weekday]: Gün
  /// - [customerId]: Cari id
  /// - [isMandatory]: Zorunlu mu
  /// - [salespersonId]: Personel kapsamı
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteStop?]: Eklenen durak (zaten varsa null)
  /// {@endtemplate}
  Future<WeeklyRouteStop?> addStop({
    required WeeklyRouteWeekday weekday,
    required String customerId,
    bool isMandatory = true,
    String? salespersonId,
  }) async {
    final trimmed = customerId.trim();
    if (trimmed.isEmpty) return null;

    final routeId = await ensureRouteForDay(
      weekday,
      salespersonId: salespersonId,
    );
    final db = await openDb();

    final dup = await db.query(
      'route_customers',
      columns: ['id'],
      where: 'route_id = ? AND customer_id = ?',
      whereArgs: [routeId, trimmed],
      limit: 1,
    );
    if (dup.isNotEmpty) return null;

    final orderRows = await db.rawQuery(
      'SELECT MAX(visit_order) AS mx FROM route_customers WHERE route_id = ?',
      [routeId],
    );
    final maxOrder = (orderRows.first['mx'] as num?)?.toInt() ?? 0;
    final nextOrder = maxOrder + 1;
    final id = uuid.v4();

    await db.insert('route_customers', {
      'id': id,
      'route_id': routeId,
      'customer_id': trimmed,
      'visit_order': nextOrder,
      'is_mandatory': isMandatory ? 1 : 0,
    });

    final stops = await loadStopsForDay(
      weekday,
      salespersonId: salespersonId,
    );
    for (final stop in stops) {
      if (stop.id == id) return stop;
    }
    return null;
  }

  /// {@template weekly_route_plan_store_remove_stop}
  /// Durağı plandan çıkarır ve sırayı yeniden numaralandırır.
  ///
  /// Parametreler:
  /// - [weekday]: Gün
  /// - [stopId]: route_customers.id
  /// - [salespersonId]: Personel kapsamı
  /// {@endtemplate}
  Future<void> removeStop({
    required WeeklyRouteWeekday weekday,
    required String stopId,
    String? salespersonId,
  }) async {
    final routeId = await ensureRouteForDay(
      weekday,
      salespersonId: salespersonId,
    );
    final db = await openDb();
    await db.delete(
      'route_customers',
      where: 'id = ? AND route_id = ?',
      whereArgs: [stopId, routeId],
    );
    await _renumber(db, routeId);
  }

  /// {@template weekly_route_plan_store_move_stop}
  /// Durak sırasını bir yukarı / aşağı kaydırır.
  ///
  /// Parametreler:
  /// - [weekday]: Gün
  /// - [stopId]: Durak id
  /// - [delta]: -1 yukarı, +1 aşağı
  /// - [salespersonId]: Personel kapsamı
  /// {@endtemplate}
  Future<void> moveStop({
    required WeeklyRouteWeekday weekday,
    required String stopId,
    required int delta,
    String? salespersonId,
  }) async {
    if (delta == 0) return;
    final stops = await loadStopsForDay(
      weekday,
      salespersonId: salespersonId,
    );
    final index = stops.indexWhere((s) => s.id == stopId);
    if (index < 0) return;
    final target = index + delta;
    if (target < 0 || target >= stops.length) return;

    final db = await openDb();
    final a = stops[index];
    final b = stops[target];
    await db.update(
      'route_customers',
      {'visit_order': b.visitOrder},
      where: 'id = ?',
      whereArgs: [a.id],
    );
    await db.update(
      'route_customers',
      {'visit_order': a.visitOrder},
      where: 'id = ?',
      whereArgs: [b.id],
    );
  }

  /// {@template weekly_route_plan_store_reorder_by_distance}
  /// Durakları origin'e göre en yakından en uzağa yeniden yazar (SQLite).
  /// Koordinatsız cariler sonda kalır.
  ///
  /// Varsayım: [origin] cihaz GPS veya test enjeksiyonu.
  /// Ambar şemasında lat/long yok.
  ///
  /// Parametreler:
  /// - [weekday]: Gün
  /// - [origin]: Başlangıç noktası
  /// - [salespersonId]: Personel kapsamı
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteDistanceSortResult]: Yeni sıra + eksik koordinat sayısı
  /// {@endtemplate}
  Future<WeeklyRouteDistanceSortResult> reorderStopsByDistance({
    required WeeklyRouteWeekday weekday,
    required WeeklyRouteGeoPoint origin,
    String? salespersonId,
  }) async {
    final routeId = await ensureRouteForDay(
      weekday,
      salespersonId: salespersonId,
    );
    final stops = await loadStopsForDay(
      weekday,
      salespersonId: salespersonId,
    );
    final result = WeeklyRouteDistance.sortNearestToFarthest(
      stops,
      origin: origin,
    );

    final db = await openDb();
    await db.transaction((txn) async {
      for (var i = 0; i < result.ordered.length; i++) {
        await txn.update(
          'route_customers',
          {'visit_order': i + 1},
          where: 'id = ? AND route_id = ?',
          whereArgs: [result.ordered[i].id, routeId],
        );
      }
    });

    final refreshed = await loadStopsForDay(
      weekday,
      salespersonId: salespersonId,
    );
    return WeeklyRouteDistanceSortResult(
      ordered: refreshed,
      missingCoordsCount: result.missingCoordsCount,
    );
  }

  /// {@template weekly_route_plan_store_load_customer_weekdays}
  /// Carinin haftalık rota planındaki ziyaret günlerini döner.
  ///
  /// Parametreler:
  /// - [customerId]: Cari id
  ///
  /// Dönüş değeri:
  /// - [Set<WeeklyRouteWeekday>]: Atanmış günler
  /// {@endtemplate}
  Future<Set<WeeklyRouteWeekday>> loadWeekdaysForCustomer(
    String customerId,
  ) async {
    final trimmed = customerId.trim();
    if (trimmed.isEmpty) return const {};

    await ensureReady();
    final db = await openDb();
    final rows = await db.rawQuery(
      SqlQuerys.weeklyRouteCustomerWeekdaysSql,
      [trimmed],
    );
    final days = <WeeklyRouteWeekday>{};
    for (final row in rows) {
      final parsed = WeeklyRouteWeekday.tryParse(
        (row['day_of_week'] as num?)?.toInt(),
      );
      if (parsed != null) days.add(parsed);
    }
    return days;
  }

  /// {@template weekly_route_plan_store_set_customer_weekdays}
  /// Carinin ziyaret günlerini paylaşılan rota planına yazar (tek kaynak).
  /// Eksik günlere ekler, fazla günlerden çıkarır.
  ///
  /// Parametreler:
  /// - [customerId]: Cari id
  /// - [weekdays]: Hedef gün seti (Pzt–Paz)
  /// {@endtemplate}
  Future<void> setCustomerWeekdays({
    required String customerId,
    required Set<WeeklyRouteWeekday> weekdays,
  }) async {
    final trimmed = customerId.trim();
    if (trimmed.isEmpty) return;

    final target = <int>{};
    for (final day in weekdays) {
      if (day.dayOfWeek >= 1 && day.dayOfWeek <= 7) {
        target.add(day.dayOfWeek);
      }
    }

    final current = await loadWeekdaysForCustomer(trimmed);
    final currentIds = current.map((d) => d.dayOfWeek).toSet();

    for (final day in target.difference(currentIds)) {
      await addStop(
        weekday: WeeklyRouteWeekday(day),
        customerId: trimmed,
      );
    }

    for (final day in currentIds.difference(target)) {
      final weekday = WeeklyRouteWeekday(day);
      final stops = await loadStopsForDay(weekday);
      for (final stop in stops) {
        if (stop.customerId == trimmed) {
          await removeStop(weekday: weekday, stopId: stop.id);
        }
      }
    }
  }

  /// {@template weekly_route_plan_store_toggle_customer_weekday}
  /// Tek günü aç/kapa (cari detay dens chip) — paylaşılan plan.
  ///
  /// Parametreler:
  /// - [customerId]: Cari id
  /// - [weekday]: Gün
  /// - [selected]: true = ekle, false = çıkar
  /// {@endtemplate}
  Future<void> toggleCustomerWeekday({
    required String customerId,
    required WeeklyRouteWeekday weekday,
    required bool selected,
  }) async {
    final trimmed = customerId.trim();
    if (trimmed.isEmpty) return;

    if (selected) {
      await addStop(weekday: weekday, customerId: trimmed);
      return;
    }

    final stops = await loadStopsForDay(weekday);
    for (final stop in stops) {
      if (stop.customerId == trimmed) {
        await removeStop(weekday: weekday, stopId: stop.id);
      }
    }
  }

  /// {@template weekly_route_plan_store_customer_ids_for_day}
  /// Günün rota planındaki cari id seti (liste filtresi).
  ///
  /// Parametreler:
  /// - [weekday]: Hedef gün
  ///
  /// Dönüş değeri:
  /// - [Set<String>]: Cari id'ler
  /// {@endtemplate}
  Future<Set<String>> loadCustomerIdsForDay(
    WeeklyRouteWeekday weekday,
  ) async {
    await ensureReady();
    final db = await openDb();
    final rows = await db.rawQuery(
      SqlQuerys.weeklyRouteCustomerIdsForDaySql,
      [weekday.dayOfWeek],
    );
    final ids = <String>{};
    for (final row in rows) {
      final id = (row['customer_id'] as String?)?.trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  /// {@template weekly_route_plan_store_filter_customers}
  /// Cari listesini gün planına göre filtreler.
  /// [routeCustomerIds] null ise tüm cariler (Tüm günler sekmesi).
  ///
  /// Parametreler:
  /// - [customers]: Kaynak liste
  /// - [idOf]: Id seçici
  /// - [routeCustomerIds]: Günün planındaki id'ler; null = filtre yok
  ///
  /// Dönüş değeri:
  /// - [List<T>]: Filtrelenmiş liste
  /// {@endtemplate}
  static List<T> filterCustomersByRouteDay<T>({
    required List<T> customers,
    required String Function(T item) idOf,
    Set<String>? routeCustomerIds,
  }) {
    if (routeCustomerIds == null) return List<T>.from(customers);
    return customers
        .where((c) => routeCustomerIds.contains(idOf(c)))
        .toList(growable: false);
  }

  Future<void> _renumber(Database db, String routeId) async {
    final rows = await db.query(
      'route_customers',
      columns: ['id'],
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'visit_order ASC, id ASC',
    );
    for (var i = 0; i < rows.length; i++) {
      await db.update(
        'route_customers',
        {'visit_order': i + 1},
        where: 'id = ?',
        whereArgs: [rows[i]['id']],
      );
    }
  }
}
