// Dosya Adı: batch_expiry_record.dart
// Açıklama: Parti / SKT dens satırı (lot + son kullanma) model
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';

/// {@template BatchExpiryStatus}
/// Parti / SKT dens yaşam durumu.
/// {@endtemplate}
enum BatchExpiryStatus {
  /// SKT henüz uzak
  ok,

  /// Yaklaşan SKT (eşik dahil)
  near,

  /// SKT geçmiş
  expired;

  /// SQLite kodu
  String get code {
    switch (this) {
      case BatchExpiryStatus.near:
        return 'NEAR';
      case BatchExpiryStatus.expired:
        return 'EXPIRED';
      case BatchExpiryStatus.ok:
        return 'OK';
    }
  }

  /// Kod → enum
  static BatchExpiryStatus fromCode(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v == 'NEAR' || v == 'NEAR_EXPIRY') {
      return BatchExpiryStatus.near;
    }
    if (v == 'EXPIRED' || v == 'PAST') {
      return BatchExpiryStatus.expired;
    }
    return BatchExpiryStatus.ok;
  }

  /// Bilinen kod mu
  static bool isKnown(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    return v == 'OK' ||
        v == 'NEAR' ||
        v == 'NEAR_EXPIRY' ||
        v == 'EXPIRED' ||
        v == 'PAST';
  }

  /// {@template BatchExpiryStatus_label}
  /// Yerelleştirilmiş durum etiketi.
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [String]: Durum metni
  /// {@endtemplate}
  String label(AppLocalization l10n) {
    switch (this) {
      case BatchExpiryStatus.near:
        return l10n.translate('field_sales.batch_expiry_status_near');
      case BatchExpiryStatus.expired:
        return l10n.translate('field_sales.batch_expiry_status_expired');
      case BatchExpiryStatus.ok:
        return l10n.translate('field_sales.batch_expiry_status_ok');
    }
  }

  /// {@template BatchExpiryStatus_fromExpiry}
  /// SKT tarihine göre durum üretir.
  ///
  /// Parametreler:
  /// - [expiryDate]: Son kullanma
  /// - [now]: Referans gün
  /// - [nearDays]: Yaklaşan eşik (gün)
  ///
  /// Dönüş değeri:
  /// - [BatchExpiryStatus]: Hesaplanan durum
  /// {@endtemplate}
  static BatchExpiryStatus fromExpiry({
    required DateTime expiryDate,
    DateTime? now,
    int nearDays = 30,
  }) {
    final today = now ?? DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final startExpiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    final days = startExpiry.difference(startToday).inDays;
    if (days < 0) return BatchExpiryStatus.expired;
    if (days <= nearDays) return BatchExpiryStatus.near;
    return BatchExpiryStatus.ok;
  }
}

/// {@template batch_expiry_record}
/// Parti / SKT dens satırı — stok kodu, lot, SKT, miktar, ambar.
///
/// Kullanım örneği:
/// ```dart
/// final row = BatchExpiryRecord(
///   id: 'be-1',
///   productCode: 'STK001',
///   productName: 'Demo Ürün',
///   lotNo: 'L2026A',
///   expiryDate: DateTime(2026, 12, 31),
/// );
/// ```
/// {@endtemplate}
class BatchExpiryRecord {
  /// [id]: Yerel birincil anahtar
  final String id;

  /// [productId]: İsteğe bağlı ürün id
  final String? productId;

  /// [productCode]: Stok / malzeme kodu
  final String productCode;

  /// [productName]: Stok adı
  final String productName;

  /// [lotNo]: Parti / lot numarası
  final String lotNo;

  /// [expiryDate]: Son kullanma (SKT)
  final DateTime expiryDate;

  /// [quantity]: Miktar
  final double quantity;

  /// [unit]: Birim
  final String unit;

  /// [warehouseCode]: Ambar kodu
  final String? warehouseCode;

  /// [warehouseName]: Ambar adı
  final String? warehouseName;

  /// [status]: OK / NEAR / EXPIRED (null → SKT’den hesaplanır)
  final BatchExpiryStatus? status;

  /// [approvalStatus]: ONAY (0 bekliyor …)
  final int approvalStatus;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// [isDeleted]: Soft delete
  final int isDeleted;

  /// [createdAt]: Oluşturma
  final DateTime? createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime? updatedAt;

  /// {@macro batch_expiry_record}
  const BatchExpiryRecord({
    required this.id,
    this.productId,
    required this.productCode,
    required this.productName,
    required this.lotNo,
    required this.expiryDate,
    this.quantity = 0,
    this.unit = 'AD',
    this.warehouseCode,
    this.warehouseName,
    this.status,
    this.approvalStatus = 0,
    this.isSynced = 0,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template batch_expiry_record_resolved_status}
  /// Durum alanı veya SKT’den çözümlenen durum.
  /// {@endtemplate}
  BatchExpiryStatus get resolvedStatus =>
      status ?? BatchExpiryStatus.fromExpiry(expiryDate: expiryDate);

  /// {@template batch_expiry_record_status_code}
  /// SQLite `status` kolon değeri.
  /// {@endtemplate}
  String get statusCode => resolvedStatus.code;

  /// {@template batch_expiry_record_days_remaining}
  /// SKT’ye kalan gün (negatif = geçmiş).
  ///
  /// Parametreler:
  /// - [now]: Referans gün
  ///
  /// Dönüş değeri:
  /// - [int]: Gün farkı
  /// {@endtemplate}
  int daysRemaining({DateTime? now}) {
    final today = now ?? DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final startExpiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return startExpiry.difference(startToday).inDays;
  }

  /// {@template batch_expiry_record_to_map}
  /// SQLite satır map’i.
  ///
  /// Dönüş değeri:
  /// - [Map]: Kolon → değer
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'lot_no': lotNo,
      'expiry_date': expiryDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'warehouse_code': warehouseCode,
      'warehouse_name': warehouseName,
      'status': statusCode,
      'ONAY': approvalStatus,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// {@template batch_expiry_record_from_map}
  /// SQLite / stub map → model.
  ///
  /// Parametreler:
  /// - [map]: Kolon map’i
  ///
  /// Dönüş değeri:
  /// - [BatchExpiryRecord]: Dens satırı
  /// {@endtemplate}
  factory BatchExpiryRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final expiry = parseDate(map['expiry_date']) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return BatchExpiryRecord(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString(),
      productCode: map['product_code']?.toString() ?? '',
      productName: map['product_name']?.toString() ?? '',
      lotNo: map['lot_no']?.toString() ?? '',
      expiryDate: expiry,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? 'AD',
      warehouseCode: map['warehouse_code']?.toString(),
      warehouseName: map['warehouse_name']?.toString(),
      status: BatchExpiryStatus.fromCode(map['status']?.toString()),
      approvalStatus: (map['ONAY'] as num?)?.toInt() ??
          (map['approval_status'] as num?)?.toInt() ??
          0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      isDeleted: (map['is_deleted'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  /// {@template batch_expiry_record_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  BatchExpiryRecord copyWith({
    String? id,
    String? productId,
    String? productCode,
    String? productName,
    String? lotNo,
    DateTime? expiryDate,
    double? quantity,
    String? unit,
    String? warehouseCode,
    String? warehouseName,
    BatchExpiryStatus? status,
    int? approvalStatus,
    int? isSynced,
    int? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatchExpiryRecord(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      lotNo: lotNo ?? this.lotNo,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      warehouseName: warehouseName ?? this.warehouseName,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
