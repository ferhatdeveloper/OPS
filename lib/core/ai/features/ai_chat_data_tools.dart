// Dosya Adı: ai_chat_data_tools.dart
// Açıklama: Sesli sohbet için SQLite-öncelikli read-only veri araçları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../ai_prompt_sanitizer.dart';
import '../../../service/database_service.dart';
import 'ai_chat_reply_sanitizer.dart';
import 'ai_chat_sqlite_runner.dart';
import 'postgrest_query_allowlist.dart';
import 'postgrest_query_runner.dart';
import 'postgrest_query_spec.dart';

/// {@template ai_chat_data_tool_id}
/// Sabit sohbet veri araçları (read-only).
/// {@endtemplate}
enum AiChatDataToolId {
  /// Cari / müşteri arama
  customers,

  /// Son siparişler
  orders,

  /// Ürün / stok
  products,

  /// Ziyaretler
  visits,

  /// Tahsilat özeti
  collections,
}

/// {@template ai_chat_data_slice}
/// Tek araç sonucu.
/// {@endtemplate}
class AiChatDataSlice {
  /// [tool]
  final AiChatDataToolId tool;

  /// [source]: sqlite | postgrest | empty
  final String source;

  /// [rows]
  final List<Map<String, dynamic>> rows;

  /// {@macro ai_chat_data_slice}
  const AiChatDataSlice({
    required this.tool,
    required this.source,
    this.rows = const [],
  });
}

/// {@template ai_chat_data_bundle}
/// Ajan bağlam paketi — SQLite önce, PostgREST opsiyonel zenginleştirme.
/// {@endtemplate}
class AiChatDataBundle {
  /// [slices]
  final List<AiChatDataSlice> slices;

  /// [usedLocal]: En az bir SQLite satırı
  final bool usedLocal;

  /// [usedCenter]: En az bir PostgREST satırı
  final bool usedCenter;

  /// [centerUnavailable]: Merkez yok/hata (yerel ile devam)
  final bool centerUnavailable;

  /// {@macro ai_chat_data_bundle}
  const AiChatDataBundle({
    this.slices = const [],
    this.usedLocal = false,
    this.usedCenter = false,
    this.centerUnavailable = false,
  });

  /// Kullanıcıya dens chip için l10n key (null = gösterme)
  String? get sourceNoteKey {
    if (centerUnavailable && usedLocal) {
      return 'ai.chat_local_only_note';
    }
    if (!usedLocal && !usedCenter) {
      return 'ai.chat_no_local_data';
    }
    return null;
  }

  /// Prompt’a eklenecek veri bloğu (telefon/e-posta sanitize; ticari ad korunur)
  String toPromptBlock({int maxRowsPerTool = 12}) {
    if (slices.every((s) => s.rows.isEmpty)) {
      return 'VERİ: Yerel SQLite ve merkezde ilgili kayıt bulunamadı. '
          'Uydurma rakam/isim verme; kullanıcıya veri olmadığını söyle.';
    }
    final buf = StringBuffer();
    buf.writeln('VERİ KAYNAĞI: '
        '${usedLocal ? "SQLite yerel" : ""}'
        '${usedLocal && usedCenter ? " + " : ""}'
        '${usedCenter ? "PostgREST merkez" : ""}'
        '${centerUnavailable && !usedCenter ? " (merkez yok/hata → yalnız yerel)" : ""}'
        '.');
    buf.writeln('Aşağıdaki satırlara dayan. Uydurma üretme.');
    buf.writeln(
      'KURAL: id / customer_id / ord_* / cust_* / uuid kullanıcıya YAZMA. '
      'Müşteri adı (customer_name/name), tutar, tarih ve DURUM anlat. '
      'Sesli okunacak gibi doğal cümle kur; teknik kod okuma.',
    );
    for (final s in slices) {
      if (s.rows.isEmpty) {
        buf.writeln('- ${s.tool.name}: (boş)');
        continue;
      }
      final take = s.rows.take(maxRowsPerTool).toList();
      final sanitized = take.map((r) {
        final slim = <String, dynamic>{};
        for (final e in AiChatReplySanitizer.slimRowForPrompt(r).entries) {
          final k = e.key.toLowerCase();
          // Telefon kolonunu prompt’a koyma
          if (k.contains('phone') || k.contains('tel') || k.contains('email')) {
            continue;
          }
          final v = e.value;
          if (v is String) {
            slim[e.key] = AiPromptSanitizer.sanitize(v);
            // sanitize kişi adını [NAME] yapabilir — ticari unvan için geri al
            if (slim[e.key] == '[NAME]' && v.trim().contains(' ')) {
              slim[e.key] = v.trim();
            }
          } else {
            slim[e.key] = v;
          }
        }
        return jsonEncode(slim);
      }).toList();
      buf.writeln(
        '- ${s.tool.name} [${s.source}] (${s.rows.length} satır, ilk ${take.length}):',
      );
      for (final line in sanitized) {
        buf.writeln('  $line');
      }
    }
    return buf.toString();
  }
}

