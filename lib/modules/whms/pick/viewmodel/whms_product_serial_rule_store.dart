// Dosya Adı: whms_product_serial_rule_store.dart
// Açıklama: Ürün bazlı require_serial kuralı (products kolonu)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';

/// {@template whms_product_serial_rule_store}
/// Ürün `require_serial` bayrağı — pick seri zorunluluğu.
///
/// Kullanım örneği:
/// ```dart
/// final store = WhmsProductSerialRuleStore();
/// final ids = await store.productIdsRequiringSerial(['p1', 'p2']);
/// ```
/// {@endtemplate}
class WhmsProductSerialRuleStore {
  /// [openDb]: Test DB açıcı
  final Future<Database> Function()? openDb;

  /// [overrideRules]: Test — productId → zorunlu
  final Map<String, bool>? overrideRules;

  /// {@macro whms_product_serial_rule_store}
  const WhmsProductSerialRuleStore({
    this.openDb,
    this.overrideRules,
  });

  /// [colRequireSerial]: products sütunu
  static const String colRequireSerial = 'require_serial';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_product_serial_rule_ensure}
  /// `products.require_serial` kolonunu ekler (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    if (overrideRules != null) return;
    final db = await _db();
    try {
      final rows = await db.rawQuery('PRAGMA table_info(products)');
      final cols = rows
          .map((r) => r['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      if (cols.isEmpty || cols.contains(colRequireSerial)) return;
      await db.execute(
        'ALTER TABLE products ADD COLUMN $colRequireSerial '
        'INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {
      // Tablo yok / yarış — yoksay
    }
  }

  /// {@template whms_product_serial_rule_requires}
  /// Tek ürün seri zorunlu mu.
  /// {@endtemplate}
  Future<bool> requiresSerial(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return false;
    final ov = overrideRules;
    if (ov != null) return ov[id] ?? false;
    await ensureReady();
    final db = await _db();
    try {
      final maps = await db.query(
        'products',
        columns: <String>[colRequireSerial],
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (maps.isEmpty) return false;
      return (maps.first[colRequireSerial] as num?)?.toInt() == 1;
    } catch (_) {
      return false;
    }
  }

  /// {@template whms_product_serial_rule_ids}
  /// Verilen id’ler içinde seri zorunlu olanlar.
  /// {@endtemplate}
  Future<Set<String>> productIdsRequiringSerial(
    Iterable<String> productIds,
  ) async {
    final ids = productIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return <String>{};
    final ov = overrideRules;
    if (ov != null) {
      return ids.where((id) => ov[id] == true).toSet();
    }
    await ensureReady();
    final db = await _db();
    final out = <String>{};
    try {
      for (final id in ids) {
        final maps = await db.query(
          'products',
          columns: <String>['id', colRequireSerial],
          where: 'id = ?',
          whereArgs: <Object?>[id],
          limit: 1,
        );
        if (maps.isEmpty) continue;
        if ((maps.first[colRequireSerial] as num?)?.toInt() == 1) {
          out.add(id);
        }
      }
    } catch (_) {
      return <String>{};
    }
    return out;
  }
}
