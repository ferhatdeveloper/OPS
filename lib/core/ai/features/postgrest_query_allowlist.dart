// Dosya Adı: postgrest_query_allowlist.dart
// Açıklama: AI dinamik rapor read-only PostgREST tablo/kolon/rpc whitelist
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template postgrest_table_allow}
/// Tek allowlist tablo tanımı (merkez PostgREST + yerel SQLite eşlemesi).
/// {@endtemplate}
class PostgrestTableAllow {
  /// [name]: Mantıksal tablo adı (AI’nın ürettiği)
  final String name;

  /// [columns]: İzinli kolonlar
  final Set<String> columns;

  /// [localSqlite]: Offline fallback SQLite tablo adı (null → yok)
  final String? localSqlite;

  /// [localColumnAliases]: Mantıksal kolon → SQLite kolon (`city`→`il`)
  final Map<String, String> localColumnAliases;

  /// [localOmitColumns]: Yerel şemada olmayan mantıksal kolonlar
  final Set<String> localOmitColumns;

  /// {@macro postgrest_table_allow}
  const PostgrestTableAllow({
    required this.name,
    required this.columns,
    this.localSqlite,
    this.localColumnAliases = const {},
    this.localOmitColumns = const {},
  });

  /// Mantıksal kolon → yerel SQLite kolon (omit → null)
  String? localColumnFor(String logical) {
    final c = logical.trim();
    if (c.isEmpty || localOmitColumns.contains(c)) return null;
    return localColumnAliases[c] ?? c;
  }
}

/// {@template postgrest_query_allowlist}
/// Read-only whitelist. AI yalnızca bu kümeden seçer; uygulama sanitize eder.
///
/// **Ham SQL EXECUTE yok** — yalnız PostgREST GET veya SQLite `query()`.
/// {@endtemplate}
class PostgrestQueryAllowlist {
  /// Varsayılan saha satış okuma tabloları
  static const List<PostgrestTableAllow> defaultTables = [
    PostgrestTableAllow(
      name: 'customers',
      localSqlite: 'customers',
      columns: {
        'id',
        'code',
        'name',
        'balance',
        'phone',
        'city',
        'is_active',
        'salesperson_id',
        'created_at',
      },
      localColumnAliases: {'city': 'il'},
      localOmitColumns: {'salesperson_id'},
    ),
    PostgrestTableAllow(
      name: 'products',
      localSqlite: 'products',
      columns: {
        'id',
        'code',
        'name',
        'barcode',
        'unit',
        'price',
        'vat_rate',
        'stock_quantity',
        'category',
      },
    ),
    PostgrestTableAllow(
      name: 'orders',
      localSqlite: 'orders',
      columns: {
        'id',
        'customer_id',
        'order_date',
        'total_amount',
        'status',
        'notes',
        'created_at',
      },
    ),
    PostgrestTableAllow(
      name: 'invoices',
      localSqlite: 'invoices',
      columns: {
        'id',
        'customer_id',
        'invoice_date',
        'total_amount',
        'invoice_type',
        'status',
        'notes',
        'created_at',
      },
    ),
    PostgrestTableAllow(
      name: 'collections',
      localSqlite: 'collections',
      columns: {
        'id',
        'customer_id',
        'amount',
        'payment_type',
        'collection_date',
        'notes',
        'created_at',
      },
    ),
    PostgrestTableAllow(
      name: 'visits',
      localSqlite: 'visits',
      columns: {
        'id',
        'customer_id',
        'visit_date',
        'status',
        'notes',
        'created_at',
      },
    ),
  ];

  /// Read-only rpc (şu an boş — bilinçli)
  static const Set<String> readOnlyRpcs = {};

  /// Max limit
  static const int maxLimit = 500;

  /// Default limit
  static const int defaultLimit = 100;

  /// [tables]: Override edilebilir
  final Map<String, PostgrestTableAllow> tables;

  /// [rpcs]: Read-only rpc set
  final Set<String> rpcs;

  /// {@macro postgrest_query_allowlist}
  PostgrestQueryAllowlist({
    List<PostgrestTableAllow>? tableList,
    Set<String>? rpcs,
  })  : tables = {
          for (final t in (tableList ?? defaultTables)) t.name: t,
        },
        rpcs = rpcs ?? readOnlyRpcs;

  /// Tablo var mı
  PostgrestTableAllow? tableOf(String name) => tables[name.trim()];

  /// Rpc izinli mi
  bool isRpcAllowed(String name) => rpcs.contains(name.trim());

  /// Prompt’ta AI’ya verilen özet (PII yok)
  String promptCatalog() {
    final buf = StringBuffer();
    for (final t in tables.values) {
      buf.writeln('${t.name}: ${t.columns.join(', ')}');
    }
    if (rpcs.isNotEmpty) {
      buf.writeln('rpc (read-only): ${rpcs.join(', ')}');
    }
    return buf.toString();
  }
}