/// {@template ai_chat_data_toolkit}
/// Soru metnine göre SQLite-öncelikli read-only araçlar.
/// PostgREST bağlanmasa bile yerel veri döner.
///
/// Kullanım örneği:
/// ```dart
/// final b = await AiChatDataToolkit().gather('Bugünkü siparişler');
/// ```
/// {@endtemplate}
class AiChatDataToolkit {
  /// [dbFactory]: Test inject
  final Future<Database> Function()? dbFactory;

  /// [centerRunner]: Opsiyonel merkez
  final PostgrestQueryRunner? centerRunner;

  /// [allowlist]
  final PostgrestQueryAllowlist allowlist;

  /// {@macro ai_chat_data_toolkit}
  AiChatDataToolkit({
    this.dbFactory,
    this.centerRunner,
    PostgrestQueryAllowlist? allowlist,
  }) : allowlist = allowlist ?? PostgrestQueryAllowlist();

  Future<Database> _db() async {
    final f = dbFactory;
    if (f != null) return f();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Anahtar kelimeden araç seçimi
  static List<AiChatDataToolId> selectTools(String question) {
    final q = question.toLowerCase();
    final selected = <AiChatDataToolId>{};

    bool hit(List<String> keys) => keys.any(q.contains);

    if (hit([
      'cari',
      'müşteri',
      'musteri',
      'borç',
      'borc',
      'bakiye',
      'customer',
    ])) {
      selected.add(AiChatDataToolId.customers);
    }
    if (hit(['sipariş', 'siparis', 'order', 'satış', 'satis'])) {
      selected.add(AiChatDataToolId.orders);
    }
    if (hit([
      'stok',
      'ürün',
      'urun',
      'product',
      'barkod',
      'malzeme',
      'fiyat',
    ])) {
      selected.add(AiChatDataToolId.products);
    }
    if (hit(['ziyaret', 'visit', 'rota', 'check-in', 'checkin'])) {
      selected.add(AiChatDataToolId.visits);
    }
    if (hit([
      'tahsilat',
      'ödeme',
      'odeme',
      'collection',
      'nakit',
      'çek',
      'cek',
      'senet',
    ])) {
      selected.add(AiChatDataToolId.collections);
    }

    // Genel soru → özet paket (öneri için)
    if (selected.isEmpty) {
      if (hit([
        'bugün',
        'bugun',
        'özet',
        'ozet',
        'rapor',
        'kaç',
        'kac',
        'ne kadar',
        'liste',
        'öner',
        'oner',
        'durum',
      ])) {
        selected.addAll([
          AiChatDataToolId.orders,
          AiChatDataToolId.visits,
          AiChatDataToolId.collections,
          AiChatDataToolId.products,
        ]);
      } else {
        // Her zaman en az bir yerel deneme: müşteri + sipariş özeti
        selected.addAll([
          AiChatDataToolId.customers,
          AiChatDataToolId.orders,
        ]);
      }
    }
    return selected.toList();
  }

  /// Soru içinden arama metni (cari/ürün kodu veya ad)
  static String? extractSearchTerm(String question) {
    final q = question.trim();
    // Tırnaklı ifade: "..." veya '...'
    final dq = RegExp('"([^"]{2,40})"').firstMatch(q);
    if (dq != null) return dq.group(1)!.trim();
    final sq = RegExp("'([^']{2,40})'").firstMatch(q);
    if (sq != null) return sq.group(1)!.trim();
    // Kod benzeri (ABC123 / 120.01)
    final code = RegExp(r'\b([A-ZÇĞİÖŞÜ0-9][A-ZÇĞİÖŞÜ0-9.\-_/]{2,24})\b')
        .firstMatch(q.toUpperCase());
    if (code != null) {
      final c = code.group(1)!;
      if (!RegExp(r'^(BUGUN|BUGÜN|SIPARIS|SİPARİŞ|STOK|CARI|CARİ)$')
          .hasMatch(c)) {
        return c;
      }
    }
    return null;
  }

  PostgrestQuerySpec _specFor(AiChatDataToolId tool, String? search) {
    switch (tool) {
      case AiChatDataToolId.customers:
        return PostgrestQuerySpec(
          table: 'customers',
          select: const [
            'id',
            'code',
            'name',
            'balance',
            'city',
            'is_active',
          ],
          filters: search == null || search.isEmpty
              ? const []
              : [
                  PostgrestQueryFilter(
                    column: 'name',
                    op: PostgrestFilterOp.ilike,
                    value: '%$search%',
                  ),
                ],
          order: 'name.asc',
          limit: 20,
        );
      case AiChatDataToolId.orders:
        return const PostgrestQuerySpec(
          table: 'orders',
          select: [
            'id',
            'customer_id',
            'order_date',
            'total_amount',
            'status',
            'created_at',
          ],
          order: 'created_at.desc',
          limit: 20,
        );
      case AiChatDataToolId.products:
        return PostgrestQuerySpec(
          table: 'products',
          select: const [
            'id',
            'code',
            'name',
            'unit',
            'price',
            'stock_quantity',
            'category',
          ],
          filters: search == null || search.isEmpty
              ? const []
              : [
                  PostgrestQueryFilter(
                    column: 'name',
                    op: PostgrestFilterOp.ilike,
                    value: '%$search%',
                  ),
                ],
          order: 'name.asc',
          limit: 20,
        );
      case AiChatDataToolId.visits:
        return const PostgrestQuerySpec(
          table: 'visits',
          select: [
            'id',
            'customer_id',
            'visit_date',
            'status',
            'created_at',
          ],
          order: 'created_at.desc',
          limit: 20,
        );
      case AiChatDataToolId.collections:
        return const PostgrestQuerySpec(
          table: 'collections',
          select: [
            'id',
            'customer_id',
            'amount',
            'payment_type',
            'collection_date',
            'created_at',
          ],
          order: 'created_at.desc',
          limit: 20,
        );
    }
  }

  /// {@template ai_chat_data_toolkit_gather}
  /// 1) SQLite her zaman 2) PostgREST varsa zenginleştir (hata → sessiz)
  /// {@endtemplate}
  Future<AiChatDataBundle> gather(String question) async {
    final tools = selectTools(question);
    final search = extractSearchTerm(question);
    final slices = <AiChatDataSlice>[];
    var usedLocal = false;
    var usedCenter = false;
    var centerUnavailable = false;

    Database? db;
    try {
      db = await _db();
    } catch (_) {
      db = null;
    }

    final runner = db == null
        ? null
        : AiChatSqliteRunner(db: db, allowlist: allowlist);
    final center = centerRunner ?? PostgrestQueryRunner(allowlist: allowlist);

    for (final tool in tools) {
      final spec = _specFor(tool, search);
      var rows = <Map<String, dynamic>>[];
      var source = 'empty';

      if (runner != null) {
        // Müşteri/ürün aramada name boşsa code ile de dene
        var local = await runner.run(spec);
        if ((!local.ok || local.rows.isEmpty) &&
            search != null &&
            search.isNotEmpty &&
            (tool == AiChatDataToolId.customers ||
                tool == AiChatDataToolId.products)) {
          local = await runner.run(
            PostgrestQuerySpec(
              table: spec.table,
              select: spec.select,
              filters: [
                PostgrestQueryFilter(
                  column: 'code',
                  op: PostgrestFilterOp.ilike,
                  value: '%$search%',
                ),
              ],
              order: spec.order,
              limit: spec.limit,
            ),
          );
        }
        if (local.ok && local.rows.isNotEmpty) {
          rows = local.rows;
          source = 'sqlite';
          usedLocal = true;
        }
      }

      // Merkez: yerel boşsa doldur; doluysa zenginleştirme (limit kadar ek)
      try {
        if (!center.client.isConfigured) {
          centerUnavailable = true;
        } else {
          final remote = await center.run(spec);
          if (!remote.ok) {
            centerUnavailable = true;
          } else if (remote.rows.isNotEmpty) {
            if (rows.isEmpty) {
              rows = remote.rows;
              source = 'postgrest';
              usedCenter = true;
            } else {
              // Yerel öncelikli; merkezden yeni id ekle
              final ids = rows
                  .map((r) => r['id']?.toString())
                  .whereType<String>()
                  .toSet();
              final extra = remote.rows
                  .where((r) => !ids.contains(r['id']?.toString()))
                  .take(8)
                  .toList();
              if (extra.isNotEmpty) {
                rows = [...rows, ...extra];
                source = 'sqlite+postgrest';
                usedCenter = true;
              }
            }
          }
        }
      } catch (_) {
        centerUnavailable = true;
      }

      if (db != null &&
          tool == AiChatDataToolId.orders &&
          rows.isNotEmpty) {
        rows = await _enrichOrdersWithCustomerNames(db, rows);
      }

      slices.add(AiChatDataSlice(tool: tool, source: source, rows: rows));
    }

    return AiChatDataBundle(
      slices: slices,
      usedLocal: usedLocal,
      usedCenter: usedCenter,
      centerUnavailable: centerUnavailable,
    );
  }

  /// Sipariş satırlarına müşteri adı ekle (klon ID yerine).
  Future<List<Map<String, dynamic>>> _enrichOrdersWithCustomerNames(
    Database db,
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = rows
        .map((r) => r['customer_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return rows;

    Map<String, Map<String, dynamic>> byId = {};
    try {
      final placeholders = List.filled(ids.length, '?').join(',');
      final custs = await db.query(
        'customers',
        columns: const ['id', 'code', 'name'],
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      byId = {
        for (final c in custs) c['id'].toString(): c,
      };
    } catch (_) {
      return rows;
    }

    return rows.map((r) {
      final copy = Map<String, dynamic>.from(r);
      final cid = copy['customer_id']?.toString();
      final c = cid == null ? null : byId[cid];
      if (c != null) {
        final name = c['name']?.toString().trim() ?? '';
        final code = c['code']?.toString().trim() ?? '';
        if (name.isNotEmpty) copy['customer_name'] = name;
        if (code.isNotEmpty) copy['customer_code'] = code;
      }
      return copy;
    }).toList();
  }
}
