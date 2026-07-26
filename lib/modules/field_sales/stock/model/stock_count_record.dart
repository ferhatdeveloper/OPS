// Dosya Adı: stock_count_record.dart
// Açıklama: Sayım fişi yerel kayıt modeli (İşyeri·Fabrika·Ambar + satırlar)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

/// {@template stock_count_line}
/// Sayım fişi satır kalemi.
///
/// Kullanım örneği:
/// ```dart
/// const line = StockCountLine(code: 'SKU-1', name: 'Ürün', qty: '1');
/// ```
/// {@endtemplate}
class StockCountLine {
  /// [code]: Ürün kodu
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [qty]: Sayılan miktar metni
  final String qty;

  /// {@macro stock_count_line}
  const StockCountLine({
    required this.code,
    required this.name,
    required this.qty,
  });

  /// {@template stock_count_line_from_map}
  /// Map / JSON satırından üretir.
  /// {@endtemplate}
  factory StockCountLine.fromMap(Map<String, dynamic> map) {
    return StockCountLine(
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      qty: map['qty']?.toString() ?? '0',
    );
  }

  /// {@template stock_count_line_to_map}
  /// SQLite / kuyruk JSON satırı.
  /// {@endtemplate}
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'qty': qty,
      };
}

/// {@template stock_count_record}
/// Sayım fişi başlık + satırlar (offline-first).
///
/// Kullanım örneği:
/// ```dart
/// final record = StockCountRecord(
///   id: 'sc-1',
///   workplace: 'Merkez',
///   factory: 'F01',
///   warehouse: 'Araç',
///   slipDate: DateTime.now(),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class StockCountRecord {
  /// [id]: Yerel UUID
  final String id;

  /// [workplace]: İşyeri
  final String? workplace;

  /// [factory]: Fabrika
  final String? factory;

  /// [warehouse]: Ambar
  final String? warehouse;

  /// [slipDate]: Fiş tarihi
  final DateTime slipDate;

  /// [lines]: Sayım satırları
  final List<StockCountLine> lines;

  /// [onay]: Sync onay (0 bekle / 1 onaylı)
  final int onay;

  /// [isSynced]: Logo aktarıldı mı
  final bool isSynced;

  /// [createdAt]: Oluşturma
  final DateTime createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime updatedAt;

  /// {@macro stock_count_record}
  const StockCountRecord({
    required this.id,
    this.workplace,
    this.factory,
    this.warehouse,
    required this.slipDate,
    this.lines = const [],
    this.onay = 1,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// {@template stock_count_record_from_map}
  /// SQLite satırından üretir.
  /// {@endtemplate}
  factory StockCountRecord.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines_json'];
    List<StockCountLine> parsed = const [];
    if (rawLines is String && rawLines.isNotEmpty) {
      final decoded = jsonDecode(rawLines);
      if (decoded is List) {
        parsed = decoded
            .map(
              (e) => StockCountLine.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    }
    return StockCountRecord(
      id: map['id']?.toString() ?? '',
      workplace: map['workplace']?.toString(),
      factory: map['factory']?.toString(),
      warehouse: map['warehouse']?.toString(),
      slipDate: DateTime.tryParse(map['slip_date']?.toString() ?? '') ??
          DateTime.now(),
      lines: parsed,
      onay: (map['ONAY'] as int?) ?? 0,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// {@template stock_count_record_to_map}
  /// SQLite insert map'i.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workplace': workplace,
      'factory': factory,
      'warehouse': warehouse,
      'slip_date': slipDate.toIso8601String(),
      'lines_json': jsonEncode(lines.map((e) => e.toMap()).toList()),
      'status': 'saved',
      'ONAY': onay,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// [entityType]: JobQueue entity_type
  static const String entityType = 'stock_count';

  /// [slipType]: Yerel fiş tipi (≠ fatura TYPE 8)
  static const String slipType = 'stock_count';

  /// {@template stock_count_record_to_queue_payload}
  /// sync_queue payload (Logo aktarım iskeleti).
  /// {@endtemplate}
  Map<String, dynamic> toQueuePayload() {
    return {
      'id': id,
      'entity': entityType,
      'type': entityType,
      'slip_type': slipType,
      'workplace': workplace,
      'factory': factory,
      'warehouse': warehouse,
      'warehouse_code': warehouse,
      'date': slipDate.toIso8601String(),
      'slip_date': slipDate.toIso8601String(),
      'ONAY': onay,
      'lines': lines
          .map(
            (line) => <String, dynamic>{
              'product_code': line.code,
              'product_name': line.name,
              'quantity':
                  double.tryParse(line.qty.replaceAll(',', '.')) ?? 0,
              'qty_text': line.qty,
              'code': line.code,
              'name': line.name,
              'qty': line.qty,
            },
          )
          .toList(),
    };
  }
}
