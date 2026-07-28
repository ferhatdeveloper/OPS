// Dosya Adı: whms_picking_control_engine.dart
// Açıklama: Planlanan vs fiili miktar karşılaştırma motoru (pure Dart)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../contract/whms_bridge_dto.dart';
import '../model/whms_order_line_dto.dart';
import 'whms_picking_control_models.dart';

export 'whms_picking_control_models.dart';

/// {@template whms_picking_control_engine}
/// Sevkiyat son kontrol — eksik / fazla / yanlış ürün.
/// DB bağımlılığı yok; load/sevk tamamlamadan önce çağrılır.
///
/// Kullanım örneği:
/// ```dart
/// final r = WhmsPickingControlEngine.compare(
///   planned: plannedLines,
///   actual: pickedLines,
/// );
/// ```
/// {@endtemplate}
class WhmsPickingControlEngine {
  WhmsPickingControlEngine._();

  /// Miktar eşitlik toleransı
  static const double qtyEpsilon = 1e-6;

  /// {@template whms_picking_control_engine_compare}
  /// Planlanan vs fiili satırları ürün anahtarına göre karşılaştırır.
  ///
  /// Parametreler:
  /// - [planned]: Planlanan satırlar (`quantity` = plan)
  /// - [actual]: Fiili / okutulan satırlar (`quantity` = fiili)
  /// - [policy]: Fark → karar politikası
  ///
  /// Dönüş değeri:
  /// - [WhmsPickingControlResult]: allow | warn | block + messageKey
  /// {@endtemplate}
  static WhmsPickingControlResult compare({
    required List<WhmsBridgeLine> planned,
    required List<WhmsBridgeLine> actual,
    WhmsPickingControlPolicy policy = WhmsPickingControlPolicy.standard,
  }) {
    final plannedMap = _aggregate(planned);
    final actualMap = _aggregate(actual);
    final keys = <String>{...plannedMap.keys, ...actualMap.keys};

    final variances = <WhmsPickingLineVariance>[];
    for (final key in keys) {
      final pQty = plannedMap[key] ?? 0;
      final aQty = actualMap[key] ?? 0;
      final v = _lineVariance(
        productKey: key,
        plannedQty: pQty,
        actualQty: aQty,
        policy: policy,
      );
      if (v.kind != WhmsPickingVarianceKind.match) {
        variances.add(v);
      }
    }

    if (variances.isEmpty) {
      return const WhmsPickingControlResult(
        decision: WhmsPickingControlDecision.allow,
        messageKey: WhmsPickingMessageKeys.allow,
      );
    }

    final hasBlock = variances.any(
      (v) => v.decision == WhmsPickingControlDecision.block,
    );
    if (hasBlock) {
      final first = variances.firstWhere(
        (v) => v.decision == WhmsPickingControlDecision.block,
      );
      return WhmsPickingControlResult(
        decision: WhmsPickingControlDecision.block,
        messageKey: first.messageKey,
        variances: variances,
      );
    }

    final firstWarn = variances.first;
    return WhmsPickingControlResult(
      decision: WhmsPickingControlDecision.warn,
      messageKey: firstWarn.messageKey,
      variances: variances,
    );
  }

  /// {@template whms_picking_control_engine_compare_order_lines}
  /// Emir satırları: [quantity] plan, [quantityDone] fiili.
  /// {@endtemplate}
  static WhmsPickingControlResult compareOrderLines({
    required List<WhmsOrderLineDto> lines,
    WhmsPickingControlPolicy policy = WhmsPickingControlPolicy.standard,
  }) {
    final active = lines.where((l) => !l.isDeleted).toList(growable: false);
    final planned = active
        .map(
          (l) => WhmsBridgeLine(
            productId: l.productId,
            productCode: l.productCode ?? '',
            quantity: l.quantity,
            unitName: l.unitName,
          ),
        )
        .toList(growable: false);
    final actual = active
        .map(
          (l) => WhmsBridgeLine(
            productId: l.productId,
            productCode: l.productCode ?? '',
            quantity: l.quantityDone,
            unitName: l.unitName,
          ),
        )
        .toList(growable: false);
    return compare(planned: planned, actual: actual, policy: policy);
  }

