// Dosya Adı: whms_picking_control_gate.dart
// Açıklama: Load/sevk tamamlamadan önce picking control kapısı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../contract/whms_bridge_dto.dart';
import '../model/whms_order_line_dto.dart';
import 'whms_picking_control_engine.dart';

/// {@template whms_picking_control_gate}
/// Planlanan vs fiili — block → StateError; warn → onay gerekir.
///
/// Kullanım örneği:
/// ```dart
/// WhmsPickingControlGate.assertAllowed(
///   planned: order.lines,
///   actual: pickedLines,
///   acknowledgeWarnings: confirmedByUser,
/// );
/// ```
/// {@endtemplate}
class WhmsPickingControlGate {
  WhmsPickingControlGate._();

  /// {@template whms_picking_control_gate_evaluate}
  /// Karşılaştırır; fırlatmaz (UI onay diyaloğu için).
  /// {@endtemplate}
  static WhmsPickingControlResult evaluate({
    required List<WhmsBridgeLine> planned,
    required List<WhmsBridgeLine> actual,
    WhmsPickingControlPolicy policy = WhmsPickingControlPolicy.standard,
  }) {
    return WhmsPickingControlEngine.compare(
      planned: planned,
      actual: actual,
      policy: policy,
    );
  }

  /// {@template whms_picking_control_gate_evaluate_order_lines}
  /// Emir satırları: quantity vs quantityDone.
  /// {@endtemplate}
  static WhmsPickingControlResult evaluateOrderLines({
    required List<WhmsOrderLineDto> lines,
    WhmsPickingControlPolicy policy = WhmsPickingControlPolicy.standard,
  }) {
    return WhmsPickingControlEngine.compareOrderLines(
      lines: lines,
      policy: policy,
    );
  }

  /// {@template whms_picking_control_gate_assert_allowed}
  /// Block → StateError(messageKey).
  /// Warn + [acknowledgeWarnings]=false → StateError(messageKey).
  ///
  /// Parametreler:
  /// - [planned]: Planlanan satırlar
  /// - [actual]: Fiili satırlar
  /// - [acknowledgeWarnings]: Uyarı onayı (UI’dan)
  /// - [policy]: Karar politikası
  ///
  /// Dönüş değeri:
  /// - [WhmsPickingControlResult]: Geçen sonuç
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: `whms.picking.*` messageKey
  /// {@endtemplate}
  static WhmsPickingControlResult assertAllowed({
    required List<WhmsBridgeLine> planned,
    required List<WhmsBridgeLine> actual,
    bool acknowledgeWarnings = false,
    WhmsPickingControlPolicy policy = WhmsPickingControlPolicy.standard,
  }) {
    final result = evaluate(
      planned: planned,
      actual: actual,
      policy: policy,
    );
    return _enforce(result, acknowledgeWarnings: acknowledgeWarnings);
  }

  /// {@template whms_picking_control_gate_assert_order_lines}
  /// Emir satırları üzerinde assert.
  /// {@endtemplate}
  static WhmsPickingControlResult assertOrderLines({
    required List<WhmsOrderLineDto> lines,
    bool acknowledgeWarnings = false,
    WhmsPickingControlPolicy policy = WhmsPickingControlPolicy.standard,
  }) {
    final result = evaluateOrderLines(lines: lines, policy: policy);
    return _enforce(result, acknowledgeWarnings: acknowledgeWarnings);
  }

  static WhmsPickingControlResult _enforce(
    WhmsPickingControlResult result, {
    required bool acknowledgeWarnings,
  }) {
    if (result.isBlocked) {
      throw StateError(result.messageKey);
    }
    if (result.isWarned && !acknowledgeWarnings) {
      throw StateError(result.messageKey);
    }
    return result;
  }
}
