// Dosya Adı: whms_order_load_bridge.dart
// Açıklama: Emir (load) → WhmsLoadOrderDto → WhmsLoadOrderConsumer
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../contract/whms_bridge_dto.dart';
import 'whms_load_order_consumer.dart';

/// {@template whms_order_load_bridge}
/// `order_type=load` + ONAY=1 → araç stoğuna consume.
///
/// Kullanım örneği:
/// ```dart
/// await WhmsOrderLoadBridge.consumeFromParams(
///   db: db,
///   orderId: 'lo1',
///   fromWh: 'MRK',
///   toVehicleId: 'veh-1',
///   date: DateTime(2026, 7, 28),
///   lines: const [],
///   approval: WhmsApprovalStatus.approved,
/// );
/// ```
/// {@endtemplate}
class WhmsOrderLoadBridge {
  /// SQLite / JSON emir tipi
  static const String orderTypeLoad = 'load';

  WhmsOrderLoadBridge._();

  /// Named params → [WhmsLoadOrderConsumer.consume].
  /// Store yazımı için [WhmsLoadOrderBridge.mirrorApproved] kullanın.
  static Future<WhmsLoadOrderConsumeOutcome> consumeFromParams({
    required DatabaseExecutor db,
    required String orderId,
    required String fromWh,
    required String toVehicleId,
    required DateTime date,
    required List<WhmsBridgeLine> lines,
    WhmsApprovalStatus approval = WhmsApprovalStatus.pending,
  }) {
    if (approval != WhmsApprovalStatus.approved) {
      return Future.value(
        WhmsLoadOrderConsumeOutcome(
          status: WhmsLoadOrderConsumeStatus.skipped,
          orderId: orderId,
        ),
      );
    }

    final order = WhmsLoadOrderDto(
      id: orderId,
      fromWarehouseCode: fromWh,
      toVehicleId: toVehicleId,
      date: date,
      lines: lines,
      approval: approval,
    );
    return WhmsLoadOrderConsumer.consume(db: db, order: order);
  }

  /// Emir map (order_type=load) → consume.
  static Future<WhmsLoadOrderConsumeOutcome> consumeFromOrderMap({
    required DatabaseExecutor db,
    required Map<String, dynamic> orderMap,
    required List<WhmsBridgeLine> lines,
  }) {
    final type = (orderMap['order_type'] ?? orderMap['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (type.isNotEmpty && type != orderTypeLoad) {
      return Future.value(
        WhmsLoadOrderConsumeOutcome(
          status: WhmsLoadOrderConsumeStatus.skipped,
          orderId: orderMap['id']?.toString() ?? '',
        ),
      );
    }

    final onay = (orderMap['ONAY'] as num?)?.toInt() ?? 0;
    final approval = onay == 1
        ? WhmsApprovalStatus.approved
        : WhmsApprovalStatus.pending;

    final dateRaw = orderMap['order_date'] ?? orderMap['date'];
    final date = dateRaw is DateTime
        ? dateRaw
        : DateTime.tryParse(dateRaw?.toString() ?? '') ?? DateTime.now();

    return consumeFromParams(
      db: db,
      orderId: orderMap['id']?.toString() ?? '',
      fromWh: (orderMap['from_warehouse_code'] ??
              orderMap['warehouse_code'] ??
              'MRK')
          .toString(),
      toVehicleId: (orderMap['to_vehicle_id'] ?? '').toString(),
      date: date,
      lines: lines,
      approval: approval,
    );
  }
}
