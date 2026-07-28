// Dosya Adı: whms_load_fifo_gate.dart
// Açıklama: Load consume öncesi FIFO/FEFO allocate + çıkış kapısı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../contract/whms_bridge_dto.dart';
import '../fifo/viewmodel/whms_fifo_rule_store.dart';
import 'whms_fifo_rule_engine.dart';

/// {@template whms_load_fifo_gate}
/// Yükleme satırlarında [WhmsFifoRuleEngine.allocate] + checkOutbound.
/// Kural / lot yoksa geçiş (geri uyum).
///
/// Kullanım örneği:
/// ```dart
/// await WhmsLoadFifoGate.assertLinesAllowed(
///   db: txn,
///   lines: order.lines,
/// );
/// ```
/// {@endtemplate}
class WhmsLoadFifoGate {
  WhmsLoadFifoGate._();

  /// {@template whms_load_fifo_gate_assert}
  /// Her satır için FEFO tahsis; block / shortfall → StateError(messageKey).
  ///
  /// Parametreler:
  /// - [db]: SQLite (batch_expiry / whms_fifo_rules okuma)
  /// - [lines]: Yükleme satırları
  /// - [today]: Referans gün
  /// - [rulesByProductCode]: Test enjeksiyonu (opsiyonel)
  /// - [batchesByProductCode]: Test enjeksiyonu (opsiyonel)
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: `whms.fifo.*` messageKey
  /// {@endtemplate}
  static Future<void> assertLinesAllowed({
    required DatabaseExecutor db,
    required List<WhmsBridgeLine> lines,
    DateTime? today,
    Map<String, WhmsFifoRule>? rulesByProductCode,
    Map<String, List<WhmsFifoBatch>>? batchesByProductCode,
  }) async {
    final ref = WhmsFifoRuleEngine.dateOnly(today ?? DateTime.now());

    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final code = line.productCode.trim();
      final productId = line.productId.trim();
      if (code.isEmpty && productId.isEmpty) continue;

      final rule = rulesByProductCode?[code] ??
          await _loadRule(db, productCode: code);
      if (rule == null) continue;

      final batches = batchesByProductCode?[code] ??
          await _loadBatches(
            db,
            productCode: code,
            productId: productId,
          );

      final plan = WhmsFifoRuleEngine.allocate(
        qty: line.quantity,
        today: ref,
        rule: rule,
        availableBatches: batches,
      );

      if (!plan.isComplete) {
        throw StateError(plan.messageKey);
      }

      // Dilim yoksa (qty=0 zaten elendi) — outbound kapısı atlanır
      if (plan.slices.isEmpty) continue;

      final proposed = plan.slices.first.batch.expiry;
      final check = WhmsFifoRuleEngine.checkOutbound(
        productCode: code.isEmpty ? productId : code,
        proposedExpiry: proposed,
        today: ref,
        rule: rule,
        availableBatches: batches,
      );
      if (check.isBlocked) {
        throw StateError(check.messageKey);
      }
    }
  }

  static Future<WhmsFifoRule?> _loadRule(
    DatabaseExecutor db, {
    required String productCode,
  }) async {
    // CRUD store ile aynı sorgu (aktif + silinmemiş)
    return WhmsFifoRuleStore.queryByProductCode(
      db,
      productCode: productCode,
    );
  }

  static Future<List<WhmsFifoBatch>> _loadBatches(
    DatabaseExecutor db, {
    required String productCode,
    required String productId,
  }) async {
    try {
      final where = <String>['COALESCE(is_deleted, 0) = 0'];
      final args = <Object>[];
      if (productCode.isNotEmpty) {
        where.add('product_code = ?');
        args.add(productCode);
      } else if (productId.isNotEmpty) {
        where.add('product_id = ?');
        args.add(productId);
      } else {
        return const [];
      }

      final rows = await db.query(
        'batch_expiry',
        where: where.join(' AND '),
        whereArgs: args,
      );
      return rows
          .map(
            (m) => WhmsFifoBatch(
              lot: (m['lot_no'] ?? m['lot'] ?? '').toString(),
              expiry: DateTime.tryParse(
                (m['expiry_date'] ?? '').toString(),
              ),
              qty: (m['quantity'] as num?)?.toDouble() ?? 0,
            ),
          )
          .where((b) => b.qty > 0)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
