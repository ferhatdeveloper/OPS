// Dosya Adı: partial_delivery_model.dart
// Açıklama: Kısmi teslimat SQLite/provider iskelet kayıt modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

/// {@template partial_delivery_line}
/// Kısmi teslimat satır iskeleti (kod · ad · miktar metni).
///
/// Kullanım örneği:
/// ```dart
/// const line = PartialDeliveryLine(code: 'KSM-1', name: 'Kalem', qty: '1/2');
/// ```
/// {@endtemplate}
class PartialDeliveryLine {
  /// [code]: Ürün / kalem kodu
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [qty]: Miktar metni (örn. 1/2)
  final String qty;

  /// {@macro partial_delivery_line}
  const PartialDeliveryLine({
    required this.code,
    required this.name,
    required this.qty,
  });

  /// {@template partial_delivery_line_from_map}
  /// Map'ten satır üretir.
  /// {@endtemplate}
  factory PartialDeliveryLine.fromMap(Map<String, dynamic> map) {
    return PartialDeliveryLine(
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      qty: (map['qty'] ?? '').toString(),
    );
  }

  /// {@template partial_delivery_line_to_map}
  /// SQLite / JSON için map üretir.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'qty': qty,
    };
  }
}

/// {@template partial_delivery_record}
/// Kısmi teslimat başlık kaydı (İşyeri · Fabrika · Ambar · tarih · satırlar).
///
/// Kullanım örneği:
/// ```dart
/// final r = PartialDeliveryRecord(
///   id: 'pd-1',
///   warehouse: 'Araç Depo',
///   deliveryDate: DateTime.now(),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class PartialDeliveryRecord {
  /// [id]: UUID
  final String id;

  /// [workplace]: İşyeri
  final String? workplace;

  /// [factory]: Fabrika
  final String? factory;

  /// [warehouse]: Ambar
  final String? warehouse;

  /// [deliveryDate]: Teslimat tarihi
  final DateTime deliveryDate;

  /// [lines]: Satır listesi
  final List<PartialDeliveryLine> lines;

  /// [status]: Pending / Synced vb.
  final String status;

  /// [isSynced]: Sync kuyruğu durumu
  final bool isSynced;

  /// [createdAt]: Oluşturma zamanı
  final DateTime? createdAt;

  /// [updatedAt]: Güncelleme zamanı
  final DateTime? updatedAt;

  /// {@macro partial_delivery_record}
  const PartialDeliveryRecord({
    required this.id,
    this.workplace,
    this.factory,
    this.warehouse,
    required this.deliveryDate,
    this.lines = const [],
    this.status = 'Pending',
    this.isSynced = false,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template partial_delivery_record_from_map}
  /// SQLite satırından kayıt üretir.
  /// {@endtemplate}
  factory PartialDeliveryRecord.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines_json'];
    List<PartialDeliveryLine> parsed = const [];
    if (rawLines is String && rawLines.isNotEmpty) {
      final decoded = jsonDecode(rawLines);
      if (decoded is List) {
        parsed = decoded
            .whereType<Map>()
            .map(
              (e) => PartialDeliveryLine.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    }

    return PartialDeliveryRecord(
      id: map['id'] as String,
      workplace: map['workplace'] as String?,
      factory: map['factory'] as String?,
      warehouse: map['warehouse'] as String?,
      deliveryDate: DateTime.parse(map['delivery_date'] as String),
      lines: parsed,
      status: map['status'] as String? ?? 'Pending',
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// {@template partial_delivery_record_to_map}
  /// SQLite insert map'i üretir.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'workplace': workplace,
      'factory': factory,
      'warehouse': warehouse,
      'delivery_date': deliveryDate.toIso8601String(),
      'status': status,
      'lines_json': jsonEncode(lines.map((e) => e.toMap()).toList()),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': 0,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
    };
  }

  /// {@template partial_delivery_record_queue_payload}
  /// sync_queue için iskelet payload.
  /// {@endtemplate}
  Map<String, dynamic> toQueuePayload() {
    return {
      'id': id,
      'workplace': workplace,
      'factory': factory,
      'warehouse': warehouse,
      'delivery_date': deliveryDate.toIso8601String(),
      'status': status,
      'lines': lines.map((e) => e.toMap()).toList(),
    };
  }
}
