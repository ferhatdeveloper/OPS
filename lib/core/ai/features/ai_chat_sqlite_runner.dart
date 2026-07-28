// Dosya Adı: ai_chat_sqlite_runner.dart
// Açıklama: Allowlist PostgREST spec → yerel SQLite db.query (ham SQL yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import 'postgrest_query_allowlist.dart';
import 'postgrest_query_sanitizer.dart';
import 'postgrest_query_spec.dart';

/// {@template local_sqlite_intent}
/// Yerel SQLite özel rapor niyeti (ham SQL değil; uygulama stratejisi).
/// {@endtemplate}
enum LocalSqliteIntent {
  /// Varsayılan allowlist query
  none,

  /// Rut / rota planında olmayan cariler
  customersWithoutRoute,
}

/// {@template local_sqlite_intent_detect}
/// Başlıktan yerel intent çıkarımı.
/// {@endtemplate}
class LocalSqliteIntentDetect {
  /// Türkçe / EN başlık heuristic
  static LocalSqliteIntent fromTitle(String? title) {
    final t = (title ?? '').toLowerCase().trim();
    if (t.isEmpty) return LocalSqliteIntent.none;
    final hasRut =
        t.contains('rut') || t.contains('rota') || t.contains('route');
    final without = t.contains('olmayan') ||
        t.contains('yok') ||
        t.contains('without') ||
        t.contains('no route') ||
        t.contains('not on');
    if (hasRut && without) {
      return LocalSqliteIntent.customersWithoutRoute;
    }
    return LocalSqliteIntent.none;
  }
}

/// {@template ai_chat_sqlite_run_result}
/// Yerel SQLite sorgu sonucu.
/// {@endtemplate}
class AiChatSqliteRunResult {
  /// [ok]
  final bool ok;

  /// [rows]
  final List<Map<String, dynamic>> rows;

  /// [table]: Kullanılan SQLite tablo
  final String? table;

  /// [errorKey]
  final String? errorKey;

  /// [message]
  final String? message;

  /// [filterNoteKey]: Özel filtre açıklaması (l10n)
  final String? filterNoteKey;

  /// {@macro ai_chat_sqlite_run_result}
  const AiChatSqliteRunResult({
    required this.ok,
    this.rows = const [],
    this.table,
    this.errorKey,
    this.message,
    this.filterNoteKey,
  });

  factory AiChatSqliteRunResult.ok(
    List<Map<String, dynamic>> rows, {
    String? table,
    String? filterNoteKey,
  }) =>
      AiChatSqliteRunResult(
        ok: true,
        rows: rows,
        table: table,
        filterNoteKey: filterNoteKey,
      );

  factory AiChatSqliteRunResult.fail(String errorKey, [String? message]) =>
      AiChatSqliteRunResult(ok: false, errorKey: errorKey, message: message);
}

/// {@template ai_chat_sqlite_runner}
/// Sanitize edilmiş [PostgrestQuerySpec] → `Database.query` (parametreli).
/// Serbest SQL string / execute yok.
///
/// Kullanım örneği:
/// ```dart
/// final r = await AiChatSqliteRunner(db).run(spec);
/// ```
/// {@endtemplate}
class AiChatSqliteRunner {
  /// [db]: Açık SQLite
  final Database db;

  /// [allowlist]
  final PostgrestQueryAllowlist allowlist;

  /// [sanitizer]
  final PostgrestQuerySanitizer sanitizer;

  /// {@macro ai_chat_sqlite_runner}
  AiChatSqliteRunner({
    required this.db,
    PostgrestQueryAllowlist? allowlist,
    PostgrestQuerySanitizer? sanitizer,
  })  : allowlist = allowlist ?? PostgrestQueryAllowlist(),
        sanitizer = sanitizer ??
            PostgrestQuerySanitizer(
              allowlist: allowlist ?? PostgrestQueryAllowlist(),
            );

