// Dosya Adı: whms_order_dto.dart
// Açıklama: WHMS emir başlık DTO (whms_orders + satırlar + ONAY)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../contract/whms_bridge_dto.dart';
import 'whms_order_line_dto.dart';
import 'whms_order_status.dart';
import 'whms_order_type.dart';

/// {@template whms_order_dto}
/// `whms_orders` başlık + opsiyonel satırlar.
///
/// Yaşam: draft → assigned → in_progress → done/completed.
/// ONAY: [WhmsApprovalStatus] (0–4) — sync kuyruğu.
///
/// Kullanım örneği:
/// ```dart
/// final o = WhmsOrderDto(
///   id: 'ord_1',
///   orderType: WhmsOrderType.malKabul,
///   status: WhmsOrderStatus.draft,
///   warehouseCode: 'MRK',
///   orderDate: '2026-07-28',
///   createdAt: '2026-07-28T00:00:00.000',
///   updatedAt: '2026-07-28T00:00:00.000',
/// );
/// ```
/// {@endtemplate}
class WhmsOrderDto {
  /// [id]: Emir PK
  final String id;

  /// [orderType]: Emir tipi
  final WhmsOrderType orderType;

  /// [status]: Yaşam durumu
  final WhmsOrderStatus status;

  /// [warehouseCode]: Kaynak / işlem ambarı
  final String? warehouseCode;

  /// [fromWarehouseCode]: Kaynak (transfer / load)
  final String? fromWarehouseCode;

  /// [toWarehouseCode]: Hedef ambar (transfer)
  final String? toWarehouseCode;

  /// [toVehicleId]: Hedef araç (load / sevk)
  final String? toVehicleId;

  /// [assignedUserId]: Atanan kullanıcı
  final String? assignedUserId;

  /// [deviceId]: Terminal / cihaz
  final String? deviceId;

  /// [referenceNo]: Dış belge / irsaliye no
  final String? referenceNo;

  /// [notes]: Not
  final String? notes;

  /// [requireSerial]: Emir flag — tüm satırlarda seri zorunlu
  final bool requireSerial;

  /// [orderDate]: Emir tarihi (ISO gün veya timestamp)
  final String orderDate;

  /// [completedAt]: Tamamlanma anı
  final String? completedAt;

  /// [approval]: ONAY 0–4
  final WhmsApprovalStatus approval;

  /// [isSynced]: Sync bayrağı
  final bool isSynced;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final String createdAt;

  /// [updatedAt]: Güncelleme
  final String updatedAt;

  /// [lines]: Satırlar (liste/detay)
  final List<WhmsOrderLineDto> lines;

  /// {@macro whms_order_dto}
  const WhmsOrderDto({
    required this.id,
    required this.orderType,
    required this.status,
    required this.orderDate,
    required this.createdAt,
    required this.updatedAt,
    this.warehouseCode,
    this.fromWarehouseCode,
    this.toWarehouseCode,
    this.toVehicleId,
    this.assignedUserId,
    this.deviceId,
    this.referenceNo,
    this.notes,
    this.requireSerial = false,
    this.completedAt,
    this.approval = WhmsApprovalStatus.pending,
    this.isSynced = false,
    this.isDeleted = false,
    this.lines = const <WhmsOrderLineDto>[],
  });

  /// mal_kabul için satır lokasyon zorunluluğu.
  bool get requiresLocation => orderType.requiresLocation;

  /// Tüm satırlar lokasyon kuralını sağlıyor mu.
  /// Boş satır = yalnızca header taslak (lokasyon satır eklenince).
  bool get linesSatisfyLocation {
    if (!requiresLocation) return true;
    if (lines.isEmpty) return true;
    return lines.every((l) => l.hasRequiredLocation(orderType));
  }

  /// SQLite başlık map → DTO (satırlar ayrı yüklenir).
  factory WhmsOrderDto.fromMap(
    Map<String, dynamic> map, {
    List<WhmsOrderLineDto> lines = const <WhmsOrderLineDto>[],
  }) {
    return WhmsOrderDto(
      id: map['id']?.toString() ?? '',
      orderType: WhmsOrderType.fromWire(map['order_type']?.toString()),
      status: WhmsOrderStatus.fromWire(map['status']?.toString()),
      warehouseCode: map['warehouse_code']?.toString(),
      fromWarehouseCode: map['from_warehouse_code']?.toString(),
      toWarehouseCode: map['to_warehouse_code']?.toString(),
      toVehicleId: map['to_vehicle_id']?.toString(),
      assignedUserId: map['assigned_user_id']?.toString(),
      deviceId: map['device_id']?.toString(),
      referenceNo: map['reference_no']?.toString(),
      notes: map['notes']?.toString(),
      requireSerial: (map['require_serial'] as num?)?.toInt() == 1,
      orderDate: map['order_date']?.toString() ?? '',
      completedAt: map['completed_at']?.toString(),
      approval: approvalFromInt((map['ONAY'] as num?)?.toInt() ?? 0),
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      lines: lines,
    );
  }

