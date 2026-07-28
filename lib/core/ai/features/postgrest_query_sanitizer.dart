// Dosya Adı: postgrest_query_sanitizer.dart
// Açıklama: AI PostgREST query spec sanitize — SQL injection / ham SQL engeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'postgrest_query_allowlist.dart';
import 'postgrest_query_spec.dart';

/// {@template postgrest_sanitize_result}
/// Sanitize sonucu.
/// {@endtemplate}
class PostgrestSanitizeResult {
  /// [ok]: Geçerli mi
  final bool ok;

  /// [spec]: Temizlenmiş spec (ok ise)
  final PostgrestQuerySpec? spec;

  /// [errorKey]: l10n hata anahtarı
  final String? errorKey;

  /// [message]: Geliştirici mesajı (log; UI’da key tercih)
  final String? message;

  /// {@macro postgrest_sanitize_result}
  const PostgrestSanitizeResult({
    required this.ok,
    this.spec,
    this.errorKey,
    this.message,
  });

  factory PostgrestSanitizeResult.success(PostgrestQuerySpec spec) =>
      PostgrestSanitizeResult(ok: true, spec: spec);

  factory PostgrestSanitizeResult.fail(String errorKey, [String? message]) =>
      PostgrestSanitizeResult(
        ok: false,
        errorKey: errorKey,
        message: message,
      );
}

/// {@template postgrest_query_sanitizer}
/// AI çıktısını allowlist’e göre temizler.
///
/// **ASLA** ham SQL string kabul etmez / üretmez.
/// Şüpheli `SELECT`, `;`, `--`, `/*` vb. reddedilir.
///
/// Kullanım örneği:
/// ```dart
/// final r = PostgrestQuerySanitizer().sanitize(rawSpec);
/// ```
/// {@endtemplate}
class PostgrestQuerySanitizer {
  /// [allowlist]: Whitelist
  final PostgrestQueryAllowlist allowlist;

  /// Güvenli tanımlayıcı: harf/rakam/_
  static final RegExp _ident = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  /// SQL benzeri yasak desenler
  static final RegExp _sqlSmell = RegExp(
    r"(;|--|/\*|\*/|\b(select|insert|update|delete|drop|alter|exec|execute|union|into)\b)",
    caseSensitive: false,
  );

  /// {@macro postgrest_query_sanitizer}
  PostgrestQuerySanitizer({PostgrestQueryAllowlist? allowlist})
      : allowlist = allowlist ?? PostgrestQueryAllowlist();

  /// {@template postgrest_query_sanitizer_sanitize}
  /// Spec’i temizle.
  ///
  /// Parametreler:
  /// - [raw]: AI / kullanıcı spec
  ///
  /// Dönüş değeri:
  /// - [PostgrestSanitizeResult]
  /// {@endtemplate}
  PostgrestSanitizeResult sanitize(PostgrestQuerySpec raw) {
    final tableName = raw.table.trim();
    if (tableName.isEmpty || !_ident.hasMatch(tableName)) {
      return PostgrestSanitizeResult.fail(
        'field_sales.ai_reports.err_table',
        'invalid table',
      );
    }
    if (_sqlSmell.hasMatch(tableName)) {
      return PostgrestSanitizeResult.fail(
        'field_sales.ai_reports.err_sql_forbidden',
        'sql smell in table',
      );
    }

    if (raw.isRpc) {
      if (!allowlist.isRpcAllowed(tableName)) {
        return PostgrestSanitizeResult.fail(
          'field_sales.ai_reports.err_rpc',
          'rpc not allowed',
        );
      }
      // rpc: select opsiyonel; filter allowlist yok — yalnız limit
      final limit = _clampLimit(raw.limit);
      return PostgrestSanitizeResult.success(
        PostgrestQuerySpec(
          table: tableName,
          select: const [],
          filters: const [],
          order: null,
          limit: limit,
          isRpc: true,
        ),
      );
    }

    final table = allowlist.tableOf(tableName);
    if (table == null) {
      return PostgrestSanitizeResult.fail(
        'field_sales.ai_reports.err_table',
        'table not in allowlist',
      );
    }

    final select = <String>[];
    for (final c in raw.select) {
      final col = c.trim();
      if (!_ident.hasMatch(col) || !table.columns.contains(col)) continue;
      if (!select.contains(col)) select.add(col);
    }
    if (select.isEmpty) {
      return PostgrestSanitizeResult.fail(
        'field_sales.ai_reports.err_select',
        'no valid columns',
      );
    }

    final filters = <PostgrestQueryFilter>[];
    for (final f in raw.filters) {
      final col = f.column.trim();
      if (!_ident.hasMatch(col) || !table.columns.contains(col)) continue;
      if (_sqlSmell.hasMatch(f.value)) continue;
      // Değer uzunluk sınırı
      if (f.value.length > 200) continue;
      filters.add(
        PostgrestQueryFilter(column: col, op: f.op, value: f.value),
      );
    }

    String? order;
    final rawOrder = (raw.order ?? '').trim();
    if (rawOrder.isNotEmpty) {
      final parts = rawOrder.split('.');
      if (parts.length == 2) {
        final col = parts[0].trim();
        final dir = parts[1].trim().toLowerCase();
        if (_ident.hasMatch(col) &&
            table.columns.contains(col) &&
            (dir == 'asc' || dir == 'desc')) {
          order = '$col.$dir';
        }
      }
    }

    return PostgrestSanitizeResult.success(
      PostgrestQuerySpec(
        table: table.name,
        select: select,
        filters: filters,
        order: order,
        limit: _clampLimit(raw.limit),
        isRpc: false,
      ),
    );
  }

  int _clampLimit(int? raw) {
    final n = raw ?? PostgrestQueryAllowlist.defaultLimit;
    if (n < 1) return PostgrestQueryAllowlist.defaultLimit;
    if (n > PostgrestQueryAllowlist.maxLimit) {
      return PostgrestQueryAllowlist.maxLimit;
    }
    return n;
  }
}
