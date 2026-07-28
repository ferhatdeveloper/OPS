// Dosya Adı: visit_detail_record.dart
// Açıklama: Geçmiş ziyaret detay + ilişkili sipariş dens modeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:intl/intl.dart';

import 'visit_history_record.dart';

/// {@template visit_related_order}
/// Ziyaret gününde aynı cariye bağlı sipariş özeti.
///
/// Kullanım örneği:
/// ```dart
/// final o = VisitRelatedOrder(
///   id: 'o1',
///   orderDate: DateTime(2026, 7, 24),
///   totalAmount: 120.5,
///   status: 'Pending',
/// );
/// ```
/// {@endtemplate}
class VisitRelatedOrder {
  /// [id]: orders.id
  final String id;

  /// [orderDate]: Sipariş tarihi
  final DateTime? orderDate;

  /// [totalAmount]: Toplam tutar
  final double totalAmount;

  /// [status]: Ham sipariş durumu
  final String status;

  /// [notes]: Opsiyonel not
  final String? notes;

  /// {@macro visit_related_order}
  const VisitRelatedOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    this.orderDate,
    this.notes,
  });

  /// {@template visit_related_order_formatted_date}
  /// Dens tarih metni (dd.MM.yyyy) veya boş.
  /// {@endtemplate}
  String get formattedDate {
    final d = orderDate;
    if (d == null) return '';
    return DateFormat('dd.MM.yyyy').format(d);
  }

  /// {@template visit_related_order_from_map}
  /// SQLite satırından ilişkili sipariş üretir.
  /// {@endtemplate}
  factory VisitRelatedOrder.fromMap(Map<String, dynamic> map) {
    final raw = map['order_date']?.toString();
    DateTime? orderDate;
    if (raw != null && raw.isNotEmpty) {
      orderDate = DateTime.tryParse(raw);
    }
    return VisitRelatedOrder(
      id: (map['id'] ?? '').toString(),
      orderDate: orderDate,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? '').toString(),
      notes: map['notes']?.toString(),
    );
  }
}

/// {@template visit_detail_record}
/// Tamamlanmış / açık ziyaret detayı (check-in/out, GPS, not, STT, sipariş).
///
/// Kullanım örneği:
/// ```dart
/// final d = VisitDetailRecord(
///   id: 'v1',
///   customerId: 'c1',
///   customerName: 'Alpha',
///   checkInAt: DateTime(2026, 7, 24, 10),
///   status: 'Completed',
/// );
/// ```
/// {@endtemplate}
class VisitDetailRecord {
  /// [id]: visits.id
  final String id;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerName]: JOIN cari ünvan
  final String customerName;

  /// [checkInAt]: Check-in
  final DateTime checkInAt;

  /// [checkOutAt]: Check-out (açıkta null)
  final DateTime? checkOutAt;

  /// [checkInLat]: Giriş enlem
  final double? checkInLat;

  /// [checkInLong]: Giriş boylam
  final double? checkInLong;

  /// [checkOutLat]: Çıkış enlem
  final double? checkOutLat;

  /// [checkOutLong]: Çıkış boylam
  final double? checkOutLong;

  /// [notes]: Ziyaret / STT notları
  final String? notes;

  /// [reasonCode]: Ziyaret sebebi kodu
  final String? reasonCode;

  /// [audioRecordingPath]: STT ses dosya yolu
  final String? audioRecordingPath;

  /// [status]: Open / Completed
  final String status;

  /// [durationMinutes]: Süre (dk)
  final int? durationMinutes;

  /// [isSynced]: Senkron bayrağı
  final bool isSynced;

  /// [relatedOrders]: Aynı cari + gün aralığı siparişleri
  final List<VisitRelatedOrder> relatedOrders;

  /// {@macro visit_detail_record}
  const VisitDetailRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.checkInAt,
    required this.status,
    this.checkOutAt,
    this.checkInLat,
    this.checkInLong,
    this.checkOutLat,
    this.checkOutLong,
    this.notes,
    this.reasonCode,
    this.audioRecordingPath,
    this.durationMinutes,
    this.isSynced = false,
    this.relatedOrders = const [],
  });

  /// {@template visit_detail_record_status_kind}
  /// Dens durum türü.
  /// {@endtemplate}
  VisitHistoryStatusKind get statusKind =>
      VisitHistoryRecord.statusKindFrom(status);

  /// {@template visit_detail_record_is_completed}
  /// Tamamlanmış mı (salt okunur detay).
  /// {@endtemplate}
  bool get isCompleted => statusKind == VisitHistoryStatusKind.completed;

  /// {@template visit_detail_record_status_l10n_key}
  /// Durum chip l10n anahtarı.
  /// {@endtemplate}
  String get statusL10nKey {
    return isCompleted
        ? 'field_sales.visit_completed'
        : 'field_sales.active_visit_status';
  }

  /// {@template visit_detail_record_copy_with_orders}
  /// İlişkili sipariş listesini günceller.
  /// {@endtemplate}
  VisitDetailRecord copyWithOrders(List<VisitRelatedOrder> orders) {
    return VisitDetailRecord(
      id: id,
      customerId: customerId,
      customerName: customerName,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      checkInLat: checkInLat,
      checkInLong: checkInLong,
      checkOutLat: checkOutLat,
      checkOutLong: checkOutLong,
      notes: notes,
      reasonCode: reasonCode,
      audioRecordingPath: audioRecordingPath,
      status: status,
      durationMinutes: durationMinutes,
      isSynced: isSynced,
      relatedOrders: orders,
    );
  }

  /// {@template visit_detail_record_from_map}
  /// SQLite JOIN satırından detay üretir (siparişler ayrı yüklenir).
  /// {@endtemplate}
  factory VisitDetailRecord.fromMap(Map<String, dynamic> map) {
    final customerId = (map['customer_id'] ?? '').toString();
    final nameRaw = (map['customer_name'] ?? '').toString().trim();
    DateTime parseDt(Object? raw) {
      final s = raw?.toString();
      if (s == null || s.isEmpty) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime? parseOpt(Object? raw) {
      final s = raw?.toString();
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return VisitDetailRecord(
      id: (map['id'] ?? '').toString(),
      customerId: customerId,
      customerName: nameRaw.isEmpty ? customerId : nameRaw,
      checkInAt: parseDt(map['check_in_at']),
      checkOutAt: parseOpt(map['check_out_at']),
      checkInLat: (map['check_in_lat'] as num?)?.toDouble(),
      checkInLong: (map['check_in_long'] as num?)?.toDouble(),
      checkOutLat: (map['check_out_lat'] as num?)?.toDouble(),
      checkOutLong: (map['check_out_long'] as num?)?.toDouble(),
      notes: map['notes']?.toString(),
      reasonCode: map['reason_code']?.toString(),
      audioRecordingPath: map['audio_recording_path']?.toString(),
      status: (map['status'] ?? 'Open').toString(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
    );
  }
}
