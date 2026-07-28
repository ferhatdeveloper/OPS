// Dosya Adı: whms_load_order_consumer.dart
// Açıklama: Onaylı WHMS yükleme emri → picking + FIFO kapı + VehicleLoadService
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../field_sales/vehicle/engine/vehicle_load_service.dart';
import '../contract/whms_bridge_dto.dart';
import '../mapper/whms_payload_mapper.dart';
import '../shipping/whms_picking_control_engine.dart';
import '../shipping/whms_picking_control_gate.dart';
import 'whms_fifo_rule_engine.dart';
import 'whms_load_fifo_gate.dart';

/// {@template whms_load_order_consume_result}
/// Consume sonucu.
/// {@endtemplate}
enum WhmsLoadOrderConsumeStatus {
  /// [applied]: Araç stoğuna uygulandı
  applied,

  /// [skipped]: ONAY≠1
  skipped,
}

/// {@template whms_load_order_consume_outcome}
/// Yükleme emri consume özeti.
/// {@endtemplate}
class WhmsLoadOrderConsumeOutcome {
  /// [status]: applied / skipped
  final WhmsLoadOrderConsumeStatus status;

  /// [orderId]: Emir id
  final String orderId;

  /// {@macro whms_load_order_consume_outcome}
  const WhmsLoadOrderConsumeOutcome({
    required this.status,
    required this.orderId,
  });
}

/// {@template whms_load_order_consumer}
/// WHMS merkez çıkış emrini plasiyer araç stoğuna uygular.
/// `vehicle_provider` UI akışına dokunmaz; yalnız motor çağrısı.
///
/// Kullanım örneği:
/// ```dart
/// await WhmsLoadOrderConsumer.consume(db: txn, order: dto);
/// ```
/// {@endtemplate}
class WhmsLoadOrderConsumer {
  /// {@macro whms_load_order_consumer}
  const WhmsLoadOrderConsumer._();

  /// {@template whms_load_order_consumer_consume}
  /// ONAY=1 ise picking control + FIFO allocate + [VehicleLoadService.applyLoad].
  ///
  /// Parametreler:
  /// - [db]: SQLite executor
  /// - [order]: Yükleme emri DTO (planlanan satırlar)
  /// - [pickedLines]: Fiili / okutulan satırlar (picking control)
  /// - [enforcePickingControl]: true → plan vs fiili kapısı
  /// - [acknowledgePickingWarnings]: fazla vb. uyarı onayı
  /// - [pickingPolicy]: eksik/fazla/yanlış politika
  /// - [enforceFifo]: true → [WhmsFifoRuleEngine.allocate] kapısı
  /// - [today]: FIFO referans günü
  /// - [rulesByProductCode]: Test / override kurallar
  /// - [batchesByProductCode]: Test / override lotlar
  ///
  /// Dönüş değeri:
  /// - [WhmsLoadOrderConsumeOutcome]
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: Stok yetersiz / FIFO / picking block (messageKey)
  /// - [ArgumentError]: Araç id boş / MRK dışı / picking fiili yok
  /// {@endtemplate}
  static Future<WhmsLoadOrderConsumeOutcome> consume({
    required DatabaseExecutor db,
    required WhmsLoadOrderDto order,
    List<WhmsBridgeLine>? pickedLines,
    bool enforcePickingControl = false,
    bool acknowledgePickingWarnings = false,
    WhmsPickingControlPolicy pickingPolicy =
        WhmsPickingControlPolicy.standard,
    bool enforceFifo = true,
    DateTime? today,
    Map<String, WhmsFifoRule>? rulesByProductCode,
    Map<String, List<WhmsFifoBatch>>? batchesByProductCode,
  }) async {
    if (order.approval != WhmsApprovalStatus.approved) {
      return WhmsLoadOrderConsumeOutcome(
        status: WhmsLoadOrderConsumeStatus.skipped,
        orderId: order.id,
      );
    }

    final vehicleId = order.toVehicleId.trim();
    if (vehicleId.isEmpty) {
      throw ArgumentError('toVehicleId required');
    }

    final from = WhmsPayloadMapper.normalizeWarehouseCode(
      order.fromWarehouseCode,
    );
    if (from != 'MRK') {
      throw ArgumentError(
        'load order fromWarehouseCode must be MRK, got: $from',
      );
    }

    final activeLines = order.lines
        .where((l) => l.quantity > 0 && l.productId.trim().isNotEmpty)
        .toList(growable: false);

    if (enforcePickingControl) {
      if (pickedLines == null) {
        throw ArgumentError(
          'pickedLines required when enforcePickingControl',
        );
      }
      WhmsPickingControlGate.assertAllowed(
        planned: activeLines,
        actual: pickedLines,
        acknowledgeWarnings: acknowledgePickingWarnings,
        policy: pickingPolicy,
      );
    }

    if (enforceFifo && activeLines.isNotEmpty) {
      await WhmsLoadFifoGate.assertLinesAllowed(
        db: db,
        lines: activeLines,
        today: today,
        rulesByProductCode: rulesByProductCode,
        batchesByProductCode: batchesByProductCode,
      );
    }

    final loadSource = pickedLines ?? activeLines;
    final items = loadSource
        .where((l) => l.quantity > 0 && l.productId.trim().isNotEmpty)
        .map(
          (l) => <String, dynamic>{
            'productId': l.productId.trim(),
            'quantity': l.quantity,
          },
        )
        .toList(growable: false);

    if (items.isNotEmpty) {
      await VehicleLoadService.applyLoad(
        db: db,
        vehicleId: vehicleId,
        items: items,
      );
    }

    return WhmsLoadOrderConsumeOutcome(
      status: WhmsLoadOrderConsumeStatus.applied,
      orderId: order.id,
    );
  }
}
