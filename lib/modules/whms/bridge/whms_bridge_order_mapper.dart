// Dosya Adı: whms_bridge_order_mapper.dart
// Açıklama: Transfer / load köprü DTO → WhmsOrderDto (A API)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:uuid/uuid.dart';

import '../contract/whms_bridge_dto.dart';
import '../mapper/whms_payload_mapper.dart';
import '../model/whms_order_dto.dart';
import '../model/whms_order_line_dto.dart';
import '../model/whms_order_status.dart';
import '../model/whms_order_type.dart';

/// {@template whms_bridge_order_mapper}
/// Dens / köprü DTO’larını emir omurgasına map eder.
///
/// Kullanım örneği:
/// ```dart
/// final order = WhmsBridgeOrderMapper.fromTransfer(dto);
/// ```
/// {@endtemplate}
class WhmsBridgeOrderMapper {
  WhmsBridgeOrderMapper._();

  /// {@template whms_bridge_order_mapper_from_transfer}
  /// Onaylı ambar transfer → `WhmsOrderType.transfer` emri.
  ///
  /// Parametreler:
  /// - [dto]: Köprü transfer DTO
  /// - [status]: Yaşam durumu (varsayılan completed)
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderDto]: Store’a yazılacak emir
  /// {@endtemplate}
  static WhmsOrderDto fromTransfer(
    WhmsWarehouseTransferDto dto, {
    WhmsOrderStatus status = WhmsOrderStatus.done,
  }) {
    final now = DateTime.now().toIso8601String();
    final from = WhmsPayloadMapper.normalizeWarehouseCode(
      dto.fromWarehouseCode,
    );
    final to = WhmsPayloadMapper.normalizeWarehouseCode(
      dto.toWarehouseCode,
    );
    final day = _day(dto.date);
    final lines = _lines(
      orderId: dto.id,
      bridgeLines: dto.lines,
      approval: dto.approval,
      now: now,
    );
    final ref = dto.transferIds.isEmpty
        ? null
        : dto.transferIds.join(',');

    return WhmsOrderDto(
      id: dto.id,
      orderType: WhmsOrderType.transfer,
      status: status,
      warehouseCode: from,
      fromWarehouseCode: from,
      toWarehouseCode: to,
      referenceNo: ref,
      notes: ref == null ? null : 'transfer_ids=$ref',
      orderDate: day,
      completedAt:
          status.isTerminal ? now : null,
      approval: dto.approval,
      isSynced: dto.isSynced,
      createdAt: now,
      updatedAt: now,
      lines: lines,
    );
  }

  /// {@template whms_bridge_order_mapper_from_load}
  /// Araç yükleme köprüsü → `WhmsOrderType.load` emri.
  ///
  /// Parametreler:
  /// - [dto]: Yükleme emri DTO
  /// - [status]: Yaşam durumu (varsayılan completed)
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderDto]
  /// {@endtemplate}
  static WhmsOrderDto fromLoad(
    WhmsLoadOrderDto dto, {
    WhmsOrderStatus status = WhmsOrderStatus.done,
  }) {
    final now = DateTime.now().toIso8601String();
    final from = WhmsPayloadMapper.normalizeWarehouseCode(
      dto.fromWarehouseCode,
    );
    final day = _day(dto.date);
    final lines = _lines(
      orderId: dto.id,
      bridgeLines: dto.lines,
      approval: dto.approval,
      now: now,
    );

    return WhmsOrderDto(
      id: dto.id,
      orderType: WhmsOrderType.load,
      status: status,
      warehouseCode: from,
      fromWarehouseCode: from,
      toVehicleId: dto.toVehicleId.trim(),
      orderDate: day,
      completedAt:
          status.isTerminal ? now : null,
      approval: dto.approval,
      isSynced: dto.isSynced,
      createdAt: now,
      updatedAt: now,
      lines: lines,
    );
  }

  static List<WhmsOrderLineDto> _lines({
    required String orderId,
    required List<WhmsBridgeLine> bridgeLines,
    required WhmsApprovalStatus approval,
    required String now,
  }) {
    final out = <WhmsOrderLineDto>[];
    for (var i = 0; i < bridgeLines.length; i++) {
      final l = bridgeLines[i];
      out.add(
        WhmsOrderLineDto(
          id: const Uuid().v4(),
          orderId: orderId,
          lineNo: i + 1,
          productId: l.productId.trim(),
          productCode: l.productCode.trim(),
          quantity: l.quantity,
          unitName: l.unitName,
          approval: approval,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return out;
  }

  static String _day(DateTime value) =>
      value.toIso8601String().split('T').first;
}