  /// Başlık → SQLite map (satırlar ayrı).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'order_type': orderType.wireName,
      'status': status.wireName,
      'warehouse_code': warehouseCode,
      'from_warehouse_code': fromWarehouseCode,
      'to_warehouse_code': toWarehouseCode,
      'to_vehicle_id': toVehicleId,
      'assigned_user_id': assignedUserId,
      'device_id': deviceId,
      'reference_no': referenceNo,
      'notes': notes,
      'require_serial': requireSerial ? 1 : 0,
      'order_date': orderDate,
      'completed_at': completedAt,
      'ONAY': approvalToInt(approval),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Load emrine köprü.
  WhmsLoadOrderDto? toLoadOrderDto() {
    if (orderType != WhmsOrderType.load) return null;
    final vehicleId = toVehicleId;
    if (vehicleId == null || vehicleId.isEmpty) return null;
    return WhmsLoadOrderDto(
      id: id,
      fromWarehouseCode:
          fromWarehouseCode ?? warehouseCode ?? '',
      toVehicleId: vehicleId,
      date: DateTime.tryParse(orderDate) ?? DateTime.now(),
      lines: lines.map((l) => l.toBridgeLine()).toList(),
      approval: approval,
      isSynced: isSynced,
    );
  }

  /// Transfer köprüsü.
  WhmsWarehouseTransferDto? toTransferDto() {
    if (orderType != WhmsOrderType.transfer) return null;
    final from = fromWarehouseCode ?? warehouseCode;
    final to = toWarehouseCode;
    if (from == null || from.isEmpty || to == null || to.isEmpty) {
      return null;
    }
    return WhmsWarehouseTransferDto(
      id: id,
      fromWarehouseCode: from,
      toWarehouseCode: to,
      date: DateTime.tryParse(orderDate) ?? DateTime.now(),
      lines: lines.map((l) => l.toBridgeLine()).toList(),
      approval: approval,
      isSynced: isSynced,
    );
  }

  /// Sayım sonucu köprüsü.
  WhmsCountResultDto? toCountResultDto() {
    if (orderType != WhmsOrderType.sayim) return null;
    return WhmsCountResultDto(
      id: id,
      warehouseCode: warehouseCode ?? '',
      date: DateTime.tryParse(orderDate) ?? DateTime.now(),
      lines: lines.map((l) => l.toBridgeLine()).toList(),
      approval: approval,
    );
  }

  /// İmmutable kopya.
  WhmsOrderDto copyWith({
    String? id,
    WhmsOrderType? orderType,
    WhmsOrderStatus? status,
    String? warehouseCode,
    String? fromWarehouseCode,
    String? toWarehouseCode,
    String? toVehicleId,
    String? assignedUserId,
    String? deviceId,
    String? referenceNo,
    String? notes,
    bool? requireSerial,
    String? orderDate,
    String? completedAt,
    WhmsApprovalStatus? approval,
    bool? isSynced,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
    List<WhmsOrderLineDto>? lines,
  }) {
    return WhmsOrderDto(
      id: id ?? this.id,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      fromWarehouseCode: fromWarehouseCode ?? this.fromWarehouseCode,
      toWarehouseCode: toWarehouseCode ?? this.toWarehouseCode,
      toVehicleId: toVehicleId ?? this.toVehicleId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      deviceId: deviceId ?? this.deviceId,
      referenceNo: referenceNo ?? this.referenceNo,
      notes: notes ?? this.notes,
      requireSerial: requireSerial ?? this.requireSerial,
      orderDate: orderDate ?? this.orderDate,
      completedAt: completedAt ?? this.completedAt,
      approval: approval ?? this.approval,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lines: lines ?? this.lines,
    );
  }

  /// ONAY int → [WhmsApprovalStatus].
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

  /// [WhmsApprovalStatus] → ONAY int.
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
}
