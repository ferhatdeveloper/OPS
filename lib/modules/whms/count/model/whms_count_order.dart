// Dosya Adı: whms_count_order.dart
// Açıklama: Merkez depo sayım emri modeli (whms_count_orders DDL)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../../contract/whms_bridge_dto.dart';

/// {@template whms_count_order_status}
/// Sayım emri yaşam döngüsü (P0).
/// {@endtemplate}
enum WhmsCountOrderStatus {
  /// [draft]: Taslak
  draft,

  /// [assigned]: Terminale atandı
  assigned,

  /// [inProgress]: Sayım devam ediyor
  inProgress,

  /// [completed]: Sonuç üretildi
  completed,

  /// [cancelled]: İptal
  cancelled,
}

/// {@template whms_count_order}
/// Merkez sayım emri — `whms_count_orders` satırı.
///
/// Plasiyer `StockCountRecord` ile karıştırılmaz; WHMS `/whms/count`.
///
/// Kullanım örneği:
/// ```dart
/// final order = WhmsCountOrder(
///   id: 'ord-1',
///   warehouseCode: 'MRK',
///   orderDate: DateTime(2026, 7, 28),
///   createdAt: DateTime(2026, 7, 28),
///   updatedAt: DateTime(2026, 7, 28),
/// );
/// print(order.toMap()['order_date']); // 2026-07-28
/// ```
/// {@endtemplate}
class WhmsCountOrder {
  /// [id]: Emir kimliği
  final String id;

  /// [warehouseCode]: Sayılacak ambar (MRK/…)
  final String warehouseCode;

  /// [locationCode]: Raf / göz filtresi (opsiyonel)
  final String? locationCode;

  /// [status]: Yaşam döngüsü
  final WhmsCountOrderStatus status;

  /// [productCodes]: Ürün filtresi → `filter_json` (boş = tüm ambar)
  final List<String> productCodes;

  /// [orderDate]: Emir tarihi (`order_date`)
  final DateTime orderDate;

  /// [approval]: ONAY
  final WhmsApprovalStatus approval;

  /// [isSynced]: Sync bayrağı
  final bool isSynced;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final DateTime createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime updatedAt;

  /// {@macro whms_count_order}
  const WhmsCountOrder({
    required this.id,
    required this.warehouseCode,
    required this.orderDate,
    required this.createdAt,
    required this.updatedAt,
    this.locationCode,
    this.status = WhmsCountOrderStatus.draft,
    this.productCodes = const [],
    this.approval = WhmsApprovalStatus.pending,
    this.isSynced = false,
    this.isDeleted = false,
  });

  /// [filterJson]: Ürün filtresi JSON metni (SQLite kolonu)
  String? get filterJson =>
      productCodes.isEmpty ? null : jsonEncode(productCodes);

  /// {@template whms_count_order_from_map}
  /// SQLite map → model.
  ///
  /// Parametreler:
  /// - [map]: `whms_count_orders` satırı
  ///
  /// Dönüş değeri:
  /// - [WhmsCountOrder]
  /// {@endtemplate}
  factory WhmsCountOrder.fromMap(Map<String, dynamic> map) {
    return WhmsCountOrder(
      id: map['id']?.toString() ?? '',
      warehouseCode: map['warehouse_code']?.toString() ?? '',
      locationCode: _nullableString(map['location_code']),
      status: _statusFrom(map['status']?.toString()),
      productCodes: _parseFilterJson(map['filter_json']),
      orderDate: _parseDate(map['order_date']) ?? DateTime.now(),
      approval: _approvalFromInt((map['ONAY'] as num?)?.toInt() ?? 0),
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  /// {@template whms_count_order_to_map}
  /// Model → SQLite insert/update map (`whms_count_orders`).
  ///
  /// Dönüş değeri:
  /// - [Map]: DDL kolonları
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'warehouse_code': warehouseCode,
      'location_code': locationCode,
      'status': status.name,
      'filter_json': filterJson,
      'order_date': _formatDate(orderDate),
      'ONAY': _approvalToInt(approval),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// {@template whms_count_order_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  WhmsCountOrder copyWith({
    String? id,
    String? warehouseCode,
    String? locationCode,
    WhmsCountOrderStatus? status,
    List<String>? productCodes,
    DateTime? orderDate,
    WhmsApprovalStatus? approval,
    bool? isSynced,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WhmsCountOrder(
      id: id ?? this.id,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      locationCode: locationCode ?? this.locationCode,
      status: status ?? this.status,
      productCodes: productCodes ?? this.productCodes,
      orderDate: orderDate ?? this.orderDate,
      approval: approval ?? this.approval,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _nullableString(Object? value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static DateTime? _parseDate(Object? raw) {
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String _formatDate(DateTime value) =>
      value.toIso8601String().split('T').first;

  static List<String> _parseFilterJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  static WhmsCountOrderStatus _statusFrom(String? raw) {
    final v = (raw ?? '').trim();
    for (final s in WhmsCountOrderStatus.values) {
      if (s.name == v) return s;
    }
    return WhmsCountOrderStatus.draft;
  }

  static WhmsApprovalStatus _approvalFromInt(int value) {
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
