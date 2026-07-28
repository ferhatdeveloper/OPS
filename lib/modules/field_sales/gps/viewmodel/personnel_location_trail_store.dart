// Dosya Adı: personnel_location_trail_store.dart
// Açıklama: Kişi bazlı GPS geçmiş trail — gps_logs + PostgREST/PG
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/tenant/postgrest_http_client.dart';
import '../../../../service/database_service.dart';
import '../../../../service/postgres_service.dart';
import '../model/gps_last_location_seed.dart';
import '../model/personnel_location_trail_point.dart';
import 'gps_last_location_store.dart';

/// {@template personnel_trail_period}
/// Trail dönem preset (Bugün / Bu Hafta dens chip).
/// {@endtemplate}
enum PersonnelTrailPeriod {
  /// Bugün
  today,

  /// Bu hafta (Pzt–Paz)
  thisWeek,
}

/// {@template personnel_location_trail_store}
/// Seçilen plasiyer + tarih aralığı için `gps_logs` trail yükler.
/// Önce uzak (PostgREST → PG), yoksa yerel SQLite.
///
/// Kullanım örneği:
/// ```dart
/// final pts = await PersonnelLocationTrailStore().loadTrail(
///   salespersonCode: 'PLS01',
///   start: DateTime(2026, 7, 28),
///   end: DateTime(2026, 7, 28),
/// );
/// ```
/// {@endtemplate}
class PersonnelLocationTrailStore {
  /// [openDb]: Test için enjekte DB
  final Future<Database> Function()? openDb;

  /// [local]: gps_logs şema / seed hazırlığı
  final GpsLastLocationStore local;

  /// [postgrest]: Opsiyonel REST
  final PostgrestHttpClient? postgrest;

  /// [postgresFactory]: Direkt PG (fallback)
  final Future<PostgresService> Function()? postgresFactory;

  /// {@macro personnel_location_trail_store}
  const PersonnelLocationTrailStore({
    this.openDb,
    this.local = const GpsLastLocationStore(),
    this.postgrest,
    this.postgresFactory,
  });

  /// [tableName]: SQLite tablo
  static const String tableName = GpsLastLocationSeed.tableName;

