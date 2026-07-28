// Dosya Adı: whms_order_line_dto.dart
// Açıklama: WHMS emir satırı DTO (whms_order_lines + ONAY)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../contract/whms_bridge_dto.dart';
import '../mapper/whms_payload_mapper.dart';
import 'whms_order_type.dart';

/// {@template whms_order_line_dto}
/// `whms_order_lines` satır modeli — fromMap / toMap + ONAY.
///
/// Kullanım örneği:
/// ```dart
/// final line = WhmsOrderLineDto(
///   id: 'ln_1',
///   orderId: 'ord_1',
///   lineNo: 1,
///   productId: 'p1',
///   productCode: 'SKU-1',
///   quantity: 10,
/// );
/// ```
/// {@endtemplate}
class WhmsOrderLineDto {
  /// [id]: Satır PK
  final String id;

  /// [orderId]: Üst emir FK
  final String orderId;

  /// [lineNo]: Satır numarası
  final int lineNo;

  /// [productId]: Yerel ürün id
  final String productId;

  /// [productCode]: Ürün kodu
  final String? productCode;

  /// [productName]: Ürün adı
  final String? productName;

  /// [quantity]: Emredilen miktar
  final double quantity;

  /// [quantityDone]: Tamamlanan miktar
  final double quantityDone;

  /// [unitName]: Birim
  final String? unitName;

  /// [locationCode]: Raf / adres (mal_kabul zorunlu)
  final String? locationCode;

  /// [lotNo]: Lot
  final String? lotNo;

  /// [serialNo]: Seri
  final String? serialNo;

  /// [expiryDate]: SKT (ISO tarih metni)
  final String? expiryDate;

  /// [routeSeq]: Toplama rota sırası
  final int? routeSeq;

  /// [approval]: Satır ONAY 0–4
  final WhmsApprovalStatus approval;

  /// [isSynced]: Sync bayrağı
  final bool isSynced;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_order_line_dto}
  const WhmsOrderLineDto({
    required this.id,
    required this.orderId,
    required this.lineNo,
    required this.productId,
    required this.quantity,
    this.quantityDone = 0,
    this.productCode,
    this.productName,
    this.unitName,
    this.locationCode,
    this.lotNo,
    this.serialNo,
    this.expiryDate,
    this.routeSeq,
    this.approval = WhmsApprovalStatus.pending,
    this.isSynced = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template whms_order_line_dto_requires_location}
  /// [orderType] için `location_code` zorunlu mu (mal_kabul).
  /// {@endtemplate}
  static bool requiresLocation(WhmsOrderType orderType) =>
      orderType.requiresLocation;

  /// {@template whms_order_line_dto_has_required_location}
  /// mal_kabul satırında dolu lokasyon var mı.
  /// {@endtemplate}
  bool hasRequiredLocation(WhmsOrderType orderType) {
    if (!requiresLocation(orderType)) return true;
    return (locationCode ?? '').trim().isNotEmpty;
  }

  /// SQLite map → DTO.
  factory WhmsOrderLineDto.fromMap(Map<String, dynamic> map) {
    return WhmsOrderLineDto(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      lineNo: (map['line_no'] as num?)?.toInt() ?? 0,
      productId: map['product_id']?.toString() ?? '',
      productCode: map['product_code']?.toString(),
      productName: map['product_name']?.toString(),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      quantityDone: (map['quantity_done'] as num?)?.toDouble() ?? 0,
      unitName: map['unit_name']?.toString(),
      locationCode: map['location_code']?.toString(),
      lotNo: map['lot_no']?.toString(),
      serialNo: map['serial_no']?.toString(),
      expiryDate: map['expiry_date']?.toString(),
      routeSeq: (map['route_seq'] as num?)?.toInt(),
      approval: WhmsPayloadMapper.approvalFromInt(
        (map['ONAY'] as num?)?.toInt() ?? 0,
      ),
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  /// DTO → SQLite map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'order_id': orderId,
      'line_no': lineNo,
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'quantity': quantity,
      'quantity_done': quantityDone,
      'unit_name': unitName,
      'location_code': locationCode,
      'lot_no': lotNo,
      'serial_no': serialNo,
      'expiry_date': expiryDate,
      'route_seq': routeSeq,
      'ONAY': WhmsPayloadMapper.approvalToInt(approval),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Köprü satırı.
  WhmsBridgeLine toBridgeLine() {
    return WhmsBridgeLine(
      productId: productId,
      productCode: productCode ?? '',
      quantity: quantity,
      unitName: unitName,
    );
  }

  /// İmmutable kopya.
  WhmsOrderLineDto copyWith({
    String? id,
    String? orderId,
    int? lineNo,
    String? productId,
    String? productCode,
    String? productName,
    double? quantity,
    double? quantityDone,
    String? unitName,
    String? locationCode,
    String? lotNo,
    String? serialNo,
    String? expiryDate,
    int? routeSeq,
    WhmsApprovalStatus? approval,
    bool? isSynced,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return WhmsOrderLineDto(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      lineNo: lineNo ?? this.lineNo,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      quantityDone: quantityDone ?? this.quantityDone,
      unitName: unitName ?? this.unitName,
      locationCode: locationCode ?? this.locationCode,
      lotNo: lotNo ?? this.lotNo,
      serialNo: serialNo ?? this.serialNo,
      expiryDate: expiryDate ?? this.expiryDate,
      routeSeq: routeSeq ?? this.routeSeq,
      approval: approval ?? this.approval,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
