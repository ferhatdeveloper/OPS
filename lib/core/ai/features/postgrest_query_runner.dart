// Dosya Adı: postgrest_query_runner.dart
// Açıklama: Sanitize edilmiş PostgREST GET + SQLite allowlist fallback
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../service/database_service.dart';
import '../../tenant/postgrest_http_client.dart';
import '../../tenant/postgrest_table_names.dart';
import 'ai_chat_sqlite_runner.dart';
import 'postgrest_query_allowlist.dart';
import 'postgrest_query_sanitizer.dart';
import 'postgrest_query_spec.dart';

/// {@template postgrest_query_runner}
/// Merkez: [PostgrestHttpClient.getRows].
/// Yerel: SQLite `db.query` — serbest SQL string yok.
///
/// Önce PostgREST; hata / yapılandırma yok → SQLite fallback.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await PostgrestQueryRunner().run(spec);
/// ```
/// {@endtemplate}
class PostgrestQueryRunner {
  /// [client]: PostgREST HTTP
  final PostgrestHttpClient client;

  /// [sanitizer]: Allowlist
  final PostgrestQuerySanitizer sanitizer;

  /// [allowlist]: Tablo meta
  final PostgrestQueryAllowlist allowlist;

  /// [dbFactory]: SQLite açıcı (test inject)
  final Future<Database> Function()? dbFactory;

  /// [enableSqliteFallback]: Merkez fail → yerel
  final bool enableSqliteFallback;

  /// {@macro postgrest_query_runner}
  PostgrestQueryRunner({
    PostgrestHttpClient? client,
    PostgrestQuerySanitizer? sanitizer,
    PostgrestQueryAllowlist? allowlist,
    this.dbFactory,
    this.enableSqliteFallback = true,
  })  : allowlist = allowlist ?? PostgrestQueryAllowlist(),
        sanitizer = sanitizer ??
            PostgrestQuerySanitizer(
              allowlist: allowlist ?? PostgrestQueryAllowlist(),
            ),
        client = client ?? PostgrestHttpClient();

  /// PostgREST query map (test edilebilir)
  Map<String, String> buildQueryMap(PostgrestQuerySpec spec) {
    final q = <String, String>{};
    if (spec.select.isNotEmpty) {
      q['select'] = spec.select.join(',');
    }
    for (final f in spec.filters) {
      q[f.column] = '${f.op.wire}.${f.value}';
    }
    if (spec.order != null && spec.order!.isNotEmpty) {
      q['order'] = spec.order!;
    }
    if (spec.limit != null) {
      q['limit'] = '${spec.limit}';
    }
    return q;
  }

  /// Path: `/rex_{FF}_table` veya `/rpc/name`
  String buildPath(PostgrestQuerySpec spec) {
    if (spec.isRpc) return '/rpc/${spec.table}';
    final remote = _remoteTableName(spec.table);
    return '/$remote';
  }

  /// Allowlist mantıksal ad → RetailEX `rex_{FF}_*` (gerekirse dönem).
  String _remoteTableName(String logical) {
    final base = logical.trim();
    if (base.isEmpty) return base;
    // Zaten rex_ önekli ise dokunma
    if (base.startsWith('rex_')) return base;
    final periodBases = {'orders', 'invoices', 'collections', 'visits'};
    try {
      if (periodBases.contains(base)) {
        return client.postgres.getRexPeriodTable(base);
      }
      return client.postgres.getRexFirmTable(base);
    } catch (_) {
      return PostgrestTableNames.firmTable('001', base);
    }
  }

