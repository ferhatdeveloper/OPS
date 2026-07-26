// Dosya Adı: invoice_pending_record.dart
// Açıklama: Bekleyen fatura dens satırı (SQLite invoices)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/services/logo_payload_mapper.dart';

/// {@template InvoicePendingDocSide}
/// Dens kuyruk yönü: satış / alış.
/// {@endtemplate}
enum InvoicePendingDocSide {
  /// 1-SATIŞ
  sales,

  /// 2-ALIŞ
  purchase;

  /// SQLite / dens kodu
  String get code =>
      this == InvoicePendingDocSide.purchase ? 'purchase' : 'sales';

  /// Kod / invoice_type → enum
  static InvoicePendingDocSide fromInvoiceType(String? raw) {
    final q = LogoPayloadMapper.resolveInvoiceQueueType(raw);
    if (q == LogoPayloadMapper.invoiceQueuePurchase) {
      return InvoicePendingDocSide.purchase;
    }
    return InvoicePendingDocSide.sales;
  }
}

/// {@template invoice_pending_record}
/// Bekleyen fatura dens satırı — `approval_status=0` veya `status=Pending`.
///
/// Kullanım örneği:
/// ```dart
/// final row = InvoicePendingRecord(
///   id: 'inv-1',
///   customerId: 'C001',
///   invoiceDate: DateTime(2026, 7, 26),
///   totalAmount: 100,
/// );
/// ```
/// {@endtemplate}
class InvoicePendingRecord {
  /// [id]: Fatura birincil anahtar
  final String id;

  /// [customerId]: Cari id
  final String customerId;

  /// [customerCode]: Opsiyonel cari kodu (join / seed)
  final String? customerCode;

  /// [customerName]: Opsiyonel cari ünvan
  final String? customerName;

  /// [invoiceDate]: Fatura tarihi
  final DateTime invoiceDate;

  /// [totalAmount]: Genel toplam
  final double totalAmount;

  /// [status]: Yerel durum (`Pending` …)
  final String status;

  /// [invoiceType]: Yerel tip anahtarı
  final String? invoiceType;

  /// [approvalStatus]: ONAY (0 bekliyor)
  final int approvalStatus;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// [ettn]: Opsiyonel ETTN
  final String? ettn;

  /// [gibStatus]: Opsiyonel GİB kodu
  final String? gibStatus;

  /// [notes]: Not
  final String? notes;

  /// [docSide]: Satış / alış dens sekmesi
  final InvoicePendingDocSide docSide;

  /// {@macro invoice_pending_record}
  InvoicePendingRecord({
    required this.id,
    required this.customerId,
    required this.invoiceDate,
    required this.totalAmount,
    this.customerCode,
    this.customerName,
    this.status = 'Pending',
    this.invoiceType,
    this.approvalStatus = 0,
    this.isSynced = 0,
    this.ettn,
    this.gibStatus,
    this.notes,
    InvoicePendingDocSide? docSide,
  }) : docSide = docSide ??
            InvoicePendingDocSide.fromInvoiceType(invoiceType);

  /// {@template invoice_pending_record_is_pending}
  /// SQLite satırı bekleyen mi? (`approval_status=0` veya status Pending)
  ///
  /// Parametreler:
  /// - [map]: invoices satırı
  ///
  /// Dönüş değeri:
  /// - [bool]: Bekleyen ise true
  /// {@endtemplate}
  static bool isPendingMap(Map<String, dynamic> map) {
    final approval = (map['approval_status'] as num?)?.toInt() ?? 0;
    if (approval == 0) return true;
    final status = (map['status'] ?? '').toString().trim().toLowerCase();
    return status == 'pending';
  }

  /// {@template invoice_pending_record_from_map}
  /// SQLite `invoices` (+ opsiyonel cari alanları) → dens kayıt.
  /// {@endtemplate}
  factory InvoicePendingRecord.fromMap(Map<String, dynamic> map) {
    final dateRaw = map['invoice_date']?.toString();
    DateTime date;
    try {
      date = dateRaw != null && dateRaw.isNotEmpty
          ? DateTime.parse(dateRaw)
          : DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      date = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final invoiceType = map['invoice_type']?.toString();
    return InvoicePendingRecord(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerCode: map['customer_code']?.toString() ??
          map['code']?.toString(),
      customerName: map['customer_name']?.toString() ??
          map['name']?.toString(),
      invoiceDate: date,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Pending',
      invoiceType: invoiceType,
      approvalStatus: (map['approval_status'] as num?)?.toInt() ?? 0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      ettn: map['ettn']?.toString(),
      gibStatus: map['gib_status']?.toString(),
      notes: map['notes']?.toString(),
      docSide: InvoicePendingDocSide.fromInvoiceType(invoiceType),
    );
  }

  /// {@template invoice_pending_record_to_map}
  /// SQLite insert / test map.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'invoice_date': invoiceDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'invoice_type': invoiceType,
      'is_e_invoice': 1,
      'ettn': ettn,
      'gib_status': gibStatus,
      'approval_status': approvalStatus,
      'is_synced': isSynced,
    };
  }

  /// {@template invoice_pending_record_customer_label}
  /// Dens alt satır için cari etiketi.
  /// {@endtemplate}
  String get customerLabel {
    final parts = <String>[
      if ((customerCode ?? '').isNotEmpty) customerCode!,
      if ((customerName ?? '').isNotEmpty) customerName!,
      if ((customerCode ?? '').isEmpty &&
          (customerName ?? '').isEmpty &&
          customerId.isNotEmpty)
        customerId,
    ];
    return parts.join(' · ');
  }
}
