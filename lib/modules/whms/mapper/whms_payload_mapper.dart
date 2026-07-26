// Dosya Adı: whms_payload_mapper.dart
// Açıklama: WHMS köprü DTO → Logo / queue payload sözleşmesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../field_sales/stock/model/warehouse_master_seed.dart';
import '../contract/whms_bridge_dto.dart';

/// {@template whms_payload_mapper}
/// Ambar kodu normalizasyonu + transfer/yükleme emri map.
///
/// Logo `stockTransferFromLocal` ile uyumlu alan adları üretir;
/// WHMS API gelince aynı DTO üzerinden ikinci implementasyon eklenir.
///
/// Kullanım örneği:
/// ```dart
/// final code = WhmsPayloadMapper.normalizeWarehouseCode('Merkez Depo');
/// // MRK
/// ```
/// {@endtemplate}
class WhmsPayloadMapper {
  WhmsPayloadMapper._();

  /// JobQueue entity — ambar transfer
  static const String stockTransferEntityType = 'stock_transfer';

  /// JobQueue entity — yükleme emri
  static const String loadOrderEntityType = 'whms_load_order';

  /// Yerel transfer tipi
  static const String warehouseTransferType = 'warehouse_transfer';

  /// {@template whms_payload_mapper_normalize}
  /// Görünen ad / tip / kod → kanonik ambar kodu.
  ///
  /// Parametreler:
  /// - [raw]: Kod, seed adı veya serbest metin
  ///
  /// Dönüş değeri:
  /// - [String]: MRK/ARC/IAD veya trim edilmiş ham metin
  /// {@endtemplate}
  static String normalizeWarehouseCode(String raw) {
    final ref = raw.trim();
    if (ref.isEmpty) return ref;

    final byCode = WarehouseMasterSeed.byCode(ref) ??
        WarehouseMasterSeed.byCode(ref.toUpperCase());
    if (byCode != null) return byCode.code;

    for (final row in WarehouseMasterSeed.defaultRows) {
      if (row.seedName.toLowerCase() == ref.toLowerCase()) {
        return row.code;
      }
    }

    final lower = ref.toLowerCase();
    if (lower.contains('merkez') || lower.contains('center')) {
      return 'MRK';
    }
    if (lower.contains('araç') ||
        lower.contains('arac') ||
        lower.contains('vehicle')) {
      return 'ARC';
    }
    if (lower.contains('iade') || lower.contains('return')) {
      return 'IAD';
    }
    return ref;
  }

  /// ONAY int → enum
  static WhmsApprovalStatus approvalFromInt(int value) {
    switch (value) {
      case 1:
        return WhmsApprovalStatus.approved;
      case 2:
        return WhmsApprovalStatus.synced;
      case 3:
        return WhmsApprovalStatus.rejected;
      case 4:
        return WhmsApprovalStatus.error;
      default:
        return WhmsApprovalStatus.pending;
    }
  }

  /// Enum → ONAY int
  static int approvalToInt(WhmsApprovalStatus status) {
    switch (status) {
      case WhmsApprovalStatus.pending:
        return 0;
      case WhmsApprovalStatus.approved:
        return 1;
      case WhmsApprovalStatus.synced:
        return 2;
      case WhmsApprovalStatus.rejected:
        return 3;
      case WhmsApprovalStatus.error:
        return 4;
    }
  }

  /// {@template whms_payload_mapper_transfer}
  /// [WhmsWarehouseTransferDto] → Logo/WHMS sync gövdesi.
  ///
  /// Dönüş değeri:
  /// - [Map]: `from_warehouse_code` / `to_warehouse_code` zorunlu
  /// {@endtemplate}
  static Map<String, dynamic> warehouseTransferToPayload(
    WhmsWarehouseTransferDto dto,
  ) {
    final from = normalizeWarehouseCode(dto.fromWarehouseCode);
    final to = normalizeWarehouseCode(dto.toWarehouseCode);
    final lines = dto.lines.map((l) => l.toMap()).toList(growable: false);

    return {
      'id': dto.id,
      'batch_id': dto.id,
      'transfer_ids': dto.transferIds,
      'entity': stockTransferEntityType,
      'type': warehouseTransferType,
      'transfer_type': warehouseTransferType,
      'from_warehouse': from,
      'to_warehouse': to,
      'from_warehouse_code': from,
      'to_warehouse_code': to,
      'SOURCE_WH': from,
      'TARGET_WH': to,
      'date': _formatDate(dto.date),
      'created_at': dto.date.toIso8601String(),
      'ONAY': approvalToInt(dto.approval),
      'is_synced': dto.isSynced ? 1 : 0,
      'lines': lines,
      'items': lines,
    };
  }

  /// {@template whms_payload_mapper_load_order}
  /// Yükleme emri → queue / gelecekteki WHMS API gövdesi.
  /// {@endtemplate}
  static Map<String, dynamic> loadOrderToPayload(WhmsLoadOrderDto dto) {
    final from = normalizeWarehouseCode(dto.fromWarehouseCode);
    final lines = dto.lines.map((l) => l.toMap()).toList(growable: false);

    return {
      'id': dto.id,
      'entity': loadOrderEntityType,
      'from_warehouse_code': from,
      'SOURCE_WH': from,
      'to_vehicle_id': dto.toVehicleId,
      'date': _formatDate(dto.date),
      'ONAY': approvalToInt(dto.approval),
      'is_synced': dto.isSynced ? 1 : 0,
      'lines': lines,
      'items': lines,
    };
  }

  static String _formatDate(DateTime value) =>
      value.toIso8601String().split('T').first;
}
