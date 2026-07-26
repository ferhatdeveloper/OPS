// Dosya Adı: cash_count_record.dart
// Açıklama: Kasa sayımı yerel kayıt modeli (safe_code + tutar + küpür satırları)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

/// {@template cash_count_line}
/// Kasa sayımı küpür satırı (nominal × adet).
///
/// Kullanım örneği:
/// ```dart
/// const line = CashCountLine(denomination: '200', qty: '5');
/// ```
/// {@endtemplate}
class CashCountLine {
  /// [denomination]: Küpür / nominal metni
  final String denomination;

  /// [qty]: Adet metni
  final String qty;

  /// {@macro cash_count_line}
  const CashCountLine({
    required this.denomination,
    required this.qty,
  });

  /// {@template cash_count_line_from_map}
  /// Map / JSON satırından üretir.
  /// {@endtemplate}
  factory CashCountLine.fromMap(Map<String, dynamic> map) {
    return CashCountLine(
      denomination: map['denomination']?.toString() ?? '',
      qty: map['qty']?.toString() ?? '0',
    );
  }

  /// {@template cash_count_line_to_map}
  /// SQLite / kuyruk JSON satırı.
  /// {@endtemplate}
  Map<String, dynamic> toMap() => {
        'denomination': denomination,
        'qty': qty,
      };
}

/// {@template cash_count_record}
/// Kasa sayımı başlık + küpür satırları (offline-first).
///
/// Kullanım örneği:
/// ```dart
/// final record = CashCountRecord(
///   id: 'cc-1',
///   cashCode: '100 01 01',
///   countDate: DateTime.now(),
///   expectedAmount: 1000,
///   countedAmount: 1000,
/// );
/// ```
/// {@endtemplate}
class CashCountRecord {
  /// [id]: Yerel UUID
  final String id;

  /// [cashCode]: Logo / MBT kasa kodu (safe_code)
  final String cashCode;

  /// [countDate]: Sayım tarihi
  final DateTime countDate;

  /// [expectedAmount]: Sistem bakiyesi
  final double expectedAmount;

  /// [countedAmount]: Sayılan tutar
  final double countedAmount;

  /// [notes]: Açıklama
  final String? notes;

  /// [lines]: Küpür satırları
  final List<CashCountLine> lines;

  /// [onay]: Sync onay (0 bekle / 1 onaylı)
  final int onay;

  /// [isSynced]: Logo aktarıldı mı
  final bool isSynced;

  /// [createdAt]: Oluşturma
  final DateTime createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime updatedAt;

  /// {@macro cash_count_record}
  const CashCountRecord({
    required this.id,
    required this.cashCode,
    required this.countDate,
    this.expectedAmount = 0,
    this.countedAmount = 0,
    this.notes,
    this.lines = const [],
    this.onay = 1,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// [difference]: Sayılan − sistem bakiyesi
  double get difference => countedAmount - expectedAmount;

  /// [entityType]: JobQueue entity_type
  static const String entityType = 'cash_count';

  /// [slipType]: Yerel fiş tipi
  static const String slipType = 'cash_count';

  /// {@template cash_count_record_from_map}
  /// SQLite satırından üretir.
  /// {@endtemplate}
  factory CashCountRecord.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines_json'];
    List<CashCountLine> parsed = const [];
    if (rawLines is String && rawLines.isNotEmpty) {
      final decoded = jsonDecode(rawLines);
      if (decoded is List) {
        parsed = decoded
            .map(
              (e) => CashCountLine.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    }
    return CashCountRecord(
      id: map['id']?.toString() ?? '',
      cashCode: map['cash_code']?.toString() ?? '',
      countDate: DateTime.tryParse(map['count_date']?.toString() ?? '') ??
          DateTime.now(),
      expectedAmount: (map['expected_amount'] as num?)?.toDouble() ?? 0,
      countedAmount: (map['counted_amount'] as num?)?.toDouble() ?? 0,
      notes: map['notes']?.toString(),
      lines: parsed,
      onay: (map['ONAY'] as int?) ?? 0,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// {@template cash_count_record_to_map}
  /// SQLite insert map'i.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cash_code': cashCode,
      'count_date': countDate.toIso8601String(),
      'expected_amount': expectedAmount,
      'counted_amount': countedAmount,
      'difference': difference,
      'notes': notes,
      'lines_json': jsonEncode(lines.map((e) => e.toMap()).toList()),
      'status': 'saved',
      'ONAY': onay,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// {@template cash_count_record_to_queue_payload}
  /// sync_queue payload (Logo aktarım iskeleti).
  /// {@endtemplate}
  Map<String, dynamic> toQueuePayload() {
    return {
      'id': id,
      'entity': entityType,
      'type': entityType,
      'slip_type': slipType,
      'cash_code': cashCode,
      'safe_code': cashCode,
      'count_date': countDate.toIso8601String(),
      'date': countDate.toIso8601String(),
      'expected_amount': expectedAmount,
      'counted_amount': countedAmount,
      'difference': difference,
      'notes': notes,
      'ONAY': onay,
      'lines': lines
          .map(
            (line) => <String, dynamic>{
              'denomination': line.denomination,
              'qty': line.qty,
              'quantity':
                  double.tryParse(line.qty.replaceAll(',', '.')) ?? 0,
            },
          )
          .toList(),
    };
  }
}
