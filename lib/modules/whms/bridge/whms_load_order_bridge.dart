// Dosya Adı: whms_load_order_bridge.dart
// Açıklama: Load emri store yazımı + FEFO allocate + store’dan consume
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../contract/whms_bridge_dto.dart';
import '../engine/whms_fifo_rule_engine.dart';
import '../engine/whms_load_order_consumer.dart';
import '../model/whms_order_dto.dart';
import '../model/whms_order_status.dart';
import '../model/whms_order_type.dart';
import '../shipping/whms_picking_control_engine.dart';
import '../viewmodel/whms_order_store.dart';
import 'whms_bridge_order_mapper.dart';

/// {@template whms_load_fifo_allocate_result}
/// Load satırı için FEFO plan özeti.
/// {@endtemplate}
class WhmsLoadFifoAllocateResult {
  /// [productCode]: Ürün
  final String productCode;

  /// [plan]: FEFO dilim planı
  final WhmsFifoPickPlan plan;

  /// [blocked]: true → çıkış engeli
  final bool blocked;

  /// [messageKey]: l10n key
  final String messageKey;

  /// {@macro whms_load_fifo_allocate_result}
  const WhmsLoadFifoAllocateResult({
    required this.productCode,
    required this.plan,
    required this.blocked,
    required this.messageKey,
  });
}

/// {@template whms_load_order_bridge}
/// Araç yükleme ↔ emir store yazma / okuma + FEFO allocate.
///
/// Kullanım örneği:
/// ```dart
/// await WhmsLoadOrderBridge.consumeFromStore(
///   db: txn,
///   orderId: 'lo-1',
/// );
/// ```
/// {@endtemplate}
class WhmsLoadOrderBridge {
  WhmsLoadOrderBridge._();

  /// {@template whms_load_order_bridge_allocate_fefo}
  /// Load satırları için FEFO tüketim planı (consume öncesi kapı).
  /// {@endtemplate}
  static List<WhmsLoadFifoAllocateResult> allocateFefo({
    required List<WhmsBridgeLine> lines,
    required Map<String, List<WhmsFifoBatch>> batchesByProduct,
    Map<String, WhmsFifoRule> rulesByProduct = const {},
    DateTime? today,
  }) {
    final ref = today ?? DateTime.now();
    final out = <WhmsLoadFifoAllocateResult>[];
    for (final line in lines) {
      final code = line.productCode.trim();
      if (code.isEmpty || line.quantity <= 0) continue;
      final rule = rulesByProduct[code] ??
          WhmsFifoRule(productCode: code, fefoEnforce: true);
      final batches = batchesByProduct[code] ?? const <WhmsFifoBatch>[];
      final plan = WhmsFifoRuleEngine.pickFefoBatches(
        qty: line.quantity,
        today: ref,
        rule: rule,
        availableBatches: batches,
      );
      final blocked = plan.shortfallQty > 0 && rule.fefoEnforce;
      out.add(
        WhmsLoadFifoAllocateResult(
          productCode: code,
          plan: plan,
          blocked: blocked,
          messageKey: plan.messageKey,
        ),
      );
    }
    return out;
  }

  /// {@template whms_load_order_bridge_mirror}
  /// Onaylı load DTO’yu emir store’a yazar.
  /// {@endtemplate}
  static Future<WhmsOrderDto?> mirrorApproved({
    required WhmsLoadOrderDto dto,
    WhmsOrderStore store = const WhmsOrderStore(),
    WhmsOrderStatus status = WhmsOrderStatus.assigned,
  }) async {
    if (dto.approval != WhmsApprovalStatus.approved) {
      return null;
    }
    final order = WhmsBridgeOrderMapper.fromLoad(
      dto,
      status: status,
    );
    return store.upsert(order);
  }

  /// {@template whms_load_order_bridge_consume_from_store}
  /// Emir store’dan load tipini okuyup [WhmsLoadOrderConsumer] uygular.
  /// Opsiyonel [batchesByProduct] verilirse FEFO allocate; shortfall → skip.
  /// [quantityDone] > 0 veya [enforcePickingControl] → son kontrol kapısı.
  /// {@endtemplate}
  static Future<WhmsLoadOrderConsumeOutcome> consumeFromStore({
    required DatabaseExecutor db,
    required String orderId,
    WhmsOrderStore store = const WhmsOrderStore(),
    Map<String, List<WhmsFifoBatch>>? batchesByProduct,
    Map<String, WhmsFifoRule>? rulesByProduct,
    DateTime? today,
    bool enforcePickingControl = false,
    bool acknowledgePickingWarnings = false,
    WhmsPickingControlPolicy pickingPolicy =
        WhmsPickingControlPolicy.standard,
  }) async {
    final order = await store.getById(orderId);
    if (order == null) {
      throw StateError('whms load order not found: $orderId');
    }
    if (order.orderType != WhmsOrderType.load) {
      throw ArgumentError(
        'order $orderId is not load '
        '(${order.orderType.wireName})',
      );
    }
    final loadDto = order.toLoadOrderDto();
    if (loadDto == null) {
      throw ArgumentError(
        'order $orderId missing to_vehicle_id',
      );
    }

    if (batchesByProduct != null) {
      final alloc = allocateFefo(
        lines: loadDto.lines,
        batchesByProduct: batchesByProduct,
        rulesByProduct: rulesByProduct ?? const {},
        today: today,
      );
      if (alloc.any((a) => a.blocked)) {
        return WhmsLoadOrderConsumeOutcome(
          status: WhmsLoadOrderConsumeStatus.skipped,
          orderId: orderId,
        );
      }
    }

    final hasPickProgress = order.lines.any(
      (l) => !l.isDeleted && l.quantityDone > 0,
    );
    final runPicking = enforcePickingControl || hasPickProgress;
    List<WhmsBridgeLine>? pickedLines;
    if (runPicking) {
      pickedLines = order.lines
          .where((l) => !l.isDeleted)
          .map(
            (l) => WhmsBridgeLine(
              productId: l.productId,
              productCode: l.productCode ?? '',
              quantity: l.quantityDone,
              unitName: l.unitName,
            ),
          )
          .toList(growable: false);
    }

    final outcome = await WhmsLoadOrderConsumer.consume(
      db: db,
      order: loadDto,
      pickedLines: pickedLines,
      enforcePickingControl: runPicking,
      acknowledgePickingWarnings: acknowledgePickingWarnings,
      pickingPolicy: pickingPolicy,
    );

    if (outcome.status == WhmsLoadOrderConsumeStatus.applied) {
      await store.setStatus(
        orderId,
        WhmsOrderStatus.done,
      );
    }
    return outcome;
  }
}
