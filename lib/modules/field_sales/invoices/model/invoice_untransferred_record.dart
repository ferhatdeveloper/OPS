// Dosya Adı: invoice_untransferred_record.dart
// Açıklama: Transfer edilmeyen fatura dens kuyruk satır modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template InvoiceUntransferredDocSide}
/// Dens kuyruk yönü: satış / alış.
/// {@endtemplate}
enum InvoiceUntransferredDocSide {
  /// 1-SATIŞ
  sales,

  /// 2-ALIŞ
  purchase;

  /// SQLite / dens kodu
  String get code =>
      this == InvoiceUntransferredDocSide.purchase ? 'purchase' : 'sales';

  /// Kod → enum
  static InvoiceUntransferredDocSide fromCode(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'purchase' ||
        v == 'alis' ||
        v == 'alış' ||
        v.contains('purchase') ||
        v.contains('satin') ||
        v.contains('alis')) {
      return InvoiceUntransferredDocSide.purchase;
    }
    return InvoiceUntransferredDocSide.sales;
  }
}

/// {@template invoice_untransferred_record}
/// Transfer edilmeyen (is_synced=0) fatura dens satırı.
///
/// Kullanım örneği:
/// ```dart
/// final row = InvoiceUntransferredRecord(
///   id: 'inv-1',
///   documentNo: 'FT20260001',
/// );
/// ```
/// {@endtemplate}
class InvoiceUntransferredRecord {
  /// [id]: Yerel birincil anahtar / fatura id
  final String id;

  /// [documentNo]: Fiş / belge no (yoksa id)
  final String documentNo;

  /// [invoiceType]: Yerel fatura tipi anahtarı
  final String? invoiceType;

  /// [docSide]: Satış / alış dens sekmesi
  final InvoiceUntransferredDocSide docSide;

  /// [customerId]: Cari id
  final String? customerId;

  /// [customerCode]: Cari kodu
  final String? customerCode;

  /// [customerName]: Cari ünvan
  final String? customerName;

  /// [documentDate]: Belge tarihi
  final DateTime? documentDate;

  /// [amount]: Tutar
  final double amount;

  /// [status]: Yerel durum
  final String? status;

  /// [approvalStatus]: ONAY (1 = transfer için uygun)
  final int approvalStatus;

  /// [isSynced]: Senkron bayrağı (untransferred → 0)
  final int isSynced;

  /// [isDeleted]: Soft delete
  final int isDeleted;

  /// [queueJobId]: Opsiyonel sync_queue satır id
  final String? queueJobId;

  /// [retryCount]: Kuyruk yeniden deneme sayısı
  final int retryCount;

  /// [lastError]: Son sync_queue hatası (yoksa null)
  final String? lastError;

  /// [createdAt]: Oluşturma
  final DateTime? createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime? updatedAt;

  /// {@macro invoice_untransferred_record}
  const InvoiceUntransferredRecord({
    required this.id,
    required this.documentNo,
    this.invoiceType,
    this.docSide = InvoiceUntransferredDocSide.sales,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.documentDate,
    this.amount = 0,
    this.status,
    this.approvalStatus = 1,
    this.isSynced = 0,
    this.isDeleted = 0,
    this.queueJobId,
    this.retryCount = 0,
    this.lastError,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template invoice_untransferred_record_to_map}
  /// SQLite / seed map (snake_case).
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_no': documentNo,
      'invoice_type': invoiceType,
      'doc_side': docSide.code,
      'customer_id': customerId,
      'customer_code': customerCode,
      'customer_name': customerName,
      'invoice_date': documentDate?.toIso8601String(),
      'total_amount': amount,
      'status': status,
      'ONAY': approvalStatus,
      'approval_status': approvalStatus,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'queue_job_id': queueJobId,
      'retry_count': retryCount,
      'last_error': lastError,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// {@template invoice_untransferred_record_from_map}
  /// Map → model (invoices / dens seed).
  /// {@endtemplate}
  factory InvoiceUntransferredRecord.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['entity_id'] ?? '').toString();
    final docNo = (map['document_no'] ?? map['invoice_no'] ?? id).toString();
    final type = map['invoice_type']?.toString();
    final sideRaw = map['doc_side']?.toString() ?? type;
    final dateRaw = map['invoice_date'] ?? map['document_date'] ?? map['created_at'];
    DateTime? date;
    if (dateRaw != null) {
      date = DateTime.tryParse(dateRaw.toString());
    }
    return InvoiceUntransferredRecord(
      id: id,
      documentNo: docNo.isEmpty ? id : docNo,
      invoiceType: type,
      docSide: InvoiceUntransferredDocSide.fromCode(sideRaw),
      customerId: map['customer_id']?.toString(),
      customerCode:
          (map['customer_code'] ?? map['arp_code'])?.toString(),
      customerName: map['customer_name']?.toString(),
      documentDate: date,
      amount: (map['total_amount'] as num?)?.toDouble() ??
          (map['amount'] as num?)?.toDouble() ??
          0,
      status: map['status']?.toString(),
      approvalStatus: (map['ONAY'] as num?)?.toInt() ??
          (map['approval_status'] as num?)?.toInt() ??
          1,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      isDeleted: (map['is_deleted'] as num?)?.toInt() ?? 0,
      queueJobId: map['queue_job_id']?.toString(),
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      lastError: map['last_error']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// {@template invoice_untransferred_record_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  InvoiceUntransferredRecord copyWith({
    String? id,
    String? documentNo,
    String? invoiceType,
    InvoiceUntransferredDocSide? docSide,
    String? customerId,
    String? customerCode,
    String? customerName,
    DateTime? documentDate,
    double? amount,
    String? status,
    int? approvalStatus,
    int? isSynced,
    int? isDeleted,
    String? queueJobId,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceUntransferredRecord(
      id: id ?? this.id,
      documentNo: documentNo ?? this.documentNo,
      invoiceType: invoiceType ?? this.invoiceType,
      docSide: docSide ?? this.docSide,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      documentDate: documentDate ?? this.documentDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      queueJobId: queueJobId ?? this.queueJobId,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
