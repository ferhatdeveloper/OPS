// Dosya Adı: postgrest_query_spec.dart
// Açıklama: AI dinamik rapor — PostgREST GET query spec (ham SQL YASAK)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template postgrest_filter_op}
/// PostgREST filter operatörleri (allowlist alt kümesi).
/// {@endtemplate}
enum PostgrestFilterOp {
  /// eq.
  eq,

  /// neq.
  neq,

  /// gt.
  gt,

  /// gte.
  gte,

  /// lt.
  lt,

  /// lte.
  lte,

  /// like. (değer uygulamada escape)
  like,

  /// ilike.
  ilike,

  /// is. (null / true / false)
  isOp,

  /// in. (virgülle ayrılmış)
  inOp,
}

/// {@template postgrest_filter_op_x}
/// Wire adı yardımcıları.
/// {@endtemplate}
extension PostgrestFilterOpX on PostgrestFilterOp {
  /// PostgREST query prefix (`eq`, `gte`, …)
  String get wire {
    switch (this) {
      case PostgrestFilterOp.eq:
        return 'eq';
      case PostgrestFilterOp.neq:
        return 'neq';
      case PostgrestFilterOp.gt:
        return 'gt';
      case PostgrestFilterOp.gte:
        return 'gte';
      case PostgrestFilterOp.lt:
        return 'lt';
      case PostgrestFilterOp.lte:
        return 'lte';
      case PostgrestFilterOp.like:
        return 'like';
      case PostgrestFilterOp.ilike:
        return 'ilike';
      case PostgrestFilterOp.isOp:
        return 'is';
      case PostgrestFilterOp.inOp:
        return 'in';
    }
  }

  /// Parse; bilinmeyen → null
  static PostgrestFilterOp? tryParse(String? raw) {
    final k = (raw ?? '').trim().toLowerCase();
    switch (k) {
      case 'eq':
        return PostgrestFilterOp.eq;
      case 'neq':
        return PostgrestFilterOp.neq;
      case 'gt':
        return PostgrestFilterOp.gt;
      case 'gte':
        return PostgrestFilterOp.gte;
      case 'lt':
        return PostgrestFilterOp.lt;
      case 'lte':
        return PostgrestFilterOp.lte;
      case 'like':
        return PostgrestFilterOp.like;
      case 'ilike':
        return PostgrestFilterOp.ilike;
      case 'is':
        return PostgrestFilterOp.isOp;
      case 'in':
        return PostgrestFilterOp.inOp;
      default:
        return null;
    }
  }
}

/// {@template postgrest_query_filter}
/// Tek kolon filtresi — değer parametre olarak taşınır; SQL birleştirilmez.
/// {@endtemplate}
class PostgrestQueryFilter {
  /// [column]: Allowlist kolon
  final String column;

  /// [op]: Operatör
  final PostgrestFilterOp op;

  /// [value]: Ham değer (string)
  final String value;

  /// {@macro postgrest_query_filter}
  const PostgrestQueryFilter({
    required this.column,
    required this.op,
    required this.value,
  });

  /// JSON
  Map<String, dynamic> toJson() => {
        'column': column,
        'op': op.wire,
        'value': value,
      };

  /// JSON → model
  factory PostgrestQueryFilter.fromJson(Map<String, dynamic> json) {
    final op = PostgrestFilterOpX.tryParse(json['op']?.toString()) ??
        PostgrestFilterOp.eq;
    return PostgrestQueryFilter(
      column: (json['column'] ?? '').toString().trim(),
      op: op,
      value: (json['value'] ?? '').toString(),
    );
  }
}

/// {@template postgrest_query_spec}
/// PostgREST `GET /table?select=…&…` spec.
///
/// **ÖNEMLİ:** Bu model ham SQL değildir. Uygulama yalnızca
/// [PostgrestHttpClient.getRows] ile çalıştırır. `db.execute(sql)` yasak.
///
/// Kullanım örneği:
/// ```dart
/// final spec = PostgrestQuerySpec(
///   table: 'customers',
///   select: ['code', 'name'],
///   limit: 100,
/// );
/// ```
/// {@endtemplate}
class PostgrestQuerySpec {
  /// [table]: Mantıksal tablo (allowlist base) veya rpc adı
  final String table;

  /// [select]: Kolon listesi
  final List<String> select;

  /// [filters]: Filtreler
  final List<PostgrestQueryFilter> filters;

  /// [order]: `col.asc` / `col.desc` (sanitize edilir)
  final String? order;

  /// [limit]: Satır üst sınırı
  final int? limit;

