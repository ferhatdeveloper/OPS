// Dosya Adı: whms_bridge_dto.dart
// Açıklama: OPS ↔ WHMS köprü DTO’ları (yükleme emri / transfer / sayım)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_approval_status}
/// Sync onay durumu — `sync_approval_rules` ile uyumlu.
/// {@endtemplate}
enum WhmsApprovalStatus {
  /// [pending]: ONAY = 0
  pending,

  /// [approved]: ONAY = 1
  approved,

  /// [synced]: ONAY = 2
  synced,

  /// [rejected]: ONAY = 3
  rejected,

  /// [error]: ONAY = 4
  error,
}

/// {@template whms_bridge_line}
/// Köprü satırı (ürün + miktar).
///
/// Kullanım örneği:
/// ```dart
/// const line = WhmsBridgeLine(
///   productId: 'prod_1',
///   productCode: 'SKU-1',
///   quantity: 10,
/// );
/// ```
/// {@endtemplate}
class WhmsBridgeLine {
  /// [productId]: Yerel ürün id
  final String productId;

  /// [productCode]: Logo / WHMS ürün kodu
  final String productCode;

  /// [quantity]: Ana birim miktar
  final double quantity;

  /// [unitName]: Birim adı (opsiyonel)
  final String? unitName;

  /// {@macro whms_bridge_line}
  const WhmsBridgeLine({
    required this.productId,
    required this.productCode,
    required this.quantity,
    this.unitName,
  });

  /// Map serileştirme (queue / mapper).
  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_code': productCode,
        'MASTER_CODE': productCode,
        'quantity': quantity,
        'QUANTITY': quantity,
        if (unitName != null) 'unit_name': unitName,
      };
}

/// {@template whms_load_order_dto}
/// WHMS merkez çıkış → OPS araç yükleme emri.
/// {@endtemplate}
class WhmsLoadOrderDto {
  /// [id]: Emir kimliği
  final String id;

  /// [fromWarehouseCode]: Çıkış ambar kodu (genelde MRK)
  final String fromWarehouseCode;

  /// [toVehicleId]: Hedef araç id
  final String toVehicleId;

  /// [date]: Emir tarihi
  final DateTime date;

  /// [lines]: Satırlar
  final List<WhmsBridgeLine> lines;

  /// [approval]: ONAY durumu
  final WhmsApprovalStatus approval;

  /// [isSynced]: Yerel sync bayrağı
  final bool isSynced;

  /// {@macro whms_load_order_dto}
  const WhmsLoadOrderDto({
    required this.id,
    required this.fromWarehouseCode,
    required this.toVehicleId,
    required this.date,
    required this.lines,
    this.approval = WhmsApprovalStatus.pending,
    this.isSynced = false,
  });
}

/// {@template whms_warehouse_transfer_dto}
/// OPS ambar fişi → WHMS / Logo ambar hareketi.
/// {@endtemplate}
class WhmsWarehouseTransferDto {
  /// [id]: Fiş / batch id
  final String id;

  /// [fromWarehouseCode]: Kaynak kod
  final String fromWarehouseCode;

  /// [toWarehouseCode]: Hedef kod
  final String toWarehouseCode;

  /// [date]: Fiş tarihi
  final DateTime date;

  /// [lines]: Satırlar
  final List<WhmsBridgeLine> lines;

  /// [transferIds]: Yerel `warehouse_transfers.id` listesi
  final List<String> transferIds;

  /// [approval]: ONAY
  final WhmsApprovalStatus approval;

  /// [isSynced]: Sync bayrağı
  final bool isSynced;

  /// {@macro whms_warehouse_transfer_dto}
  const WhmsWarehouseTransferDto({
    required this.id,
    required this.fromWarehouseCode,
    required this.toWarehouseCode,
    required this.date,
    required this.lines,
    this.transferIds = const [],
    this.approval = WhmsApprovalStatus.pending,
    this.isSynced = false,
  });
}

/// {@template whms_count_result_dto}
/// Merkez sayım sonucu (plasiyer sayımından ayrı).
///
/// Kullanım örneği:
/// ```dart
/// final dto = WhmsCountResultDto(
///   id: 'cnt-1',
///   warehouseCode: 'MRK',
///   date: DateTime(2026, 7, 28),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class WhmsCountResultDto {
  /// [id]: Sayım fiş id
  final String id;

  /// [orderId]: Bağlı sayım emri id (opsiyonel)
  final String? orderId;

  /// [warehouseCode]: Sayılan ambar
  final String warehouseCode;

  /// [locationCode]: Raf / göz (opsiyonel)
  final String? locationCode;

  /// [date]: Sayım tarihi
  final DateTime date;

  /// [lines]: Sayılan satırlar (fiili miktar)
  final List<WhmsBridgeLine> lines;

  /// [approval]: ONAY
  final WhmsApprovalStatus approval;

  /// [isSynced]: Logo / kuyruk sync bayrağı
  final bool isSynced;

  /// {@macro whms_count_result_dto}
  const WhmsCountResultDto({
    required this.id,
    required this.warehouseCode,
    required this.date,
    required this.lines,
    this.orderId,
    this.locationCode,
    this.approval = WhmsApprovalStatus.pending,
    this.isSynced = false,
  });

  /// Map serileştirme (queue / mapper iskeleti).
  Map<String, dynamic> toMap() => {
        'id': id,
        if (orderId != null) 'order_id': orderId,
        'warehouse_code': warehouseCode,
        if (locationCode != null) 'location_code': locationCode,
        'date': date.toIso8601String(),
        'lines': lines.map((l) => l.toMap()).toList(growable: false),
        'ONAY': _approvalToInt(approval),
        'is_synced': isSynced ? 1 : 0,
      };

  static int _approvalToInt(WhmsApprovalStatus status) {
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