  /// {@template whms_picking_control_engine_product_key}
  /// Satır ürün anahtarı: dolu productId, yoksa productCode.
  /// {@endtemplate}
  static String productKey(WhmsBridgeLine line) {
    final id = line.productId.trim();
    if (id.isNotEmpty) return id;
    return line.productCode.trim();
  }

  static bool qtyEqual(double a, double b) => (a - b).abs() <= qtyEpsilon;

  static Map<String, double> _aggregate(List<WhmsBridgeLine> lines) {
    final map = <String, double>{};
    for (final line in lines) {
      final key = productKey(line);
      if (key.isEmpty) continue;
      final q = line.quantity;
      if (q <= 0) continue;
      map[key] = (map[key] ?? 0) + q;
    }
    return map;
  }

  static WhmsPickingLineVariance _lineVariance({
    required String productKey,
    required double plannedQty,
    required double actualQty,
    required WhmsPickingControlPolicy policy,
  }) {
    if (plannedQty <= qtyEpsilon && actualQty > qtyEpsilon) {
      final decision = _decisionFor(
        kind: WhmsPickingVarianceKind.wrong,
        policy: policy,
      );
      return WhmsPickingLineVariance(
        productKey: productKey,
        plannedQty: plannedQty,
        actualQty: actualQty,
        kind: WhmsPickingVarianceKind.wrong,
        decision: decision,
        messageKey: _messageFor(
          kind: WhmsPickingVarianceKind.wrong,
          decision: decision,
        ),
      );
    }

    if (qtyEqual(plannedQty, actualQty)) {
      return WhmsPickingLineVariance(
        productKey: productKey,
        plannedQty: plannedQty,
        actualQty: actualQty,
        kind: WhmsPickingVarianceKind.match,
        decision: WhmsPickingControlDecision.allow,
        messageKey: WhmsPickingMessageKeys.allow,
      );
    }

    if (actualQty < plannedQty) {
      final decision = _decisionFor(
        kind: WhmsPickingVarianceKind.short,
        policy: policy,
      );
      return WhmsPickingLineVariance(
        productKey: productKey,
        plannedQty: plannedQty,
        actualQty: actualQty,
        kind: WhmsPickingVarianceKind.short,
        decision: decision,
        messageKey: _messageFor(
          kind: WhmsPickingVarianceKind.short,
          decision: decision,
        ),
      );
    }

    final decision = _decisionFor(
      kind: WhmsPickingVarianceKind.over,
      policy: policy,
    );
    return WhmsPickingLineVariance(
      productKey: productKey,
      plannedQty: plannedQty,
      actualQty: actualQty,
      kind: WhmsPickingVarianceKind.over,
      decision: decision,
      messageKey: _messageFor(
        kind: WhmsPickingVarianceKind.over,
        decision: decision,
      ),
    );
  }

  static WhmsPickingControlDecision _decisionFor({
    required WhmsPickingVarianceKind kind,
    required WhmsPickingControlPolicy policy,
  }) {
    switch (policy) {
      case WhmsPickingControlPolicy.strict:
        return WhmsPickingControlDecision.block;
      case WhmsPickingControlPolicy.warnAll:
        return WhmsPickingControlDecision.warn;
      case WhmsPickingControlPolicy.standard:
        switch (kind) {
          case WhmsPickingVarianceKind.over:
            return WhmsPickingControlDecision.warn;
          case WhmsPickingVarianceKind.short:
          case WhmsPickingVarianceKind.wrong:
            return WhmsPickingControlDecision.block;
          case WhmsPickingVarianceKind.match:
            return WhmsPickingControlDecision.allow;
        }
    }
  }

  static String _messageFor({
    required WhmsPickingVarianceKind kind,
    required WhmsPickingControlDecision decision,
  }) {
    final isWarn = decision == WhmsPickingControlDecision.warn;
    switch (kind) {
      case WhmsPickingVarianceKind.short:
        return isWarn
            ? WhmsPickingMessageKeys.warnShort
            : WhmsPickingMessageKeys.blockShort;
      case WhmsPickingVarianceKind.over:
        return isWarn
            ? WhmsPickingMessageKeys.warnOver
            : WhmsPickingMessageKeys.blockOver;
      case WhmsPickingVarianceKind.wrong:
        return isWarn
            ? WhmsPickingMessageKeys.warnWrong
            : WhmsPickingMessageKeys.blockWrong;
      case WhmsPickingVarianceKind.match:
        return WhmsPickingMessageKeys.allow;
    }
  }
}