  /// {@template ai_chat_sqlite_runner_run}
  /// Allowlist sanitize + yerel query.
  ///
  /// Parametreler:
  /// - [raw]: PostgREST spec
  /// - [intent]: Özel yerel strateji (ör. rutsuz cariler)
  /// {@endtemplate}
  Future<AiChatSqliteRunResult> run(
    PostgrestQuerySpec raw, {
    LocalSqliteIntent intent = LocalSqliteIntent.none,
  }) async {
    final sanitized = sanitizer.sanitize(raw);
    if (!sanitized.ok || sanitized.spec == null) {
      return AiChatSqliteRunResult.fail(
        sanitized.errorKey ?? 'field_sales.ai_reports.err_sanitize',
        sanitized.message,
      );
    }
    final spec = sanitized.spec!;
    if (spec.isRpc) {
      return AiChatSqliteRunResult.fail(
        'field_sales.ai_reports.err_sanitize',
        'rpc not supported on sqlite',
      );
    }
    final meta = allowlist.tableOf(spec.table);
    final local = meta?.localSqlite?.trim();
    if (local == null || local.isEmpty) {
      return AiChatSqliteRunResult.fail(
        'ai.chat_local_table_missing',
        'no localSqlite for ${spec.table}',
      );
    }

    if (intent == LocalSqliteIntent.customersWithoutRoute &&
        spec.table == 'customers') {
      return _runCustomersWithoutRoute(spec, meta!);
    }

    return _runPlain(spec, meta!, local);
  }

  Future<AiChatSqliteRunResult> _runPlain(
    PostgrestQuerySpec spec,
    PostgrestTableAllow meta,
    String local,
  ) async {
    final existing = await _existingColumns(local);
    final mapped = _mapSelect(spec.select, meta, existing);
    if (mapped.sqliteColumns.isEmpty) {
      return AiChatSqliteRunResult.fail(
        'field_sales.ai_reports.err_select',
        'no local columns',
      );
    }

    final whereParts = <String>[];
    final whereArgs = <Object?>[];
    for (final f in spec.filters) {
      final mappedF = _mapFilter(f, meta, existing);
      if (mappedF == null) continue;
      whereParts.add(mappedF.sql);
      whereArgs.addAll(mappedF.args);
    }

    String? orderBy;
    final order = (spec.order ?? '').trim();
    if (order.isNotEmpty) {
      final m = RegExp(r'^([a-zA-Z0-9_]+)\.(asc|desc)$', caseSensitive: false)
          .firstMatch(order);
      if (m != null) {
        final logical = m.group(1)!;
        final localCol = _resolveLocalColumn(logical, meta, existing);
        if (localCol != null &&
            (meta.columns.contains(logical.toLowerCase()) ||
                meta.columns.contains(logical))) {
          orderBy = '$localCol ${m.group(2)!.toUpperCase()}';
        }
      }
    }

    final limit = spec.limit ?? PostgrestQueryAllowlist.defaultLimit;
    final capped = limit.clamp(1, PostgrestQueryAllowlist.maxLimit);

    try {
      final rows = await db.query(
        local,
        columns: mapped.sqliteColumns,
        where: whereParts.isEmpty ? null : whereParts.join(' AND '),
        whereArgs: whereParts.isEmpty ? null : whereArgs,
        orderBy: orderBy,
        limit: capped,
      );
      return AiChatSqliteRunResult.ok(
        rows.map((e) => _projectRow(e, mapped)).toList(),
        table: local,
      );
    } catch (e) {
      return AiChatSqliteRunResult.fail(
        'ai.chat_local_query_failed',
        e.toString(),
      );
    }
  }

