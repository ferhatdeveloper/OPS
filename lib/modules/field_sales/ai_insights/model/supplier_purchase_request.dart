// Dosya Adı: supplier_purchase_request.dart
// Açıklama: Depocu tedarikçi ürün talep modeli (yerel kuyruk)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template supplier_purchase_request_status}
/// Tedarik talebi durumu (draft → onay → sync).
/// {@endtemplate}
enum SupplierPurchaseRequestStatus {
  /// Taslak
  draft,

  /// Onay bekliyor
  pendingApproval,

  /// Onaylandı
  approved,

  /// Reddedildi
  rejected,

  /// Logo / merkez sync edildi (ileride)
  synced,
}

/// {@template supplier_purchase_request_status_x}
/// Status string yardımcıları.
/// {@endtemplate}
extension SupplierPurchaseRequestStatusX on SupplierPurchaseRequestStatus {
  /// SQLite değer
  String get storageValue {
    switch (this) {
      case SupplierPurchaseRequestStatus.draft:
        return 'draft';
      case SupplierPurchaseRequestStatus.pendingApproval:
        return 'pending_approval';
      case SupplierPurchaseRequestStatus.approved:
        return 'approved';
      case SupplierPurchaseRequestStatus.rejected:
        return 'rejected';
      case SupplierPurchaseRequestStatus.synced:
        return 'synced';
    }
  }

  /// l10n: field_sales.supply_request.status_<value>
  String get labelKey =>
      'field_sales.supply_request.status_$storageValue';

  static SupplierPurchaseRequestStatus parse(String? raw) {
    final k = (raw ?? '').trim().toLowerCase();
    for (final s in SupplierPurchaseRequestStatus.values) {
      if (s.storageValue == k) return s;
    }
    return SupplierPurchaseRequestStatus.draft;
  }
}

/// {@template supplier_purchase_request}
/// `supplier_purchase_requests` satırı.
/// {@endtemplate}
class SupplierPurchaseRequest {
  /// [id]: UUID
  final String id;

  /// [productId]: Ürün
  final String productId;

  /// [productCode]: Kod
  final String productCode;

  /// [productName]: Ad
  final String productName;

  /// [quantity]: Talep miktarı
  final double quantity;

  /// [supplierId]: Tedarikçi cari (card_role supplier)
  final String? supplierId;

  /// [supplierCode]: Kod
  final String supplierCode;

  /// [supplierName]: Ünvan
  final String supplierName;

  /// [warehouseCode]: Ambar
  final String warehouseCode;

  /// [status]: Durum
  final SupplierPurchaseRequestStatus status;

  /// [notes]: Not
  final String notes;

  /// [onay]: ONAY 0..4
  final int onay;

  /// [isSynced]: Sync
  final bool isSynced;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdBy]: Oluşturan
  final String? createdBy;

  /// [createdAt]: ISO
  final String? createdAt;

  /// [updatedAt]: ISO
  final String? updatedAt;

  /// {@macro supplier_purchase_request}
  const SupplierPurchaseRequest({
    required this.id,
    required this.productId,
    this.productCode = '',
    this.productName = '',
    required this.quantity,
    this.supplierId,
    this.supplierCode = '',
    this.supplierName = '',
    this.warehouseCode = '',
    this.status = SupplierPurchaseRequestStatus.draft,
    this.notes = '',
    this.onay = 0,
    this.isSynced = false,
    this.isDeleted = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierPurchaseRequest.fromMap(Map<String, dynamic> map) {
    return SupplierPurchaseRequest(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      productCode: map['product_code']?.toString() ?? '',
      productName: map['product_name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      supplierId: map['supplier_id']?.toString(),
      supplierCode: map['supplier_code']?.toString() ?? '',
      supplierName: map['supplier_name']?.toString() ?? '',
      warehouseCode: map['warehouse_code']?.toString() ?? '',
      status: SupplierPurchaseRequestStatusX.parse(
        map['status']?.toString(),
      ),
      notes: map['notes']?.toString() ?? '',
      onay: (map['ONAY'] as num?)?.toInt() ?? 0,
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'quantity': quantity,
      'supplier_id': supplierId,
      'supplier_code': supplierCode,
      'supplier_name': supplierName,
      'warehouse_code': warehouseCode,
      'status': status.storageValue,
      'notes': notes,
      'ONAY': onay,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  SupplierPurchaseRequest copyWith({
    String? productId,
    String? productCode,
    String? productName,
    double? quantity,
    String? supplierId,
    String? supplierCode,
    String? supplierName,
    String? warehouseCode,
    SupplierPurchaseRequestStatus? status,
    String? notes,
    int? onay,
    bool? isSynced,
    bool? isDeleted,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return SupplierPurchaseRequest(
      id: id,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      supplierId: supplierId ?? this.supplierId,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      onay: onay ?? this.onay,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