  /// {@template personnel_trail_range_for_period}
  /// Dönem → (başlangıç, bitiş) gün aralığı.
  ///
  /// Parametreler:
  /// - [period]: Bugün / Bu Hafta
  /// - [now]: Referans (test)
  ///
  /// Dönüş değeri:
  /// - [(DateTime, DateTime)]: Gün-only aralık
  /// {@endtemplate}
  static (DateTime, DateTime) rangeForPeriod(
    PersonnelTrailPeriod period, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (period) {
      case PersonnelTrailPeriod.today:
        return (today, today);
      case PersonnelTrailPeriod.thisWeek:
        final weekday = today.weekday;
        final start = today.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, end);
    }
  }

  /// Gün → `yyyy-MM-dd` (SQLite date()).
  static String formatDay(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return DateFormat('yyyy-MM-dd').format(day);
  }

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template personnel_location_trail_store_load}
  /// Kişi + tarih aralığı trail noktalarını yükler (kronolojik).
  ///
  /// Parametreler:
  /// - [salespersonCode]: Plasiyer kodu (zorunlu filtre)
  /// - [userId]: Uzak kaynak user_id (opsiyonel)
  /// - [start]: Başlangıç günü
  /// - [end]: Bitiş günü
  /// - [limit]: Maks nokta
  ///
  /// Dönüş değeri:
  /// - [List]: Sıralı trail noktaları
  /// {@endtemplate}
  Future<List<PersonnelLocationTrailPoint>> loadTrail({
    required String salespersonCode,
    String userId = '',
    required DateTime start,
    required DateTime end,
    int limit = 2000,
  }) async {
    final code = salespersonCode.trim();
    final uid = userId.trim();
    if (code.isEmpty && uid.isEmpty) {
      return const [];
    }

    final remote = await _tryRemote(
      salespersonCode: code,
      userId: uid,
      start: start,
      end: end,
      limit: limit,
    );
    if (remote.isNotEmpty) {
      return PersonnelLocationTrailPoint.mergeChronological(remote);
    }

    return loadTrailLocal(
      salespersonCode: code,
      userId: uid,
      start: start,
      end: end,
      limit: limit,
    );
  }

  /// Yalnızca yerel `gps_logs` (test / offline).
  Future<List<PersonnelLocationTrailPoint>> loadTrailLocal({
    required String salespersonCode,
    String userId = '',
    required DateTime start,
    required DateTime end,
    int limit = 2000,
  }) async {
    final code = salespersonCode.trim();
    final uid = userId.trim();
    if (code.isEmpty && uid.isEmpty) return const [];

    final ensure = GpsLastLocationStore(openDb: openDb ?? local.openDb);
    await ensure.ensureReady();
    final db = await _db();
    await db.execute(SqlQuerys.createGpsLogsTable);

    final from = formatDay(start);
    final to = formatDay(end);

    // salesperson_code eşleşmesi; kod boşsa userId ile label/id deneme yok —
    // yerel şemada user_id yok; kod veya kod=userId.
    final filterCode = code.isNotEmpty ? code : uid;

    final rows = await db.rawQuery(
      '''
      SELECT *
      FROM $tableName
      WHERE COALESCE(is_deleted, 0) = 0
        AND date(timestamp) >= date(?)
        AND date(timestamp) <= date(?)
        AND COALESCE(salesperson_code, '') = ?
      ORDER BY timestamp ASC
      LIMIT ?
      ''',
      [from, to, filterCode, limit],
    );

    final points = rows
        .map(PersonnelLocationTrailPoint.fromMap)
        .toList(growable: false);
    return PersonnelLocationTrailPoint.mergeChronological(points);
  }

  Future<List<PersonnelLocationTrailPoint>> _tryRemote({
    required String salespersonCode,
    required String userId,
    required DateTime start,
    required DateTime end,
    required int limit,
  }) async {
    final fromIso = DateTime(start.year, start.month, start.day)
        .toIso8601String();
    final toExclusive = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1));
    final toIso = toExclusive.toIso8601String();

    try {
      final client = postgrest ?? PostgrestHttpClient();
      if (client.isConfigured) {
        final query = <String, String>{
          'order': 'timestamp.asc',
          'limit': '$limit',
          'and':
              '(timestamp.gte.$fromIso,timestamp.lt.$toIso)',
        };
        if (salespersonCode.isNotEmpty) {
          query['salesperson_code'] = 'eq.$salespersonCode';
        } else if (userId.isNotEmpty) {
          query['user_id'] = 'eq.$userId';
        }
        final rows = await client.getRows('/gps_logs', query: query);
        if (rows.isNotEmpty) {
          return rows
              .map(PersonnelLocationTrailPoint.fromMap)
              .toList(growable: false);
        }
      }
    } catch (e) {
      debugPrint('PersonnelLocationTrailStore postgrest: $e');
    }

    try {
      final factory = postgresFactory ?? PostgresService.getInstance;
      final pg = await factory();
      final code = salespersonCode.isNotEmpty ? salespersonCode : userId;
      final rows = await pg.query(
        '''
        SELECT id, salesperson_code, user_id, latitude, longitude,
               timestamp, accuracy, label
        FROM gps_logs
        WHERE COALESCE(is_deleted, false) = false
          AND timestamp >= @from_ts
          AND timestamp < @to_ts
          AND (
            salesperson_code = @code
            OR CAST(user_id AS TEXT) = @code
          )
        ORDER BY timestamp ASC
        LIMIT @lim
        ''',
        params: {
          'from_ts': DateTime(start.year, start.month, start.day),
          'to_ts': toExclusive,
          'code': code,
          'lim': limit,
        },
      );
      return rows
          .map(PersonnelLocationTrailPoint.fromMap)
          .toList(growable: false);
    } catch (e) {
      debugPrint('PersonnelLocationTrailStore postgres: $e');
      return const [];
    }
  }
}
