// Dosya Adı: order_pending_record.dart
// Açıklama: Bekleyen sipariş dens satırı — SQLite orders + ONAY
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'order_model.dart';

/// {@template order_pending_record}
/// Bekleyen sipariş dens satırı (ONAY / approval_status = 0).
///
/// Kullanım örneği:
/// ```dart
/// final row = OrderPendingRecord.fromMap(sqliteMap);
/// ```
/// {@endtemplate}
class OrderPendingRecord {
  /// [id]: Sipariş kimliği
  final String id;

  /// [customerId]: Cari id
  final String customerId;

  /// [customerCode]: Cari kodu (join)
  final String? customerCode;

  /// [customerName]: Cari ünvan (join)
  final String? customerName;

  /// [orderDate]: Sipariş tarihi
  final DateTime orderDate;

  /// [totalAmount]: Genel toplam
  final double totalAmount;

  /// [status]: Metin durum (Pending / Proposal …)
  final String status;

  /// [orderType]: Satış / Alış
  final OrderType orderType;

  /// [approvalStatus]: ONAY (0 bekliyor …)
  final int approvalStatus;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// [notes]: Not
  final String? notes;

  /// {@macro order_pending_record}
  const OrderPendingRecord({
    required this.id,
    required this.customerId,
    this.customerCode,
    this.customerName,
    required this.orderDate,
    required this.totalAmount,
    this.status = 'Pending',
    this.orderType = OrderType.sales,
    this.approvalStatus = 0,
    this.isSynced = 0,
    this.notes,
  });

  /// {@template order_pending_record_to_map}
  /// SQLite / dens map (ONAY + approval_status).
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_code': customerCode,
      'customer_name': customerName,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'order_type': orderType.storageValue,
      'ONAY': approvalStatus,
      'approval_status': approvalStatus,
      'is_synced': isSynced,
      'notes': notes,
    };
  }

  /// {@template order_pending_record_from_map}
  /// SQLite / stub map → dens satırı.
  ///
  /// Parametreler:
  /// - [map]: Kolon map’i
  ///
  /// Dönüş değeri:
  /// - [OrderPendingRecord]: Dens satırı
  /// {@endtemplate}
  factory OrderPendingRecord.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      final s = v?.toString() ?? '';
      return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    final onay = (map['ONAY'] as num?)?.toInt() ??
        (map['approval_status'] as num?)?.toInt() ??
        0;

    return OrderPendingRecord(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerCode: map['customer_code']?.toString(),
      customerName: map['customer_name']?.toString(),
      orderDate: parseDate(map['order_date']),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Pending',
      orderType: OrderType.fromStorage(map['order_type']?.toString()),
      approvalStatus: onay,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString(),
    );
  }
}