  /// [rpc]: true ise path `/rpc/{table}` — yalnız read-only whitelist
  final bool isRpc;

  /// {@macro postgrest_query_spec}
  const PostgrestQuerySpec({
    required this.table,
    required this.select,
    this.filters = const [],
    this.order,
    this.limit,
    this.isRpc = false,
  });

  /// JSON
  Map<String, dynamic> toJson() => {
        'table': table,
        'select': select,
        'filters': filters.map((f) => f.toJson()).toList(),
        if (order != null) 'order': order,
        if (limit != null) 'limit': limit,
        if (isRpc) 'rpc': true,
      };

  /// JSON → model
  factory PostgrestQuerySpec.fromJson(Map<String, dynamic> json) {
    final rawSelect = json['select'];
    final select = <String>[];
    if (rawSelect is List) {
      for (final e in rawSelect) {
        final s = e.toString().trim();
        if (s.isNotEmpty) select.add(s);
      }
    } else if (rawSelect is String) {
      for (final p in rawSelect.split(',')) {
        final s = p.trim();
        if (s.isNotEmpty) select.add(s);
      }
    }
    final rawFilters = json['filters'];
    final filters = <PostgrestQueryFilter>[];
    if (rawFilters is List) {
      for (final e in rawFilters) {
        if (e is Map<String, dynamic>) {
          filters.add(PostgrestQueryFilter.fromJson(e));
        } else if (e is Map) {
          filters.add(
            PostgrestQueryFilter.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final rpcFlag = json['rpc'] == true || json['isRpc'] == true;
    return PostgrestQuerySpec(
      table: (json['table'] ?? '').toString().trim(),
      select: select,
      filters: filters,
      order: json['order']?.toString(),
      limit: (json['limit'] is num)
          ? (json['limit'] as num).toInt()
          : int.tryParse('${json['limit'] ?? ''}'),
      isRpc: rpcFlag,
    );
  }
}

/// {@template ai_report_layout_column}
/// Dinamik rapor sonuç sütunu (layout).
/// {@endtemplate}
class AiReportLayoutColumn {
  /// [id]: Kolon id (= select alanı)
  final String id;

  /// [labelKey]: l10n veya düz etiket
  final String labelKey;

  /// [numeric]: Sayısal mı
  final bool numeric;

  /// {@macro ai_report_layout_column}
  const AiReportLayoutColumn({
    required this.id,
    required this.labelKey,
    this.numeric = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'labelKey': labelKey,
        'numeric': numeric,
      };

  factory AiReportLayoutColumn.fromJson(Map<String, dynamic> json) {
    return AiReportLayoutColumn(
      id: (json['id'] ?? '').toString().trim(),
      labelKey: (json['labelKey'] ?? json['id'] ?? '').toString().trim(),
      numeric: json['numeric'] == true,
    );
  }
}

/// {@template ai_report_proposal}
/// AI rapor önerisi — onaydan önce UI’da gösterilir; persist sonra.
/// {@endtemplate}
class AiReportProposal {
  /// [title]: Görünen başlık
  final String title;

  /// [titleKey]: Opsiyonel l10n key
  final String? titleKey;

  /// [query]: PostgREST spec (ham SQL değil)
  final PostgrestQuerySpec query;

  /// [columns]: Layout sütunları
  final List<AiReportLayoutColumn> columns;

  /// {@macro ai_report_proposal}
  const AiReportProposal({
    required this.title,
    this.titleKey,
    required this.query,
    required this.columns,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (titleKey != null) 'titleKey': titleKey,
        'query': query.toJson(),
        'columns': columns.map((c) => c.toJson()).toList(),
      };

  factory AiReportProposal.fromJson(Map<String, dynamic> json) {
    final qRaw = json['query'];
    final query = qRaw is Map<String, dynamic>
        ? PostgrestQuerySpec.fromJson(qRaw)
        : qRaw is Map
            ? PostgrestQuerySpec.fromJson(Map<String, dynamic>.from(qRaw))
            : const PostgrestQuerySpec(table: '', select: []);
    final cols = <AiReportLayoutColumn>[];
    final cRaw = json['columns'];
    if (cRaw is List) {
      for (final e in cRaw) {
        if (e is Map<String, dynamic>) {
          cols.add(AiReportLayoutColumn.fromJson(e));
        } else if (e is Map) {
          cols.add(AiReportLayoutColumn.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return AiReportProposal(
      title: (json['title'] ?? '').toString().trim(),
      titleKey: json['titleKey']?.toString(),
      query: query,
      columns: cols,
    );
  }
}
