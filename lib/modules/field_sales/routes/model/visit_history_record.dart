// Dosya Adı: visit_history_record.dart
// Açıklama: Geçmiş ziyaret dens satırı (visits SQLite JOIN)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:intl/intl.dart';

/// {@template visit_history_status_kind}
/// Dens trailing durum rengi için durum türü.
/// {@endtemplate}
enum VisitHistoryStatusKind {
  /// Tamamlanmış ziyaret
  completed,

  /// Açık / aktif ziyaret
  open,
}

/// {@template visit_history_record}
/// Geçmiş ziyaret dens satırı — cari adı + tarih + süre + durum.
///
/// Kullanım örneği:
/// ```dart
/// final row = VisitHistoryRecord(
///   id: 'v1',
///   customerId: 'c1',
///   customerName: 'Alpha Market',
///   checkInAt: DateTime(2026, 7, 24),
///   status: 'Completed',
///   durationMinutes: 42,
/// );
/// ```
/// {@endtemplate}
class VisitHistoryRecord {
  /// [id]: visits.id
  final String id;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerName]: JOIN ile cari ünvan (yoksa id)
  final String customerName;

  /// [checkInAt]: Check-in zamanı
  final DateTime checkInAt;

  /// [durationMinutes]: Süre (dk); açık ziyarette null olabilir
  final int? durationMinutes;

  /// [status]: Ham SQLite status (`Open` / `Completed`)
  final String status;

  /// [isSynced]: Senkron bayrağı
  final bool isSynced;

  /// {@macro visit_history_record}
  const VisitHistoryRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.checkInAt,
    required this.status,
    this.durationMinutes,
    this.isSynced = false,
  });

  /// {@template visit_history_record_status_kind}
  /// Ham status → dens durum türü.
  /// {@endtemplate}
  VisitHistoryStatusKind get statusKind => statusKindFrom(status);

  /// {@template visit_history_record_status_l10n_key}
  /// Trailing chip için l10n anahtarı.
  /// {@endtemplate}
  String get statusL10nKey {
    return statusKind == VisitHistoryStatusKind.completed
        ? 'field_sales.visit_completed'
        : 'field_sales.active_visit_status';
  }

  /// {@template visit_history_record_formatted_date}
  /// Dens tarih metni (dd.MM.yyyy).
  /// {@endtemplate}
  String get formattedDate => DateFormat('dd.MM.yyyy').format(checkInAt);

  /// {@template visit_history_record_status_kind_from}
  /// Ham status metnini dens türe çevirir.
  ///
  /// Parametreler:
  /// - [raw]: SQLite `status` değeri
  ///
  /// Dönüş değeri:
  /// - [VisitHistoryStatusKind]: completed veya open
  /// {@endtemplate}
  static VisitHistoryStatusKind statusKindFrom(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'completed') return VisitHistoryStatusKind.completed;
    return VisitHistoryStatusKind.open;
  }

  /// {@template visit_history_record_from_map}
  /// SQLite JOIN satırından dens kayıt üretir.
  /// {@endtemplate}
  factory VisitHistoryRecord.fromMap(Map<String, dynamic> map) {
    final customerId = (map['customer_id'] ?? '').toString();
    final nameRaw = (map['customer_name'] ?? '').toString().trim();
    final checkInRaw = map['check_in_at']?.toString();
    final DateTime checkInAt;
    if (checkInRaw != null && checkInRaw.isNotEmpty) {
      checkInAt = DateTime.tryParse(checkInRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      checkInAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return VisitHistoryRecord(
      id: (map['id'] ?? '').toString(),
      customerId: customerId,
      customerName: nameRaw.isEmpty ? customerId : nameRaw,
      checkInAt: checkInAt,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      status: (map['status'] ?? 'Open').toString(),
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
    );
  }
}