  /// Rut planında olmayan cariler — yalnız `db.query` + Dart filtre.
  Future<AiChatSqliteRunResult> _runCustomersWithoutRoute(
    PostgrestQuerySpec spec,
    PostgrestTableAllow meta,
  ) async {
    final selectWithId = spec.select.contains('id')
        ? spec.select
        : <String>['id', ...spec.select];
    final plain = await _runPlain(
      PostgrestQuerySpec(
        table: spec.table,
        select: selectWithId,
        filters: spec.filters,
        order: spec.order,
        limit: spec.limit,
      ),
      meta,
      meta.localSqlite!,
    );
    if (!plain.ok) return plain;

    Set<String>? routedIds;
    try {
      final activeRouteIds = <String>{};
      try {
        final routes = await db.query(
          'routes',
          columns: const ['id'],
          where: 'COALESCE(is_active, 1) = 1',
        );
        for (final r in routes) {
          final id = r['id']?.toString();
          if (id != null && id.isNotEmpty) activeRouteIds.add(id);
        }
      } catch (_) {}

      final rc = await db.query(
        'route_customers',
        columns: const ['customer_id', 'route_id'],
      );
      routedIds = <String>{};
      for (final row in rc) {
        final cid = row['customer_id']?.toString();
        if (cid == null || cid.isEmpty) continue;
        final rid = row['route_id']?.toString();
        if (activeRouteIds.isEmpty ||
            rid == null ||
            activeRouteIds.contains(rid)) {
          routedIds.add(cid);
        }
      }
    } catch (_) {
      routedIds = null;
    }

    List<Map<String, dynamic>> project(List<Map<String, dynamic>> rows) {
      if (spec.select.contains('id')) return rows;
      return rows
          .map((row) => Map<String, dynamic>.from(row)..remove('id'))
          .toList();
    }

    if (routedIds == null) {
      return AiChatSqliteRunResult.ok(
        project(plain.rows),
        table: plain.table,
        filterNoteKey:
            'field_sales.ai_reports.note_without_route_fallback',
      );
    }

    final filtered = plain.rows.where((row) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) return false;
      return !routedIds!.contains(id);
    }).toList();

    return AiChatSqliteRunResult.ok(
      project(filtered),
      table: plain.table,
      filterNoteKey: 'field_sales.ai_reports.note_without_route',
    );
  }

  Future<Set<String>> _existingColumns(String table) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      return info
          .map((r) => r['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  String? _resolveLocalColumn(
    String logical,
    PostgrestTableAllow meta,
    Set<String> existing,
  ) {
    final c = logical.trim();
    if (c.isEmpty || meta.localOmitColumns.contains(c)) return null;
    final alias = meta.localColumnAliases[c];
    if (existing.isEmpty) {
      return alias ?? c;
    }
    if (alias != null && existing.contains(alias)) return alias;
    if (existing.contains(c)) return c;
    if (alias != null) return alias;
    return null;
  }

  _SelectMap _mapSelect(
    List<String> select,
    PostgrestTableAllow meta,
    Set<String> existing,
  ) {
    final sqliteColumns = <String>[];
    final logicalBySqlite = <String, String>{};
    for (final logical in select) {
      final local = _resolveLocalColumn(logical, meta, existing);
      if (local == null) continue;
      if (!sqliteColumns.contains(local)) sqliteColumns.add(local);
      logicalBySqlite[local] = logical;
    }
    return _SelectMap(
      sqliteColumns: sqliteColumns,
      logicalBySqlite: logicalBySqlite,
    );
  }

  Map<String, dynamic> _projectRow(
    Map<String, Object?> row,
    _SelectMap mapped,
  ) {
    final out = <String, dynamic>{};
    for (final e in mapped.logicalBySqlite.entries) {
      out[e.value] = row[e.key];
    }
    if (row.containsKey('id') && !out.containsKey('id')) {
      out['id'] = row['id'];
    }
    return out;
  }

  _SqliteFilter? _mapFilter(
    PostgrestQueryFilter f,
    PostgrestTableAllow meta,
    Set<String> existing,
  ) {
    final logical = f.column.trim();
    if (logical.isEmpty) return null;
    final col = _resolveLocalColumn(logical, meta, existing);
    if (col == null) return null;
    switch (f.op) {
      case PostgrestFilterOp.eq:
        return _SqliteFilter('$col = ?', [f.value]);
      case PostgrestFilterOp.neq:
        return _SqliteFilter('$col != ?', [f.value]);
      case PostgrestFilterOp.gt:
        return _SqliteFilter('$col > ?', [f.value]);
      case PostgrestFilterOp.gte:
        return _SqliteFilter('$col >= ?', [f.value]);
      case PostgrestFilterOp.lt:
        return _SqliteFilter('$col < ?', [f.value]);
      case PostgrestFilterOp.lte:
        return _SqliteFilter('$col <= ?', [f.value]);
      case PostgrestFilterOp.like:
      case PostgrestFilterOp.ilike:
        final v = f.value.contains('%') ? f.value : '%${f.value}%';
        return _SqliteFilter('$col LIKE ?', [v]);
      case PostgrestFilterOp.isOp:
        final low = f.value.trim().toLowerCase();
        if (low == 'null') return _SqliteFilter('$col IS NULL', const []);
        if (low == 'true') return _SqliteFilter('$col = ?', [1]);
        if (low == 'false') return _SqliteFilter('$col = ?', [0]);
        return null;
      case PostgrestFilterOp.inOp:
        final parts = f.value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.isEmpty) return null;
        final marks = List.filled(parts.length, '?').join(',');
        return _SqliteFilter('$col IN ($marks)', parts);
    }
  }
}

class _SelectMap {
  final List<String> sqliteColumns;
  final Map<String, String> logicalBySqlite;
  const _SelectMap({
    required this.sqliteColumns,
    required this.logicalBySqlite,
  });
}

class _SqliteFilter {
  final String sql;
  final List<Object?> args;
  const _SqliteFilter(this.sql, this.args);
}