  /// {@template postgrest_query_runner_run}
  /// Sanitize + PostgREST GET; başarısızsa aynı allowlist ile SQLite.
  ///
  /// Parametreler:
  /// - [raw]: Spec
  /// - [reportTitle]: Yerel intent (ör. rut planı olmayan)
  ///
  /// Dönüş: satırlar; [PostgrestRunResult.usedLocal] true ise dens note.
  /// Ham SQL **yok**.
  /// {@endtemplate}
  Future<PostgrestRunResult> run(
    PostgrestQuerySpec raw, {
    String? reportTitle,
  }) async {
    final sanitized = sanitizer.sanitize(raw);
    if (!sanitized.ok || sanitized.spec == null) {
      return PostgrestRunResult.fail(
        sanitized.errorKey ?? 'field_sales.ai_reports.err_sanitize',
        sanitized.message,
      );
    }
    final spec = sanitized.spec!;
    final intent = LocalSqliteIntentDetect.fromTitle(reportTitle);

    if (client.isConfigured) {
      try {
        final rows = await client.getRows(
          buildPath(spec),
          query: buildQueryMap(spec),
        );
        return PostgrestRunResult.ok(rows, spec);
      } on PostgrestHttpException catch (e) {
        if (!enableSqliteFallback || spec.isRpc) {
          return PostgrestRunResult.fail(
            'field_sales.ai_reports.err_http',
            e.message,
          );
        }
        final local = await _runSqlite(spec, intent: intent);
        if (local != null) return local;
        return PostgrestRunResult.fail(
          'field_sales.ai_reports.err_http',
          e.message,
        );
      } catch (e) {
        if (!enableSqliteFallback || spec.isRpc) {
          return PostgrestRunResult.fail(
            'field_sales.ai_reports.err_http',
            e.toString(),
          );
        }
        final local = await _runSqlite(spec, intent: intent);
        if (local != null) return local;
        return PostgrestRunResult.fail(
          'field_sales.ai_reports.err_http',
          e.toString(),
        );
      }
    }

    // Merkez URL yok
    if (!enableSqliteFallback || spec.isRpc) {
      return PostgrestRunResult.fail(
        'field_sales.ai_reports.center_unavailable',
        'no postgrest url',
      );
    }
    final local = await _runSqlite(spec, intent: intent);
    if (local != null) return local;
    return PostgrestRunResult.fail(
      'field_sales.ai_reports.center_unavailable',
      'no postgrest url and sqlite failed',
    );
  }

  Future<PostgrestRunResult?> _runSqlite(
    PostgrestQuerySpec spec, {
    required LocalSqliteIntent intent,
  }) async {
    try {
      final db = dbFactory != null
          ? await dbFactory!()
          : await _defaultDb();
      final r = await AiChatSqliteRunner(
        db: db,
        allowlist: allowlist,
        sanitizer: sanitizer,
      ).run(spec, intent: intent);
      if (!r.ok) return null;
      // Preview kolonlarında id sızıntısını temizle (select’te yoksa)
      final rows = r.rows.map((row) {
        if (spec.select.contains('id')) return row;
        final m = Map<String, dynamic>.from(row);
        m.remove('id');
        return m;
      }).toList();
      return PostgrestRunResult.ok(
        rows,
        spec,
        usedLocal: true,
        noteKey: 'field_sales.ai_reports.local_sqlite_note',
        localFilterNoteKey: r.filterNoteKey,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Database> _defaultDb() async {
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }
}

/// {@template postgrest_run_result}
/// Runner sonucu.
/// {@endtemplate}
class PostgrestRunResult {
  /// [ok]
  final bool ok;

  /// [rows]
  final List<Map<String, dynamic>> rows;

  /// [spec]: Kullanılan temiz spec
  final PostgrestQuerySpec? spec;

  /// [errorKey]
  final String? errorKey;

  /// [message]
  final String? message;

  /// [usedLocal]: SQLite fallback
  final bool usedLocal;

  /// [noteKey]: Dens chip / not (ör. merkez yok)
  final String? noteKey;

  /// [localFilterNoteKey]: Özel filtre açıklaması
  final String? localFilterNoteKey;

  /// {@macro postgrest_run_result}
  const PostgrestRunResult({
    required this.ok,
    this.rows = const [],
    this.spec,
    this.errorKey,
    this.message,
    this.usedLocal = false,
    this.noteKey,
    this.localFilterNoteKey,
  });

  factory PostgrestRunResult.ok(
    List<Map<String, dynamic>> rows,
    PostgrestQuerySpec spec, {
    bool usedLocal = false,
    String? noteKey,
    String? localFilterNoteKey,
  }) =>
      PostgrestRunResult(
        ok: true,
        rows: rows,
        spec: spec,
        usedLocal: usedLocal,
        noteKey: noteKey,
        localFilterNoteKey: localFilterNoteKey,
      );

  factory PostgrestRunResult.fail(String errorKey, [String? message]) =>
      PostgrestRunResult(ok: false, errorKey: errorKey, message: message);
}
