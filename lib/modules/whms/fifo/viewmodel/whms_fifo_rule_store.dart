// Dosya Adı: whms_fifo_rule_store.dart
// Açıklama: whms_fifo_rules SQLite ensure / dens CRUD (upsert · soft delete)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../engine/whms_fifo_models.dart';

/// {@template whms_fifo_rule_store}
/// `whms_fifo_rules` tablo hazırlığı + listActive / upsert / softDelete /
/// ürün kodu ile motor kuralı okuma.
///
/// Kullanım örneği:
/// ```dart
/// final store = WhmsFifoRuleStore();
/// await store.ensureReady();
/// final rows = await store.listActive();
/// ```
/// {@endtemplate}
class WhmsFifoRuleStore {
  /// [openDb]: Test DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro whms_fifo_rule_store}
  const WhmsFifoRuleStore({this.openDb});

  /// [tableName]: SQLite tablo
  static const String tableName = 'whms_fifo_rules';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_fifo_rule_store_ensure}
  /// Tabloyu [SqlQuerys.createWhmsFifoRulesTable] ile hazırlar.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsFifoRulesTable);
  }

  /// {@template whms_fifo_rule_store_list}
  /// Aktif (silinmemiş) kurallar; opsiyonel FEFO enforce filtresi.
  ///
  /// Parametreler:
  /// - [fefoEnforceOnly]: true → yalnızca fefo_enforce=1
  ///
  /// Dönüş değeri:
  /// - [List<WhmsFifoRule>]: product_code ASC
  /// {@endtemplate}
  Future<List<WhmsFifoRule>> listActive({bool? fefoEnforceOnly}) async {
    await ensureReady();
    final db = await _db();
    final where = StringBuffer(
      'COALESCE(is_deleted, 0) = 0 AND COALESCE(is_active, 1) = 1',
    );
    final args = <Object>[];
    if (fefoEnforceOnly == true) {
      where.write(' AND COALESCE(fefo_enforce, 1) = 1');
    } else if (fefoEnforceOnly == false) {
      where.write(' AND COALESCE(fefo_enforce, 1) = 0');
    }
    final maps = await db.query(
      tableName,
      where: where.toString(),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'product_code ASC',
    );
    return maps
        .map((m) => WhmsFifoRule.fromMap(Map<String, Object?>.from(m)))
        .toList(growable: false);
  }

  /// {@template whms_fifo_rule_store_find}
  /// Ürün koduna göre aktif kural (motor / gate için).
  ///
  /// Parametreler:
  /// - [productCode]: Ürün kodu
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoRule]: Yoksa null
  /// {@endtemplate}
  Future<WhmsFifoRule?> findByProductCode(String productCode) async {
    await ensureReady();
    final db = await _db();
    return queryByProductCode(db, productCode: productCode);
  }

  /// {@template whms_fifo_rule_store_query}
  /// Transaction / gate ile aynı SQL — DBExecutor üzerinden okur.
  ///
  /// Parametreler:
  /// - [db]: SQLite executor
  /// - [productCode]: Ürün kodu
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoRule]: Yoksa null
  /// {@endtemplate}
  static Future<WhmsFifoRule?> queryByProductCode(
    DatabaseExecutor db, {
    required String productCode,
  }) async {
    final code = productCode.trim();
    if (code.isEmpty) return null;
    try {
      final rows = await db.query(
        tableName,
        where: 'product_code = ? AND COALESCE(is_deleted, 0) = 0 '
            'AND COALESCE(is_active, 1) = 1',
        whereArgs: <Object>[code],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return WhmsFifoRule.fromMap(Map<String, Object?>.from(rows.first));
    } catch (_) {
      return null;
    }
  }

  /// {@template whms_fifo_rule_store_upsert}
  /// id doluysa günceller; boşsa yeni satır. UNIQUE(product_code) replace.
  ///
  /// Parametreler:
  /// - [rule]: Zorunlu productCode
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoRule]: Kaydedilen satır
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: product_code boş
  /// {@endtemplate}
  Future<WhmsFifoRule> upsert(WhmsFifoRule rule) async {
    final code = rule.productCode.trim();
    if (code.isEmpty) {
      throw ArgumentError('product_code required');
    }

    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final id = rule.id.trim().isEmpty ? const Uuid().v4() : rule.id.trim();

    final row = WhmsFifoRule(
      id: id,
      productCode: code,
      fifoDays: rule.fifoDays < 0 ? 0 : rule.fifoDays,
      fefoEnforce: rule.fefoEnforce,
      warnDays: rule.warnDays < 0 ? 0 : rule.warnDays,
      isActive: rule.isActive,
      isDeleted: false,
      createdAt: rule.createdAt?.trim().isNotEmpty == true
          ? rule.createdAt
          : now,
      updatedAt: now,
    );

    await db.insert(
      tableName,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return row;
  }

  /// {@template whms_fifo_rule_store_soft_delete}
  /// Soft delete (`is_deleted=1`, `is_active=0`).
  /// {@endtemplate}
  Future<void> softDelete(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      tableName,
      <String, Object?>{
        'is_deleted': 1,
        'is_active': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object>[trimmed],
    );
  }
}
