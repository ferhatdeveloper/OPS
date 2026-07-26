// Dosya Adı: order_dens_row.dart
// Açıklama: Sipariş dens liste satırı (SQLite join sonucu)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'order_model.dart';

/// {@template order_dens_row}
/// Sipariş dens listesinde gösterilen satır (cari adı + tutar).
///
/// Kullanım örneği:
/// ```dart
/// final row = OrderDensRow.fromJoinedMap(map);
/// ```
/// {@endtemplate}
class OrderDensRow {
  /// [id]: Sipariş kimliği
  final String id;

  /// [orderType]: Satış / Alış
  final OrderType orderType;

  /// [orderDate]: Sipariş tarihi
  final DateTime orderDate;

  /// [status]: Durum metni
  final String status;

  /// [totalAmount]: Genel toplam
  final double totalAmount;

  /// [isSynced]: Logo / merkez transfer durumu
  final bool isSynced;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerCode]: Cari kodu (join)
  final String? customerCode;

  /// [customerName]: Cari ünvanı (join)
  final String? customerName;

  /// [queueJobId]: sync_queue satır kimliği (yoksa null)
  final String? queueJobId;

  /// [retryCount]: Kuyruk yeniden deneme sayısı
  final int retryCount;

  /// [lastError]: Son sync_queue hatası
  final String? lastError;

  /// {@macro order_dens_row}
  const OrderDensRow({
    required this.id,
    required this.orderType,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.isSynced,
    required this.customerId,
    this.customerCode,
    this.customerName,
    this.queueJobId,
    this.retryCount = 0,
    this.lastError,
  });

  /// {@template order_dens_row_from_joined_map}
  /// `orders` + `customers` join satırından model üretir.
  ///
  /// Parametreler:
  /// - [map]: SQLite satırı
  ///
  /// Dönüş değeri:
  /// - [OrderDensRow]: Dens satırı
  /// {@endtemplate}
  factory OrderDensRow.fromJoinedMap(Map<String, dynamic> map) {
    final dateRaw = map['order_date']?.toString();
    final parsed = dateRaw == null || dateRaw.isEmpty
        ? DateTime.now()
        : (DateTime.tryParse(dateRaw) ?? DateTime.now());
    return OrderDensRow(
      id: map['id']?.toString() ?? '',
      orderType: OrderType.fromStorage(map['order_type'] as String?),
      orderDate: parsed,
      status: map['status']?.toString() ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      isSynced: (map['is_synced'] as int?) == 1,
      customerId: map['customer_id']?.toString() ?? '',
      customerCode: map['customer_code']?.toString(),
      customerName: map['customer_name']?.toString(),
      queueJobId: map['queue_job_id']?.toString(),
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      lastError: map['last_error']?.toString(),
    );
  }

  /// {@template order_dens_row_display_title}
  /// Dens başlık: kod · ünvan (yoksa customerId).
  /// {@endtemplate}
  String get displayTitle {
    final code = (customerCode ?? '').trim();
    final name = (customerName ?? '').trim();
    if (code.isNotEmpty && name.isNotEmpty) return '$code · $name';
    if (name.isNotEmpty) return name;
    if (code.isNotEmpty) return code;
    final id = customerId.trim();
    return id.isEmpty ? '—' : id;
  }
}
