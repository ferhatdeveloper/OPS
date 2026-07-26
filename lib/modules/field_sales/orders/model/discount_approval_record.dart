// Dosya Adı: discount_approval_record.dart
// Açıklama: İskonto onay dens satır modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template discount_approval_doc_side}
/// İskonto onay belge yönü (1-SATIŞ / 2-ALIŞ).
/// {@endtemplate}
enum DiscountApprovalDocSide {
  /// Satış
  sales,

  /// Alış
  purchase,
}

/// {@template discount_approval_record}
/// Yerelde bekleyen iskonto onay talebi özeti.
///
/// Kullanım örneği:
/// ```dart
/// final r = DiscountApprovalRecord(
///   id: 'da-1',
///   docNo: 'SIP-001',
///   customerCode: 'C001',
///   customerName: 'Demo Cari',
///   discountPercent: 15,
///   side: DiscountApprovalDocSide.sales,
///   requestedAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class DiscountApprovalRecord {
  /// [id]: Yerel kayıt kimliği
  final String id;

  /// [docNo]: Sipariş / belge no
  final String docNo;

  /// [customerCode]: Cari kodu
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [discountPercent]: Talep edilen iskonto %
  final double discountPercent;

  /// [amount]: Belge tutarı (opsiyonel)
  final double amount;

  /// [side]: Satış / alış
  final DiscountApprovalDocSide side;

  /// [requestedAt]: Talep zamanı
  final DateTime requestedAt;

  /// [note]: Opsiyonel not
  final String note;

  /// {@macro discount_approval_record}
  const DiscountApprovalRecord({
    required this.id,
    required this.docNo,
    required this.customerCode,
    required this.customerName,
    required this.discountPercent,
    required this.side,
    required this.requestedAt,
    this.amount = 0,
    this.note = '',
  });

  /// {@template discount_approval_record_from_json}
  /// JSON map'ten kayıt üretir; hatalıysa null.
  /// {@endtemplate}
  static DiscountApprovalRecord? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = (json['id'] as String?)?.trim() ?? '';
    final requestedRaw = json['requested_at'] as String?;
    final requestedAt =
        requestedRaw == null ? null : DateTime.tryParse(requestedRaw);
    if (id.isEmpty || requestedAt == null) return null;
    final sideRaw = (json['side'] as String?) ?? 'sales';
    final disc = (json['discount_percent'] as num?)?.toDouble() ?? 0;
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
    return DiscountApprovalRecord(
      id: id,
      docNo: (json['doc_no'] as String?) ?? '',
      customerCode: (json['customer_code'] as String?) ?? '',
      customerName: (json['customer_name'] as String?) ?? '',
      discountPercent: disc,
      amount: amount,
      side: sideRaw == 'purchase'
          ? DiscountApprovalDocSide.purchase
          : DiscountApprovalDocSide.sales,
      requestedAt: requestedAt,
      note: (json['note'] as String?) ?? '',
    );
  }

  /// {@template discount_approval_record_to_json}
  /// SharedPreferences JSON serileştirme.
  /// {@endtemplate}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doc_no': docNo,
      'customer_code': customerCode,
      'customer_name': customerName,
      'discount_percent': discountPercent,
      'amount': amount,
      'side': side == DiscountApprovalDocSide.purchase ? 'purchase' : 'sales',
      'requested_at': requestedAt.toIso8601String(),
      'note': note,
    };
  }
}
