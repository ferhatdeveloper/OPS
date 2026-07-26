// Dosya Adı: waybill_model.dart
// Açıklama: İrsaliye (dispatch) yerel model — SQLite kalıcılık
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template WaybillModel}
/// Yerel irsaliye başlığı (`waybills` tablosu).
///
/// Kullanım örneği:
/// ```dart
/// final wb = WaybillModel(
///   id: id,
///   customerId: cariId,
///   waybillDate: DateTime.now(),
///   waybillType: 'waybill_wholesale',
/// );
/// ```
/// {@endtemplate}
class WaybillModel {
  /// [id]: İrsaliye kimliği (UUID)
  final String id;

  /// [customerId]: Cari kart kimliği
  final String customerId;

  /// [waybillDate]: Belge tarihi
  final DateTime waybillDate;

  /// [waybillType]: `waybill_wholesale` | `waybill_purchase`
  final String waybillType;

  /// [totalAmount]: Bilgilendirme tutarı (cari borçlandırma yok)
  final double totalAmount;

  /// [status]: Durum metni
  final String status;

  /// [notes]: Not
  final String? notes;

  /// [isSynced]: Logo sync bayrağı
  final int isSynced;

  WaybillModel({
    required this.id,
    required this.customerId,
    required this.waybillDate,
    required this.waybillType,
    this.totalAmount = 0,
    this.status = 'Completed',
    this.notes,
    this.isSynced = 0,
  });

  /// {@template WaybillModel.toMap}
  /// SQLite satır map'i.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'waybill_date': waybillDate.toIso8601String(),
      'waybill_type': waybillType,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'is_synced': isSynced,
    };
  }

  /// {@template WaybillModel.fromMap}
  /// SQLite satırından model.
  /// {@endtemplate}
  factory WaybillModel.fromMap(Map<String, dynamic> map) {
    return WaybillModel(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      waybillDate: DateTime.tryParse(map['waybill_date']?.toString() ?? '') ??
          DateTime.now(),
      waybillType:
          map['waybill_type']?.toString() ?? 'waybill_wholesale',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Completed',
      notes: map['notes']?.toString(),
      isSynced: (map['is_synced'] as int?) ?? 0,
    );
  }
}

/// {@template WaybillItemModel}
/// İrsaliye kalem satırı (`waybill_items`).
/// {@endtemplate}
class WaybillItemModel {
  /// [id]: Kalem kimliği
  final String id;

  /// [waybillId]: Üst irsaliye kimliği
  final String waybillId;

  /// [productId]: Ürün kimliği
  final String productId;

  /// [productCode]: Logo MASTER_CODE
  final String productCode;

  /// [quantity]: Miktar
  final double quantity;

  /// [price]: Birim fiyat (bilgilendirme)
  final double price;

  /// [totalAmount]: Satır tutarı
  final double totalAmount;

  WaybillItemModel({
    required this.id,
    required this.waybillId,
    required this.productId,
    required this.productCode,
    required this.quantity,
    this.price = 0,
    this.totalAmount = 0,
  });

  /// {@template WaybillItemModel.toMap}
  /// SQLite satır map'i.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'waybill_id': waybillId,
      'product_id': productId,
      'product_code': productCode,
      'quantity': quantity,
      'price': price,
      'total_amount': totalAmount,
    };
  }

  /// {@template WaybillItemModel.fromMap}
  /// SQLite satırından model.
  /// {@endtemplate}
  factory WaybillItemModel.fromMap(Map<String, dynamic> map) {
    return WaybillItemModel(
      id: map['id']?.toString() ?? '',
      waybillId: map['waybill_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      productCode: map['product_code']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// {@template WaybillLineInput}
/// Kaydet API girişi (ekran dens kalemi).
/// {@endtemplate}
class WaybillLineInput {
  /// [productId]: Ürün kimliği
  final String productId;

  /// [productCode]: Ürün kodu
  final String productCode;

  /// [quantity]: Miktar
  final double quantity;

  /// [unitPrice]: Birim fiyat (opsiyonel bilgilendirme)
  final double unitPrice;

  const WaybillLineInput({
    required this.productId,
    required this.productCode,
    required this.quantity,
    this.unitPrice = 0,
  });
}
