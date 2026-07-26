// Dosya Adı: delivery_hold_record.dart
// Açıklama: Beklemeye alınan teslimat dens satır modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template delivery_hold_doc_side}
/// Beklemeye alınan belge yönü (1-SATIŞ / 2-ALIŞ).
/// {@endtemplate}
enum DeliveryHoldDocSide {
  /// Satış
  sales,

  /// Alış
  purchase,
}

/// {@template delivery_hold_record}
/// Yerelde beklemeye alınan teslimat fiş özeti.
///
/// Kullanım örneği:
/// ```dart
/// final r = DeliveryHoldRecord(
///   id: 'dh-1',
///   docNo: 'TSL-001',
///   customerCode: 'C001',
///   customerName: 'Demo Cari',
///   side: DeliveryHoldDocSide.sales,
///   heldAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class DeliveryHoldRecord {
  /// [id]: Yerel kayıt kimliği
  final String id;

  /// [docNo]: Belge / fiş no
  final String docNo;

  /// [customerCode]: Cari kodu
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [side]: Satış / alış
  final DeliveryHoldDocSide side;

  /// [heldAt]: Beklemeye alınma zamanı
  final DateTime heldAt;

  /// [note]: Opsiyonel not
  final String note;

  /// {@macro delivery_hold_record}
  const DeliveryHoldRecord({
    required this.id,
    required this.docNo,
    required this.customerCode,
    required this.customerName,
    required this.side,
    required this.heldAt,
    this.note = '',
  });

  /// {@template delivery_hold_record_from_json}
  /// JSON map'ten kayıt üretir; hatalıysa null.
  /// {@endtemplate}
  static DeliveryHoldRecord? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = (json['id'] as String?)?.trim() ?? '';
    final heldRaw = json['held_at'] as String?;
    final heldAt = heldRaw == null ? null : DateTime.tryParse(heldRaw);
    if (id.isEmpty || heldAt == null) return null;
    final sideRaw = (json['side'] as String?) ?? 'sales';
    return DeliveryHoldRecord(
      id: id,
      docNo: (json['doc_no'] as String?) ?? '',
      customerCode: (json['customer_code'] as String?) ?? '',
      customerName: (json['customer_name'] as String?) ?? '',
      side: sideRaw == 'purchase'
          ? DeliveryHoldDocSide.purchase
          : DeliveryHoldDocSide.sales,
      heldAt: heldAt,
      note: (json['note'] as String?) ?? '',
    );
  }

  /// {@template delivery_hold_record_to_json}
  /// SharedPreferences JSON serileştirme.
  /// {@endtemplate}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doc_no': docNo,
      'customer_code': customerCode,
      'customer_name': customerName,
      'side': side == DeliveryHoldDocSide.purchase ? 'purchase' : 'sales',
      'held_at': heldAt.toIso8601String(),
      'note': note,
    };
  }
}
